import { createHash } from "node:crypto"
import { readdir, readFile, stat } from "node:fs/promises"
import { basename, extname, join, normalize, relative } from "node:path"

import type { EvidenceCorpus, EvidenceDocument } from "@/lib/server/copilot/schemas"
import type { ReadmeBrief } from "@/lib/server/knowledge/parse-readme"
import { parsePdfFile } from "@/lib/server/knowledge/parse-pdf-documents"

/** Only these extensions are ingested from the share. */
const ALLOWED_EXTENSIONS = new Set([".sas", ".txt", ".pdf", ".sas7bdat", ".xpt"])
const TEXT_EXTENSIONS = new Set([".txt", ".sas"])
const PDF_EXT = ".pdf"
const DATA_TRANSPORT_EXT = new Set([".sas7bdat", ".xpt"])

const SKIP_DIR_NAMES = new Set([
  "node_modules",
  ".git",
  ".svn",
  "dist",
  "build",
  ".next",
  "__pycache__",
])

const CHUNK_CHARS = 12_000
const MAX_CHUNKS_PER_FILE = 200
const MAX_FILE_BYTES = 80 * 1024 * 1024
const MAX_SOURCE_TEXT_CHARS = 50_000

function sanitizeAscii(text: string): string {
  return text.replace(/[^\x20-\x7E\n\r\t]/g, " ")
}

export function createNetworkReadmeBrief(scanRootDisplay: string): ReadmeBrief {
  return {
    id: "brief:product",
    path: "README.md",
    title: "Network share evidence index",
    summary: `Vector-indexed files scanned from ${scanRootDisplay}.`,
    keywords: ["network", "share", "samba", "evidence", "vector", "regulatory", "documents", "macros", "programs"],
    sourceText: [
      "# Network share evidence",
      "",
      `Files under this corpus were ingested from: ${scanRootDisplay}`,
      "",
      "Recommended layout (same idea as the bundled repo): **documents/** (PDF, Define-XML, specs), **macros/** (macro .sas), **programs/** (TLF and listing .sas). The indexer walks the whole tree.",
      "",
      "Select Network share as the evidence source in the copilot after running npm run ingest:network.",
    ].join("\n"),
  }
}

export function embeddingInputForDocument(doc: EvidenceDocument): string {
  return [
    doc.title,
    doc.summary,
    doc.keywords.join(", "),
    doc.datasetNames.join(", "),
    doc.outputFamilies.join(", "),
    doc.sourceText.slice(0, 12_000),
  ]
    .filter(Boolean)
    .join("\n")
}

function stableChunkId(chunkKey: string): string {
  const h = createHash("sha256").update(chunkKey).digest("hex").slice(0, 16)
  return `net:${h}`
}

/**
 * Persist absolute paths on network documents so the UI shows full UNC/mapped paths
 * (e.g. \\server\share\ia\stat\...\pgms\start.sas). Stable ids still use relative keys via {@link normalizeRel}.
 */
function absolutePathForStorage(absPath: string): string {
  const norm = normalize(absPath)
  if (process.platform === "win32") {
    return norm.replace(/\//g, "\\")
  }
  return norm
}

/** Persist the ingest root alongside documents so retrieval never guesses a share path. */
export function scanRootForCorpusStorage(root: string): string {
  return absolutePathForStorage(normalize(root.trim()))
}

function normalizeRel(root: string, absPath: string): string {
  const r = root.replace(/\\/g, "/").replace(/\/+$/, "")
  const a = absPath.replace(/\\/g, "/")
  const rLower = r.toLowerCase()
  const aLower = a.toLowerCase()
  if (aLower === rLower) return ""

  const prefix = `${rLower}/`
  if (aLower.startsWith(prefix)) {
    return a.slice(prefix.length)
  }

  try {
    return relative(root, absPath).replace(/\\/g, "/")
  } catch {
    return basename(absPath)
  }
}

function shouldSkipDir(name: string): boolean {
  return SKIP_DIR_NAMES.has(name.toLowerCase())
}

function isTextExtension(ext: string): boolean {
  return TEXT_EXTENSIONS.has(ext.toLowerCase())
}

/** Pull likely ADaM / SDTM-style dataset names from SAS or plain text for retrieval boosts. */
export function extractDatasetHintsFromText(text: string): string[] {
  const found = new Set<string>()
  const upper = text.toUpperCase()
  for (const match of upper.matchAll(/\b(AD[A-Z]{2,})\b/g)) {
    const name = match[1]
    if (name.length <= 12) found.add(name)
  }
  return [...found].slice(0, 24)
}

async function listFilesRecursive(root: string): Promise<string[]> {
  const out: string[] = []

  async function walk(dir: string): Promise<void> {
    let entries
    try {
      entries = await readdir(dir, { withFileTypes: true })
    } catch (e) {
      if (dir === root) {
        const err = e as NodeJS.ErrnoException
        throw new Error(
          `Cannot read network scan root "${root}" (${err.code ?? "UNKNOWN"}): ${err.message}.`,
          { cause: e },
        )
      }
      return
    }

    for (const ent of entries) {
      const full = join(dir, ent.name)
      if (ent.isDirectory()) {
        if (shouldSkipDir(ent.name)) continue
        await walk(full)
      } else if (ent.isFile()) {
        const ext = extname(ent.name).toLowerCase()
        if (!ALLOWED_EXTENSIONS.has(ext)) continue
        try {
          const st = await stat(full)
          if (st.size > MAX_FILE_BYTES) continue
        } catch {
          continue
        }
        out.push(full)
      }
    }
  }

  await walk(root)
  return out
}

function chunkPlainText(text: string): string[] {
  const normalized = text.replace(/\r\n/g, "\n").trim()
  if (!normalized) return []
  if (normalized.length <= CHUNK_CHARS) return [normalized]

  const chunks: string[] = []
  let start = 0

  while (start < normalized.length && chunks.length < MAX_CHUNKS_PER_FILE) {
    const end = Math.min(start + CHUNK_CHARS, normalized.length)
    let slice = normalized.slice(start, end)

    if (end < normalized.length) {
      const lastBreak = Math.max(slice.lastIndexOf("\n\n"), slice.lastIndexOf("\n"))
      if (lastBreak > CHUNK_CHARS * 0.4) {
        slice = slice.slice(0, lastBreak)
      }
    }

    const trimmed = slice.trim()
    if (trimmed.length > 0) chunks.push(trimmed)
    const advance = slice.length || CHUNK_CHARS
    start += advance
  }

  return chunks
}

function filenameKeywords(fileBase: string): string[] {
  return fileBase
    .replace(/\.[^.]+$/, "")
    .split(/[\s_\-./]+/)
    .map((s) => s.toLowerCase())
    .filter((s) => s.length > 2)
    .slice(0, 12)
}

function relativePathForNetworkUi(rel: string, base: string): string {
  const r = rel.length > 0 ? rel : base
  return r.replace(/\\/g, "/")
}

async function filePathToDocuments(absPath: string, root: string): Promise<EvidenceDocument[]> {
  const rel = normalizeRel(root, absPath)
  const fullPath = absolutePathForStorage(absPath)
  const ext = extname(absPath).toLowerCase()
  const base = basename(absPath)
  const relativePath = relativePathForNetworkUi(rel, base)

  if (DATA_TRANSPORT_EXT.has(ext)) {
    const baseUpper = base.toUpperCase()
    const ds = extractDatasetHintsFromText(`${baseUpper} ${rel.toUpperCase()}`)
    const summary = `Dataset transport: ${base}`
    return [
      {
        id: stableChunkId(`data:${rel}`),
        title: base,
        sourceType: "network-file" as const,
        path: fullPath,
        relativePath,
        summary,
        keywords: [...new Set([...filenameKeywords(base), ...ds.map((d) => d.toLowerCase())])].slice(0, 24),
        datasetNames: ds.length > 0 ? ds : extractDatasetHintsFromText(baseUpper),
        outputFamilies: [],
        sourceText: `Transport dataset file at ${fullPath}. Path and name are indexed for search; binary contents are not embedded here.`,
        embedding: null,
      },
    ]
  }

  if (ext === PDF_EXT) {
    const buffer = await readFile(absPath)
    const chunks = await parsePdfFile(fullPath, buffer, {
      path: fullPath,
      sourceType: "network-file",
      label: base.replace(/\.pdf$/i, ""),
    })

    return chunks.map((chunk, index) => {
      const cleanText = sanitizeAscii(chunk.text).trim()
      const body = cleanText.slice(0, MAX_SOURCE_TEXT_CHARS)
      const summary = body.slice(0, 1500)

      return {
        id: stableChunkId(`pdf:${rel}:${index}`),
        title: (sanitizeAscii(chunk.title) || `${base} (chunk ${index + 1})`).slice(0, 500),
        sourceType: "network-file" as const,
        path: fullPath,
        relativePath,
        summary,
        keywords: [...new Set([...chunk.keywords, ...filenameKeywords(base)])].slice(0, 24),
        datasetNames: [
          ...new Set([...chunk.referencedDatasets, ...extractDatasetHintsFromText(body)]),
        ].slice(0, 24),
        outputFamilies: chunk.referencedOutputs,
        sourceText: body.length > 0 ? body : summary,
        embedding: null,
      }
    })
  }

  if (!isTextExtension(ext)) return []

  let raw: string
  try {
    raw = await readFile(absPath, "utf8")
  } catch {
    return []
  }

  const parts = chunkPlainText(raw)

  return parts.map((text, index) => {
    const body = text.slice(0, MAX_SOURCE_TEXT_CHARS)
    const summary = body.slice(0, 1500)
    const ds = extractDatasetHintsFromText(body)

    return {
      id: stableChunkId(`txt:${rel}#${index}`),
      title: parts.length > 1 ? `${base} (part ${index + 1})` : base,
      sourceType: "network-file" as const,
      path: fullPath,
      relativePath,
      summary,
      keywords: [...new Set([...filenameKeywords(base), ...ds.map((d) => d.toLowerCase())])].slice(0, 24),
      datasetNames: ds,
      outputFamilies: [],
      sourceText: body,
      embedding: null,
    }
  })
}

export async function scanRootToDocuments(root: string): Promise<EvidenceDocument[]> {
  const normalizedRoot = root.trim()
  if (!normalizedRoot) return []

  const files = await listFilesRecursive(normalizedRoot)
  const documents: EvidenceDocument[] = []

  for (const abs of files.sort()) {
    try {
      documents.push(...await filePathToDocuments(abs, normalizedRoot))
    } catch {
      // skip unreadable or unsupported
    }
  }

  return documents
}

function buildBriefDocument(brief: ReadmeBrief): EvidenceDocument {
  return {
    id: brief.id,
    title: brief.title,
    sourceType: "brief",
    path: brief.path,
    summary: brief.summary,
    keywords: brief.keywords,
    datasetNames: [],
    outputFamilies: [],
    sourceText: brief.sourceText,
    embedding: null,
  }
}

export async function buildNetworkEvidenceCorpus(scanRoot: string): Promise<EvidenceCorpus> {
  const brief = createNetworkReadmeBrief(scanRoot)
  const scanned = await scanRootToDocuments(scanRoot)
  const documents = [buildBriefDocument(brief), ...scanned]

  return {
    generatedAt: new Date().toISOString(),
    embeddingModel: null,
    embeddingDimensions: null,
    brief,
    datasets: [],
    programs: [],
    documents,
    networkScanRoot: scanRootForCorpusStorage(scanRoot),
  }
}

/** Valid corpus when `evidence-corpus.network.json` is missing (no share ingest yet). */
export function buildPlaceholderNetworkCorpus(): EvidenceCorpus {
  const brief = createNetworkReadmeBrief(
    "Not built yet — map the share, set EVIDENCE_SCAN_ROOT, then run: npm run ingest:network",
  )
  return {
    generatedAt: new Date().toISOString(),
    embeddingModel: null,
    embeddingDimensions: null,
    brief,
    datasets: [],
    programs: [],
    documents: [buildBriefDocument(brief)],
  }
}
