import type { EvidenceDocument } from "@/lib/server/copilot/schemas"

export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length || a.length === 0) {
    return 0
  }

  let dot = 0
  let magA = 0
  let magB = 0

  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i]
    magA += a[i] * a[i]
    magB += b[i] * b[i]
  }

  const magnitude = Math.sqrt(magA) * Math.sqrt(magB)

  if (magnitude === 0) {
    return 0
  }

  return dot / magnitude
}

export function vectorSearch(
  queryEmbedding: number[],
  documents: EvidenceDocument[],
): Array<{ documentId: string; similarity: number }> {
  return documents
    .filter((doc) => doc.embedding !== null)
    .map((doc) => ({
      documentId: doc.id,
      similarity: cosineSimilarity(queryEmbedding, doc.embedding!),
    }))
    .sort((a, b) => b.similarity - a.similarity)
}
