import "server-only"

import type {
  EvidenceDocument,
  EvidenceHit,
  EvidencePool,
  RetrievalMetadata,
  RequestInterpretation,
} from "@/lib/server/copilot/schemas"
import { normalizeEvidenceHitsForNetworkShare } from "@/lib/server/copilot/network-path-resolve"
import { getKnowledgeBase } from "@/lib/server/copilot/knowledge-base"
import { DEFAULT_NETWORK_SCAN_ROOT } from "@/lib/server/knowledge/run-network-ingest"
import { normalizeNetworkScanRoot } from "@/lib/server/knowledge/normalize-network-scan-root"
import { buildQueryTerms } from "@/lib/server/copilot/query-terms"
import { generateEmbeddings } from "@/lib/server/llm/openai"
import { vectorSearch } from "@/lib/server/copilot/vector-search"

export type RetrievalStrategy = "hybrid" | "vector-primary"

type RetrieveEvidenceInput = {
  evidencePool?: EvidencePool
  interpretation: RequestInterpretation
  limit?: number
  precomputedEmbeddings?: number[][] | null
  question: string
  retrievalStrategy?: RetrievalStrategy
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
  } else if (document.sourceType === "network-file") {
    reasons.push("Matched content from the mapped network share")
  } else {
    reasons.push("Provides product-level workflow context")
  }

  return reasons.join(". ")
}

const RRF_K = 60

/** Initial cap before SAS backfill; keep generous so mixed corpora still surface code. */
const DEFAULT_REPO_LIMIT = 32
const DEFAULT_NETWORK_LIMIT = 48

/** After the top-N slice, add more SAS programs from the ranked tail so the response-plan table is not stuck on one file. */
const TARGET_SAS_DOCUMENTS = 28
const MAX_EVIDENCE_AFTER_EXPANSION = 96

function isSasEvidenceDocument(document: EvidenceDocument): boolean {
  if (document.sourceType === "program") return true
  const p = document.path.replace(/\\/g, "/")
  if (document.sourceType === "network-file" && /\.sas$/i.test(p)) return true
  return false
}

function countSasHits<T extends { document: EvidenceDocument }>(hits: T[]): number {
  return hits.filter((h) => isSasEvidenceDocument(h.document)).length
}

function networkQuestionTokenOverlap(question: string, document: EvidenceDocument): number {
  const tokens = question
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((t) => t.length >= 3)
  if (tokens.length === 0) return 0
  const haystack = buildDocumentText(document)
  let hits = 0
  for (const t of tokens) {
    if (haystack.includes(t)) hits++
  }
  return hits / tokens.length
}

export async function retrieveEvidence({
  evidencePool = "repository",
  interpretation,
  limit,
  precomputedEmbeddings,
  question,
  retrievalStrategy = "hybrid",
}: RetrieveEvidenceInput): Promise<RetrieveEvidenceResult> {
  const limitExplicitlySet = typeof limit === "number"
  const effectiveLimit =
    limit ?? (evidencePool === "network" ? DEFAULT_NETWORK_LIMIT : DEFAULT_REPO_LIMIT)

  const { corpus, index } = getKnowledgeBase(evidencePool)
  const queryTerms = buildQueryTerms({ interpretation, question })
  const isWeakInterpretation = interpretation.requestType === "unknown" || interpretation.confidence === "low"
  const networkFileCount = corpus.documents.filter((d) => d.sourceType === "network-file").length
  const suppressNetworkBrief = evidencePool === "network" && networkFileCount > 0

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
  let hasVectorRankings = false

  const hasEmbeddings = corpus.documents.some((doc) => doc.embedding !== null)

  if (hasEmbeddings) {
    try {
      const queryEmbeddings = precomputedEmbeddings ?? await generateEmbeddings(question)

      if (queryEmbeddings && queryEmbeddings.length > 0) {
        const vectorResults = vectorSearch(queryEmbeddings[0], corpus.documents)

        vectorRankMap = new Map(vectorResults.map(({ documentId }, rank) => [documentId, rank]))
        vectorSimilarityMap = new Map(vectorResults.map(({ documentId, similarity }) => [documentId, similarity]))
        hasVectorRankings = true
      }
    } catch (error) {
      console.warn("Vector search failed, falling back to keyword-only:", error instanceof Error ? error.message : error)
    }
  }

  const useVectorPrimary = retrievalStrategy === "vector-primary" && hasVectorRankings

  // 3. RRF fusion + heuristic boosts (or vector-primary ranking)
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
    const similarity = vectorSimilarityMap.get(document.id) ?? null

    let score: number

    if (useVectorPrimary) {
      const sim = similarity ?? 0
      score = sim + keywordRrfScore * 0.08
    } else {
      score = keywordRrfScore + vectorRrfScore
    }

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

    if (document.sourceType === "network-file" && evidencePool === "network") {
      score += 2 / 100
      score += networkQuestionTokenOverlap(question, document) * 0.35
    }

    return {
      document,
      keywordScore: keywordScores.get(document.id) ?? 0,
      matchedTerms,
      retrievalReason: buildRetrievalReason(document, datasetOverlap, familyOverlap),
      score,
      vectorSimilarity: similarity,
    }
  })

  // 4. Filter and sort
  let filtered = scoredDocuments
    .filter((hit) => {
      if (suppressNetworkBrief && hit.document.id === "brief:product") {
        return false
      }
      if (isWeakInterpretation) {
        return hit.score > 0
      }

      return hit.score > 0
    })
    .sort((left, right) => right.score - left.score)

  // Network share: fill up to effectiveLimit with share files (overlap-ranked; min score so files still appear)
  if (evidencePool === "network" && networkFileCount > 0 && filtered.length < effectiveLimit) {
    const salvage = corpus.documents
      .filter((d) => d.sourceType === "network-file")
      .map((document) => {
        const qOverlap = networkQuestionTokenOverlap(question, document)
        const datasetOverlap = overlap(document.datasetNames, interpretation.datasetHints)
        const familyOverlap = overlap(document.outputFamilies, interpretation.outputFamilyHints)
        const boost = Math.max(
          qOverlap * 0.45 + datasetOverlap.length * 0.14 + familyOverlap.length * 0.09,
          0.028,
        )
        return { document, boost }
      })
      .sort((a, b) => b.boost - a.boost)

    const existingIds = new Set(filtered.map((h) => h.document.id))
    for (const { document, boost } of salvage) {
      if (existingIds.has(document.id)) continue
      if (filtered.length >= effectiveLimit) break
      const datasetOverlap = overlap(document.datasetNames, interpretation.datasetHints)
      const familyOverlap = overlap(document.outputFamilies, interpretation.outputFamilyHints)
      const documentText = buildDocumentText(document)
      const matchedTerms = queryTerms.filter((term) => documentText.includes(term.toLowerCase())).slice(0, 8)
      filtered.push({
        document,
        keywordScore: keywordScores.get(document.id) ?? 0,
        matchedTerms,
        retrievalReason: buildRetrievalReason(document, datasetOverlap, familyOverlap),
        score: boost,
        vectorSimilarity: vectorSimilarityMap.get(document.id) ?? null,
      })
      existingIds.add(document.id)
    }
    filtered = filtered.sort((left, right) => right.score - left.score)
  }

  // 5. Top-N slice, then backfill SAS from the same ranked list so programs/macros are not drowned by specs/datasets
  let selected = filtered.slice(0, effectiveLimit)
  const selectedIds = new Set(selected.map((h) => h.document.id))

  if (!limitExplicitlySet && countSasHits(selected) < TARGET_SAS_DOCUMENTS) {
    for (const hit of filtered) {
      if (selected.length >= MAX_EVIDENCE_AFTER_EXPANSION) break
      if (selectedIds.has(hit.document.id)) continue
      if (!isSasEvidenceDocument(hit.document)) continue
      selected.push(hit)
      selectedIds.add(hit.document.id)
      if (countSasHits(selected) >= TARGET_SAS_DOCUMENTS) break
    }
    selected = selected.sort((left, right) => right.score - left.score)
  }

  // Normalize scores to 0-100 and assign hybrid ranks
  const maxScore = selected[0]?.score ?? 1
  let evidence: EvidenceHit[] = selected.map((hit, index) => ({
    document: hit.document,
    score: Math.round((hit.score / maxScore) * 100),
    matchedTerms: hit.matchedTerms,
    retrievalReason: hit.retrievalReason,
    vectorSimilarity: hit.vectorSimilarity,
    keywordScore: hit.keywordScore,
    hybridRank: index + 1,
  }))

  const networkScanRootUsed =
    evidencePool === "network"
      ? normalizeNetworkScanRoot(process.env.EVIDENCE_SCAN_ROOT?.trim() || DEFAULT_NETWORK_SCAN_ROOT) || undefined
      : undefined

  if (evidencePool === "network" && networkScanRootUsed) {
    evidence = normalizeEvidenceHitsForNetworkShare(evidence, networkScanRootUsed)
  }

  const topSimilarity = evidence.reduce(
    (max, hit) => Math.max(max, hit.vectorSimilarity ?? 0),
    0,
  )

  let method: RetrievalMetadata["method"]
  if (useVectorPrimary) {
    method = "vector-primary"
  } else if (hasVectorRankings) {
    method = "hybrid"
  } else {
    method = "keyword-only"
  }

  return {
    evidence,
    retrievalMetadata: {
      method,
      documentCount: evidence.length,
      topSimilarity: hasVectorRankings ? topSimilarity : null,
      evidencePool,
      ...(networkScanRootUsed ? { networkScanRootUsed } : {}),
    },
  }
}
