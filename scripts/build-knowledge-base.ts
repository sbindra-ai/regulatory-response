import { existsSync, readFileSync } from "node:fs"
import { readFile, readdir, mkdir, writeFile } from "node:fs/promises"
import { dirname, resolve } from "node:path"

import { buildCorpus } from "@/lib/server/knowledge/build-corpus"
import { parsePdfFile, PDF_FILE_CONFIGS } from "@/lib/server/knowledge/parse-pdf-documents"
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
const defineXmlPath = resolve(workspaceRoot, "docs/examples/define.xml")
const programsDirectory = resolve(workspaceRoot, "docs/examples/programs")

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

async function loadPdfChunks(): Promise<PdfChunk[]> {
  const allChunks: PdfChunk[] = []

  for (const config of PDF_FILE_CONFIGS) {
    const fullPath = resolve(workspaceRoot, config.path)

    if (!existsSync(fullPath)) {
      console.warn(`PDF not found, skipping: ${config.path}`)
      continue
    }

    try {
      const buffer = readFileSync(fullPath)
      const chunks = await parsePdfFile(fullPath, buffer, config)
      allChunks.push(...chunks)
      console.log(`  Parsed ${config.path}: ${chunks.length} chunks`)
    } catch (error) {
      console.warn(`Failed to parse ${config.path}:`, error instanceof Error ? error.message : error)
    }
  }

  return allChunks
}

async function main() {
  const [readmeContent, defineXml, programFileNames] = await Promise.all([
    readFile(readmePath, "utf8"),
    readFile(defineXmlPath, "utf8"),
    readdir(programsDirectory),
  ])
  const programSources = await Promise.all(
    programFileNames
      .filter((fileName) => fileName.endsWith(".sas"))
      .map(async (fileName) => ({
        path: `docs/examples/programs/${fileName}`,
        content: await readFile(resolve(programsDirectory, fileName), "utf8"),
      })),
  )

  // Parse PDF documents
  console.log("Parsing PDF documents...")
  const pdfChunks = await loadPdfChunks()
  console.log(`Total PDF chunks: ${pdfChunks.length}`)

  // Build corpus first without embeddings to get document IDs and metadata
  const preliminaryCorpus = buildCorpus({
    defineXml,
    pdfChunks,
    programSources,
    readmeContent,
  })

  // Generate embeddings if MGA_TOKEN is available
  const mgaToken = process.env.MGA_TOKEN?.trim()
  const embeddingModel = process.env.MGA_EMBEDDING_MODEL?.trim() || DEFAULT_EMBEDDING_MODEL
  let embeddings: Map<string, number[]> | undefined
  let embeddingDimensions: number | null = null

  if (mgaToken) {
    console.log(`Generating embeddings with model: ${embeddingModel}...`)
    const docTexts = preliminaryCorpus.documents.map((doc) => buildEmbeddingText(doc))
    const docIds = preliminaryCorpus.documents.map((doc) => doc.id)

    try {
      // Batch in chunks of 20 to stay within API limits
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

  // Rebuild corpus with embeddings
  const corpus = buildCorpus({
    defineXml,
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
