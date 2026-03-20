import "server-only"

import MiniSearch from "minisearch"

import corpusData from "@/data/copilot/evidence-corpus.json"
import {
  evidenceCorpusSchema,
  type EvidenceCorpus,
  type EvidenceDocument,
} from "@/lib/server/copilot/schemas"

let cachedCorpus: EvidenceCorpus | null = null
let cachedIndex: MiniSearch<EvidenceDocument> | null = null

function loadCorpus(): EvidenceCorpus {
  if (!cachedCorpus) {
    cachedCorpus = evidenceCorpusSchema.parse(corpusData)
  }

  return cachedCorpus
}

function buildIndex(): MiniSearch<EvidenceDocument> {
  if (!cachedIndex) {
    cachedIndex = new MiniSearch<EvidenceDocument>({
      fields: ["title", "summary", "keywords", "datasetNames", "outputFamilies", "sourceText"],
      idField: "id",
      searchOptions: {
        boost: {
          keywords: 2,
          title: 3,
        },
        prefix: true,
      },
      storeFields: ["id"],
    })
    cachedIndex.addAll(loadCorpus().documents)
  }

  return cachedIndex
}

export function getKnowledgeBase() {
  return {
    corpus: loadCorpus(),
    index: buildIndex(),
  }
}

export function getDocumentEmbeddings(): Map<string, number[]> {
  const corpus = loadCorpus()
  const embeddings = new Map<string, number[]>()

  for (const doc of corpus.documents) {
    if (doc.embedding) {
      embeddings.set(doc.id, doc.embedding)
    }
  }

  return embeddings
}
