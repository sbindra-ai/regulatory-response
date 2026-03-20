"use server"

import { getKnowledgeBase } from "@/lib/server/copilot/knowledge-base"

export type CorpusStats = {
  totalDocuments: number
  generatedAt: string
  embeddingModel: string
  datasetsCount: number
  programsCount: number
  documentsByType: Record<string, number>
  uniqueDatasetNames: string[]
  documentsWithEmbeddings: number
}

export async function getCorpusStats(): Promise<CorpusStats> {
  const { corpus } = getKnowledgeBase()

  const documentsByType: Record<string, number> = {}
  const datasetNames = new Set<string>()
  let documentsWithEmbeddings = 0

  for (const doc of corpus.documents) {
    documentsByType[doc.sourceType] = (documentsByType[doc.sourceType] || 0) + 1
    if (doc.embedding && doc.embedding.length > 0) documentsWithEmbeddings++
    for (const name of doc.datasetNames) datasetNames.add(name)
  }

  return {
    totalDocuments: corpus.documents.length,
    generatedAt: corpus.generatedAt,
    embeddingModel: corpus.embeddingModel ?? "unknown",
    datasetsCount: corpus.datasets.length,
    programsCount: corpus.programs.length,
    documentsByType,
    uniqueDatasetNames: Array.from(datasetNames).sort(),
    documentsWithEmbeddings,
  }
}
