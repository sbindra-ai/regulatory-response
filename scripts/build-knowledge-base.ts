import { existsSync, readFileSync } from "node:fs"
import { readFile, readdir, mkdir, writeFile, stat } from "node:fs/promises"
import { dirname, join, relative, resolve } from "node:path"

import { buildCorpus } from "@/lib/server/knowledge/build-corpus"
import { inferPdfFileConfig, parsePdfFile, PDF_FILE_CONFIGS } from "@/lib/server/knowledge/parse-pdf-documents"
import type { PdfChunk } from "@/lib/server/knowledge/parse-pdf-documents"

// Load .env since tsx doesn't do it automatically (Next.js does at runtime)
const envPath = resolve(process.cwd(), ".env")
if (existsSync(envPath)) {
  for (const line of readFileSync(envPath, "utf8").split("\n")) {
    const match = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*"?([^"]*)"?\s*$/)
    if (match && !process.env[match[1]]) {
      process.env[match[1]] = match[2]
    }
  }
}

const workspaceRoot = process.cwd()
const outputPath = resolve(workspaceRoot, "data/copilot/evidence-corpus.json")
const readmePath = resolve(workspaceRoot, "README.md")
const programsDirectory = resolve(workspaceRoot, "docs/examples/programs")
const macrosDirectory = resolve(workspaceRoot, "docs/examples/macros")
const documentsDirectory = resolve(workspaceRoot, "docs/examples/documents")

const MGA_BASE_URL = "https://chat.int.bayer.com/api/v2"
const DEFAULT_EMBEDDING_MODEL = "text-embedding-3-small"

type EmbeddingResponse = {
  data: Array<{ embedding: number[] }>
}

async function fetchEmbeddings(
  texts: string[],
  apiKey: string,
  model: string,
): Promise<number[][]> {
  const { default: OpenAI } = await import("openai")
  const client = new OpenAI({ apiKey, baseURL: MGA_BASE_URL })
  const response = (await client.embeddings.create({
    input: texts,
    model,
  })) as EmbeddingResponse

  return response.data.map((item) => item.embedding)
}

function buildEmbeddingText(doc: { title: string; summary: string; keywords: string[]; datasetNames: string[]; outputFamilies: string[] }): string {
  return [doc.title, doc.summary, doc.keywords.join(", "), doc.datasetNames.join(", "), doc.outputFamilies.join(", ")]
    .filter(Boolean)
    .join("\n")
}

async function walkPdfFiles(dir: string): Promise<string[]> {
  const out: string[] = []
  async function walk(d: string): Promise<void> {
    let entries
    try {
      entries = await readdir(d, { withFileTypes: true })
    } catch {
      return
    }
    for (const e of entries) {
      const full = join(d, e.name)
      if (e.isDirectory()) await walk(full)
      else if (e.isFile() && e.name.toLowerCase().endsWith(".pdf")) out.push(full)
    }
  }
  await walk(dir)
  return out
}

async function loadPdfChunks(): Promise<PdfChunk[]> {
  const allChunks: PdfChunk[] = []
  const seenRel = new Set<string>()

  if (existsSync(documentsDirectory)) {
    for (const abs of await walkPdfFiles(documentsDirectory)) {
      const rel = relative(workspaceRoot, abs).replace(/\\/g, "/")
      if (seenRel.has(rel)) continue
      seenRel.add(rel)
      try {
        const buffer = readFileSync(abs)
        const chunks = await parsePdfFile(abs, buffer, inferPdfFileConfig(rel))
        allChunks.push(...chunks)
        console.log(`  Parsed ${rel}: ${chunks.length} chunks`)
      } catch (error) {
        console.warn(`Failed to parse ${rel}:`, error instanceof Error ? error.message : error)
      }
    }
  }

  for (const config of PDF_FILE_CONFIGS) {
    if (seenRel.has(config.path)) continue
    const fullPath = resolve(workspaceRoot, config.path)
    if (!existsSync(fullPath)) {
      console.warn(`PDF not found, skipping: ${config.path}`)
      continue
    }
    try {
      const buffer = readFileSync(fullPath)
      const chunks = await parsePdfFile(fullPath, buffer, config)
      allChunks.push(...chunks)
      seenRel.add(config.path)
      console.log(`  Parsed ${config.path}: ${chunks.length} chunks`)
    } catch (error) {
      console.warn(`Failed to parse ${config.path}:`, error instanceof Error ? error.message : error)
    }
  }

  return allChunks
}

async function collectSasProgramSources(): Promise<Array<{ path: string; content: string }>> {
  const out: Array<{ path: string; content: string }> = []
  for (const absDir of [programsDirectory, macrosDirectory]) {
    if (!existsSync(absDir)) continue
    const names = await readdir(absDir)
    for (const fileName of names.filter((n) => n.toLowerCase().endsWith(".sas"))) {
      const abs = join(absDir, fileName)
      const st = await stat(abs).catch(() => null)
      if (!st?.isFile()) continue
      const rel = relative(workspaceRoot, abs).replace(/\\/g, "/")
      out.push({ path: rel, content: await readFile(abs, "utf8") })
    }
  }
  return out.sort((a, b) => a.path.localeCompare(b.path))
}

function resolveDefineXmlPaths(): { absolute: string; datasetDocPath: string } {
  const candidates = [
    resolve(workspaceRoot, "docs/examples/documents/define.xml"),
    resolve(workspaceRoot, "docs/examples/define.xml"),
  ]
  const absolute = candidates.find((p) => existsSync(p)) ?? candidates[1]
  return {
    absolute,
    datasetDocPath: relative(workspaceRoot, absolute).replace(/\\/g, "/"),
  }
}

async function main() {
  const { absolute: defineXmlPathResolved, datasetDocPath: defineDatasetDocumentPath } = resolveDefineXmlPaths()

  const [readmeContent, defineXml, programSources] = await Promise.all([
    readFile(readmePath, "utf8"),
    readFile(defineXmlPathResolved, "utf8"),
    collectSasProgramSources(),
  ])

  console.log(`Define-XML: ${defineDatasetDocumentPath}`)
  console.log(`SAS sources: ${programSources.length} files under programs/ and macros/`)

  console.log("Parsing PDF documents...")
  const pdfChunks = await loadPdfChunks()
  console.log(`Total PDF chunks: ${pdfChunks.length}`)

  const preliminaryCorpus = buildCorpus({
    defineXml,
    defineDatasetDocumentPath,
    pdfChunks,
    programSources,
    readmeContent,
  })

  const mgaToken = process.env.MGA_TOKEN?.trim()
  const embeddingModel = process.env.MGA_EMBEDDING_MODEL?.trim() || DEFAULT_EMBEDDING_MODEL
  let embeddings: Map<string, number[]> | undefined
  let embeddingDimensions: number | null = null

  if (mgaToken) {
    console.log(`Generating embeddings with model: ${embeddingModel}...`)
    const docTexts = preliminaryCorpus.documents.map((doc) => buildEmbeddingText(doc))
    const docIds = preliminaryCorpus.documents.map((doc) => doc.id)

    try {
      const BATCH_SIZE = 20
      const allEmbeddings: number[][] = []

      for (let i = 0; i < docTexts.length; i += BATCH_SIZE) {
        const batch = docTexts.slice(i, i + BATCH_SIZE)
        const batchEmbeddings = await fetchEmbeddings(batch, mgaToken, embeddingModel)
        allEmbeddings.push(...batchEmbeddings)
        console.log(`  Embedded ${Math.min(i + BATCH_SIZE, docTexts.length)}/${docTexts.length} documents`)
      }

      embeddings = new Map<string, number[]>()
      for (let i = 0; i < docIds.length; i++) {
        embeddings.set(docIds[i], allEmbeddings[i])
      }

      embeddingDimensions = allEmbeddings[0]?.length ?? null
      console.log(`Embeddings generated: ${allEmbeddings.length} documents, ${embeddingDimensions} dimensions`)
    } catch (error) {
      console.warn("Failed to generate embeddings, continuing without:", error instanceof Error ? error.message : error)
    }
  } else {
    console.warn("MGA_TOKEN not set - skipping embeddings. Corpus will use keyword-only search.")
  }

  const corpus = buildCorpus({
    defineXml,
    defineDatasetDocumentPath,
    embeddings,
    embeddingModel: embeddings ? embeddingModel : null,
    embeddingDimensions,
    pdfChunks,
    programSources,
    readmeContent,
  })

  await mkdir(dirname(outputPath), { recursive: true })
  await writeFile(outputPath, `${JSON.stringify(corpus, null, 2)}\n`, "utf8")

  console.log(`Wrote evidence corpus to ${outputPath}`)
  console.log(`  Documents: ${corpus.documents.length}`)
  console.log(`  Programs: ${corpus.programs.length}`)
  console.log(`  PDF chunks: ${pdfChunks.length}`)
  console.log(`  With embeddings: ${corpus.documents.filter((d) => d.embedding !== null).length}`)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
