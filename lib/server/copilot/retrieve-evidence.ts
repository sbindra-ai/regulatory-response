import "server-only"

import type { EvidenceDocument, EvidenceHit, RetrievalMetadata, RequestInterpretation } from "@/lib/server/copilot/schemas"
import { getKnowledgeBase } from "@/lib/server/copilot/knowledge-base"
import { buildQueryTerms } from "@/lib/server/copilot/query-terms"
import { generateEmbeddings } from "@/lib/server/llm/openai"
import { vectorSearch } from "@/lib/server/copilot/vector-search"

type RetrieveEvidenceInput = {
  interpretation: RequestInterpretation
  limit?: number
  precomputedEmbeddings?: number[][] | null
  question: string
}

type RetrieveEvidenceResult = {
  evidence: EvidenceHit[]
  retrievalMetadata: RetrievalMetadata
}

function overlap(sourceValues: string[], targetValues: string[]): string[] {
  const targetLookup = new Set(targetValues.map((value) => value.toLowerCase()))

  return sourceValues.filter((value) => targetLookup.has(value.toLowerCase()))
}

function buildDocumentText(document: EvidenceDocument): string {
  return [
    document.title,
    document.summary,
    document.keywords.join(" "),
    document.datasetNames.join(" "),
    document.outputFamilies.join(" "),
    document.sourceText,
  ]
    .join(" ")
    .toLowerCase()
}

function buildRetrievalReason(document: EvidenceDocument, datasetOverlap: string[], familyOverlap: string[]): string {
  const reasons = []

  if (familyOverlap.length > 0) {
    reasons.push(`Matches output family ${familyOverlap.join(", ")}`)
  }

  if (datasetOverlap.length > 0) {
    reasons.push(`Grounded by datasets ${datasetOverlap.join(", ")}`)
  }

  if (document.sourceType === "program") {
    reasons.push("Provides reusable prior output logic")
  } else if (document.sourceType === "dataset") {
    reasons.push("Provides dataset metadata grounding")
  } else if (document.sourceType === "sap-section") {
    reasons.push("Provides SAP methodology context")
  } else if (document.sourceType === "tlf-spec") {
    reasons.push("Provides TLF specification details")
  } else if (document.sourceType === "adrg-section") {
    reasons.push("Provides analysis reviewer guidance")
  } else if (document.sourceType === "fda-request") {
    reasons.push("Provides FDA information request context")
  } else if (document.sourceType === "ads-spec") {
    reasons.push("Provides dataset specification details")
  } else if (document.sourceType === "case-data") {
    reasons.push("Provides subject-level case data")
  } else {
    reasons.push("Provides product-level workflow context")
  }

  return reasons.join(". ")
}

const RRF_K = 60

export async function retrieveEvidence({
  interpretation,
  limit = 8,
  precomputedEmbeddings,
  question,
}: RetrieveEvidenceInput): Promise<RetrieveEvidenceResult> {
  const { corpus, index } = getKnowledgeBase()
  const queryTerms = buildQueryTerms({ interpretation, question })
  const isWeakInterpretation = interpretation.requestType === "unknown" || interpretation.confidence === "low"

  // 1. Keyword search: rank by MiniSearch score
  const keywordScores = new Map<string, number>()

  for (const term of queryTerms) {
    for (const result of index.search(term, { prefix: true })) {
      keywordScores.set(result.id, (keywordScores.get(result.id) ?? 0) + result.score)
    }
  }

  const keywordRanked = [...keywordScores.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([id], rank) => ({ id, rank }))

  const keywordRankMap = new Map(keywordRanked.map(({ id, rank }) => [id, rank]))

  // 2. Vector search: embed query, compute cosine similarity
  let vectorRankMap = new Map<string, number>()
  let vectorSimilarityMap = new Map<string, number>()
  let isHybrid = false

  const hasEmbeddings = corpus.documents.some((doc) => doc.embedding !== null)

  if (hasEmbeddings) {
    try {
      const queryEmbeddings = precomputedEmbeddings ?? await generateEmbeddings(question)

      if (queryEmbeddings && queryEmbeddings.length > 0) {
        const vectorResults = vectorSearch(queryEmbeddings[0], corpus.documents)

        vectorRankMap = new Map(vectorResults.map(({ documentId }, rank) => [documentId, rank]))
        vectorSimilarityMap = new Map(vectorResults.map(({ documentId, similarity }) => [documentId, similarity]))
        isHybrid = true
      }
    } catch (error) {
      console.warn("Vector search failed, falling back to keyword-only:", error instanceof Error ? error.message : error)
    }
  }

  // 3. RRF fusion + heuristic boosts
  const scoredDocuments = corpus.documents.map((document) => {
    const datasetOverlap = overlap(document.datasetNames, interpretation.datasetHints)
    const familyOverlap = overlap(document.outputFamilies, interpretation.outputFamilyHints)
    const documentText = buildDocumentText(document)
    const matchedTerms = queryTerms.filter((term) => documentText.includes(term.toLowerCase())).slice(0, 8)
    const timepointMatches = interpretation.timepoints.filter(
      (timepoint) => timepoint !== "Not explicitly stated" && documentText.includes(timepoint.toLowerCase()),
    )

    const kRank = keywordRankMap.get(document.id)
    const vRank = vectorRankMap.get(document.id)
    const keywordRrfScore = kRank !== undefined ? 1 / (RRF_K + kRank) : 0
    const vectorRrfScore = vRank !== undefined ? 1 / (RRF_K + vRank) : 0
    let score = keywordRrfScore + vectorRrfScore

    // Heuristic boosts
    score += datasetOverlap.length * 8 / 100
    score += familyOverlap.length * 18 / 100
    score += timepointMatches.length * 5 / 100

    if (document.sourceType === "program") {
      score += familyOverlap.length > 0 ? 12 / 100 : 0
    }

    if (document.sourceType === "dataset") {
      score += datasetOverlap.length > 0 ? 10 / 100 : 0
    }

    // PDF source type boosts
    if (document.sourceType === "sap-section") {
      score += 4 / 100
    }

    if (document.sourceType === "tlf-spec") {
      score += 3 / 100
    }

    if (document.sourceType === "fda-request") {
      score += 5 / 100
    }

    if (document.sourceType === "adrg-section") {
      score += 2 / 100
    }

    if (document.sourceType === "ads-spec") {
      score += datasetOverlap.length > 0 ? 6 / 100 : 2 / 100
    }

    if (document.sourceType === "brief") {
      score += interpretation.requestType === "unknown" ? 8 / 100 : 1 / 100
    }

    return {
      document,
      keywordScore: keywordScores.get(document.id) ?? 0,
      matchedTerms,
      retrievalReason: buildRetrievalReason(document, datasetOverlap, familyOverlap),
      score,
      vectorSimilarity: vectorSimilarityMap.get(document.id) ?? null,
    }
  })

  // 4. Filter and sort
  const filtered = scoredDocuments
    .filter((hit) => {
      if (isWeakInterpretation) {
        return hit.score > 0
      }

      return hit.score > 0
    })
    .sort((left, right) => right.score - left.score)

  // 5. Normalize scores to 0-100 and assign hybrid ranks
  const maxScore = filtered[0]?.score ?? 1
  const evidence: EvidenceHit[] = filtered.slice(0, limit).map((hit, index) => ({
    document: hit.document,
    score: Math.round((hit.score / maxScore) * 100),
    matchedTerms: hit.matchedTerms,
    retrievalReason: hit.retrievalReason,
    vectorSimilarity: hit.vectorSimilarity,
    keywordScore: hit.keywordScore,
    hybridRank: index + 1,
  }))

  const topSimilarity = evidence.reduce(
    (max, hit) => Math.max(max, hit.vectorSimilarity ?? 0),
    0,
  )

  return {
    evidence,
    retrievalMetadata: {
      method: isHybrid ? "hybrid" : "keyword-only",
      documentCount: evidence.length,
      topSimilarity: isHybrid ? topSimilarity : null,
    },
  }
}
