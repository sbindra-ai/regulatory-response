import type {
  Confidence,
  ConfidenceScore,
  EvidenceHit,
  RequestInterpretation,
} from "@/lib/server/copilot/schemas"

type ComputeConfidenceInput = {
  evidence: EvidenceHit[]
  interpretation: RequestInterpretation
  retrievalMethod: "hybrid" | "keyword-only" | "vector-primary"
}

function computeInterpretationScore(interpretation: RequestInterpretation): {
  score: number
  reasons: string[]
} {
  let score = 100
  const reasons: string[] = []

  if (interpretation.requestType === "unknown") {
    score -= 30
    reasons.push("Request type could not be mapped to a supported evidence family (-30)")
  } else {
    reasons.push(`Matched request type '${interpretation.requestType}' with high specificity`)
  }

  if (interpretation.population === "Not explicitly stated") {
    score -= 15
    reasons.push("Population not specified in question (-15)")
  }

  if (
    interpretation.timepoints.length === 0 ||
    (interpretation.timepoints.length === 1 && interpretation.timepoints[0] === "Not explicitly stated")
  ) {
    score -= 10
    reasons.push("Timepoints not specified in question (-10)")
  }

  if (interpretation.datasetHints.length === 0) {
    score -= 10
    reasons.push("No dataset hints could be inferred (-10)")
  }

  return { score: Math.max(0, score), reasons }
}

function computeEvidenceRelevanceScore(
  evidence: EvidenceHit[],
  retrievalMethod: "hybrid" | "keyword-only" | "vector-primary",
): {
  score: number
  reasons: string[]
} {
  if (evidence.length === 0) {
    return { score: 0, reasons: ["No evidence documents retrieved"] }
  }

  const reasons: string[] = []

  if (retrievalMethod === "hybrid" || retrievalMethod === "vector-primary") {
    const topSimilarity = evidence.reduce(
      (max, hit) => Math.max(max, hit.vectorSimilarity ?? 0),
      0,
    )

    if (topSimilarity > 0) {
      const score = Math.round(topSimilarity * 100)
      reasons.push(`Top evidence has ${topSimilarity.toFixed(2)} cosine similarity to query`)
      if (retrievalMethod === "vector-primary") {
        reasons.push("Vector-first ranking emphasized semantic similarity")
      }
      return { score, reasons }
    }
  }

  const topRetrievalScore = evidence.reduce((max, hit) => Math.max(max, hit.score), 0)
  if (topRetrievalScore > 0) {
    const score = Math.min(78, Math.round(topRetrievalScore * 0.82))
    reasons.push(
      "Vector similarity unavailable or weak in top hits — relevance inferred from retrieval ranking scores",
    )
    return { score, reasons }
  }

  // Keyword-only fallback: normalize keyword score, cap at 80
  const topKeywordScore = evidence.reduce((max, hit) => Math.max(max, hit.keywordScore), 0)
  const normalizedScore = Math.min(80, Math.round((topKeywordScore / Math.max(topKeywordScore, 50)) * 80))
  reasons.push("Vector search unavailable - relevance based on keyword matching (capped at 80)")
  return { score: normalizedScore, reasons }
}

function computeEvidenceCoverageScore(
  interpretation: RequestInterpretation,
  evidence: EvidenceHit[],
): {
  score: number
  reasons: string[]
} {
  const expectedDatasets = interpretation.datasetHints
  const expectedFamilies = interpretation.outputFamilyHints
  const totalExpected = expectedDatasets.length + expectedFamilies.length

  if (totalExpected === 0) {
    return { score: 0, reasons: ["No expected datasets or output families to match against"] }
  }

  const matchedDatasets = new Set<string>()
  const matchedFamilies = new Set<string>()

  for (const hit of evidence) {
    for (const ds of hit.document.datasetNames) {
      if (expectedDatasets.some((expected) => expected.toLowerCase() === ds.toLowerCase())) {
        matchedDatasets.add(ds.toLowerCase())
      }
    }
    for (const fam of hit.document.outputFamilies) {
      if (expectedFamilies.some((expected) => expected.toLowerCase() === fam.toLowerCase())) {
        matchedFamilies.add(fam.toLowerCase())
      }
    }
  }

  const totalMatched = matchedDatasets.size + matchedFamilies.size
  const score = Math.round((totalMatched / totalExpected) * 100)
  const reasons: string[] = []

  if (matchedDatasets.size > 0) {
    reasons.push(`Found ${matchedDatasets.size} of ${expectedDatasets.length} expected datasets in evidence`)
  }

  if (matchedFamilies.size > 0) {
    reasons.push(`Found ${matchedFamilies.size} of ${expectedFamilies.length} expected output families in evidence`)
  }

  if (totalMatched === 0) {
    reasons.push("No expected datasets or output families found in retrieved evidence")
  }

  return { score, reasons }
}

function overallToLevel(overall: number): Confidence {
  if (overall >= 70) return "high"
  if (overall >= 40) return "medium"
  return "low"
}

export function computeConfidenceScore({
  evidence,
  interpretation,
  retrievalMethod,
}: ComputeConfidenceInput): ConfidenceScore {
  const interp = computeInterpretationScore(interpretation)
  const relevance = computeEvidenceRelevanceScore(evidence, retrievalMethod)
  const coverage = computeEvidenceCoverageScore(interpretation, evidence)

  const overall = Math.round(
    0.3 * interp.score + 0.4 * relevance.score + 0.3 * coverage.score,
  )

  return {
    overall,
    level: overallToLevel(overall),
    interpretationScore: interp.score,
    evidenceRelevanceScore: relevance.score,
    evidenceCoverageScore: coverage.score,
    reasons: [...interp.reasons, ...relevance.reasons, ...coverage.reasons],
  }
}
