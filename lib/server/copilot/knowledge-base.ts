import "server-only"

import { existsSync, readFileSync, statSync } from "node:fs"
import { join } from "node:path"

import MiniSearch from "minisearch"

import corpusData from "@/data/copilot/evidence-corpus.json"
import { buildPlaceholderNetworkCorpus } from "@/lib/server/knowledge/build-network-corpus"
import {
  evidenceCorpusSchema,
  type EvidenceCorpus,
  type EvidenceDocument,
  type EvidencePool,
} from "@/lib/server/copilot/schemas"

const NETWORK_CORPUS_FILENAME = "evidence-corpus.network.json"

let repositoryCorpus: EvidenceCorpus | null = null
let repositoryIndex: MiniSearch<EvidenceDocument> | null = null

let networkCorpus: EvidenceCorpus | null = null
let networkIndex: MiniSearch<EvidenceDocument> | null = null
/** File mtime in ms, or -1 when using in-memory placeholder (missing JSON). */
let networkCorpusMtime = 0

function loadRepositoryCorpus(): EvidenceCorpus {
  if (!repositoryCorpus) {
    repositoryCorpus = evidenceCorpusSchema.parse(corpusData)
  }
  return repositoryCorpus
}

function buildMiniSearchIndex(corpus: EvidenceCorpus): MiniSearch<EvidenceDocument> {
  const index = new MiniSearch<EvidenceDocument>({
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
  index.addAll(corpus.documents)
  return index
}

function getRepositoryIndex(): MiniSearch<EvidenceDocument> {
  if (!repositoryIndex) {
    repositoryIndex = buildMiniSearchIndex(loadRepositoryCorpus())
  }
  return repositoryIndex
}

function networkCorpusPath(): string {
  const override = process.env.EVIDENCE_NETWORK_CORPUS_PATH?.trim()
  if (override) return override
  return join(process.cwd(), "data", "copilot", NETWORK_CORPUS_FILENAME)
}

function loadNetworkCorpusFromDisk(): EvidenceCorpus {
  const path = networkCorpusPath()

  if (!existsSync(path)) {
    if (networkCorpus && networkCorpusMtime === -1) {
      return networkCorpus
    }
    console.warn(
      `[knowledge-base] Network corpus file missing: ${path}\n` +
        "Using a placeholder (brief only) so the app keeps running. Map your share, set EVIDENCE_SCAN_ROOT, run npm run ingest:network, or set EVIDENCE_NETWORK_CORPUS_PATH to a real JSON file.",
    )
    networkCorpus = evidenceCorpusSchema.parse(buildPlaceholderNetworkCorpus())
    networkCorpusMtime = -1
    networkIndex = null
    return networkCorpus
  }

  const mtime = statSync(path).mtimeMs

  if (networkCorpus && mtime === networkCorpusMtime) {
    return networkCorpus
  }

  const raw = JSON.parse(readFileSync(path, "utf8"))
  networkCorpus = evidenceCorpusSchema.parse(raw)
  networkCorpusMtime = mtime
  networkIndex = null
  return networkCorpus
}

function getNetworkIndex(corpus: EvidenceCorpus): MiniSearch<EvidenceDocument> {
  if (!networkIndex) {
    networkIndex = buildMiniSearchIndex(corpus)
  }
  return networkIndex
}

export function getKnowledgeBase(evidencePool: EvidencePool = "repository") {
  if (evidencePool === "network") {
    const corpus = loadNetworkCorpusFromDisk()
    return {
      corpus,
      index: getNetworkIndex(corpus),
    }
  }

  return {
    corpus: loadRepositoryCorpus(),
    index: getRepositoryIndex(),
  }
}

/** Drop cached corpora (e.g. after rebuilding JSON on disk). */
export function clearKnowledgeBaseCache(): void {
  repositoryCorpus = null
  repositoryIndex = null
  networkCorpus = null
  networkIndex = null
  networkCorpusMtime = 0
}

export function getDocumentEmbeddings(): Map<string, number[]> {
  const corpus = loadRepositoryCorpus()
  const embeddings = new Map<string, number[]>()

  for (const doc of corpus.documents) {
    if (doc.embedding) {
      embeddings.set(doc.id, doc.embedding)
    }
  }

  return embeddings
}
