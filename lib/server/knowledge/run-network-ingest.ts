import "server-only"

import { mkdir, writeFile } from "node:fs/promises"
import { dirname, resolve } from "node:path"

import type { EvidenceCorpus } from "@/lib/server/copilot/schemas"
import {
  buildNetworkEvidenceCorpus,
  embeddingInputForDocument,
} from "@/lib/server/knowledge/build-network-corpus"
import {
  normalizeNetworkScanRoot,
  resolveReadableScanRoot,
} from "@/lib/server/knowledge/normalize-network-scan-root"

/** Used when `EVIDENCE_SCAN_ROOT` is unset (override via env or UI if your share differs). */
export const DEFAULT_NETWORK_SCAN_ROOT = "\\\\by-swanPRD\\swan\\root\\bhc\\3427080"

const MGA_BASE_URL = "https://chat.int.bayer.com/api/v2"
const DEFAULT_EMBEDDING_MODEL = "text-embedding-3-small"

export type NetworkIngestResult = {
  success: boolean
  fileDocCount: number
  embeddedCount: number
  outputPath: string
  scanRootUsed: string
  error?: string
  warnings: string[]
}

async function fetchEmbeddings(texts: string[], apiKey: string, model: string): Promise<number[][]> {
  const { default: OpenAI } = await import("openai")
  const client = new OpenAI({ apiKey, baseURL: MGA_BASE_URL })
  const response = (await client.embeddings.create({
    input: texts,
    model,
  })) as { data: Array<{ embedding: number[] }> }

  return response.data.map((item) => item.embedding)
}

function applyEmbeddings(
  corpus: EvidenceCorpus,
  embeddings: Map<string, number[]>,
  embeddingModel: string,
  embeddingDimensions: number | null,
): EvidenceCorpus {
  const documents = corpus.documents.map((doc) => ({
    ...doc,
    embedding: embeddings.get(doc.id) ?? null,
  }))

  return {
    ...corpus,
    embeddingModel,
    embeddingDimensions,
    documents,
  }
}

/**
 * Scan a filesystem root and write `evidence-corpus.network.json`.
 * Does not write when the scan finds zero files (preserves an existing corpus).
 */
export async function runNetworkIngest(options: {
  scanRootOverride?: string | null
  outputPathOverride?: string | null
}): Promise<NetworkIngestResult> {
  const warnings: string[] = []
  const workspaceRoot = process.cwd()
  const outputPath = resolve(
    workspaceRoot,
    options.outputPathOverride?.trim() ||
      process.env.EVIDENCE_NETWORK_OUTPUT?.trim() ||
      "data/copilot/evidence-corpus.network.json",
  )

  const fromEnv = process.env.EVIDENCE_SCAN_ROOT?.trim()
  const rawRoot = options.scanRootOverride?.trim() || fromEnv || DEFAULT_NETWORK_SCAN_ROOT
  const scanRoot = normalizeNetworkScanRoot(rawRoot)

  if (!scanRoot) {
    return {
      success: false,
      fileDocCount: 0,
      embeddedCount: 0,
      outputPath,
      scanRootUsed: "",
      error:
        "No scan root configured. Set EVIDENCE_SCAN_ROOT in .env, enter a mapped folder below, or pass the path as the first argument to npm run ingest:network.",
      warnings,
    }
  }

  const resolved = await resolveReadableScanRoot(scanRoot)
  if (!resolved.ok) {
    return {
      success: false,
      fileDocCount: 0,
      embeddedCount: 0,
      outputPath,
      scanRootUsed: scanRoot,
      error: resolved.error,
      warnings,
    }
  }

  const readableRoot = resolved.path

  let preliminary: EvidenceCorpus
  try {
    preliminary = await buildNetworkEvidenceCorpus(readableRoot)
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    return {
      success: false,
      fileDocCount: 0,
      embeddedCount: 0,
      outputPath,
      scanRootUsed: readableRoot,
      error: `Scan failed under "${readableRoot}": ${msg}`,
      warnings,
    }
  }

  const fileDocCount = preliminary.documents.length - 1

  if (fileDocCount === 0) {
    return {
      success: false,
      fileDocCount: 0,
      embeddedCount: 0,
      outputPath,
      scanRootUsed: readableRoot,
      error:
        "No indexable files found under that path. Expected .sas, .txt, .pdf, .sas7bdat, or .xpt (subfolders allowed). The folder opened successfully but contains no matching files in this tree (or they are all larger than the size limit).",
      warnings,
    }
  }

  let corpus: EvidenceCorpus = preliminary
  const mgaToken = process.env.MGA_TOKEN?.trim()
  const embeddingModel = process.env.MGA_EMBEDDING_MODEL?.trim() || DEFAULT_EMBEDDING_MODEL
  let embeddedCount = 0

  if (mgaToken) {
    try {
      const docTexts = preliminary.documents.map((doc) => embeddingInputForDocument(doc))
      const docIds = preliminary.documents.map((doc) => doc.id)
      const BATCH_SIZE = 20
      const allEmbeddings: number[][] = []

      for (let i = 0; i < docTexts.length; i += BATCH_SIZE) {
        const batch = docTexts.slice(i, i + BATCH_SIZE)
        const batchEmbeddings = await fetchEmbeddings(batch, mgaToken, embeddingModel)
        allEmbeddings.push(...batchEmbeddings)
      }

      const embeddings = new Map<string, number[]>()
      for (let i = 0; i < docIds.length; i++) {
        embeddings.set(docIds[i], allEmbeddings[i])
      }

      const embeddingDimensions = allEmbeddings[0]?.length ?? null
      corpus = applyEmbeddings(preliminary, embeddings, embeddingModel, embeddingDimensions)
      embeddedCount = corpus.documents.filter((d) => d.embedding !== null).length
    } catch (e) {
      warnings.push(
        `Embedding generation failed; corpus saved keyword-only: ${e instanceof Error ? e.message : String(e)}`,
      )
      corpus = preliminary
      embeddedCount = 0
    }
  } else {
    warnings.push("MGA_TOKEN not set — corpus is keyword-only until you embed.")
  }

  await mkdir(dirname(outputPath), { recursive: true })
  await writeFile(outputPath, `${JSON.stringify(corpus, null, 2)}\n`, "utf8")

  return {
    success: true,
    fileDocCount,
    embeddedCount,
    outputPath,
    scanRootUsed: readableRoot,
    warnings,
  }
}
