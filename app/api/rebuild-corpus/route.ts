import { exec } from "node:child_process"

import { clearKnowledgeBaseCache } from "@/lib/server/copilot/knowledge-base"

export async function POST(): Promise<Response> {
  try {
    const result = await new Promise<{ stdout: string; stderr: string }>((resolve, reject) => {
      exec(
        "npx tsx scripts/build-knowledge-base.ts",
        { cwd: process.cwd(), timeout: 120_000 },
        (error, stdout, stderr) => {
          if (error) {
            reject(error)
          } else {
            resolve({ stdout, stderr })
          }
        },
      )
    })

    clearKnowledgeBaseCache()

    const output = [result.stdout, result.stderr].filter(Boolean).join("\n").trim()
    const embeddingMatch = output.match(/With embeddings: (\d+)/)
    const documentMatch = output.match(/Documents: (\d+)/)

    return Response.json({
      success: true,
      documentCount: documentMatch ? Number(documentMatch[1]) : null,
      embeddingCount: embeddingMatch ? Number(embeddingMatch[1]) : null,
      output,
    })
  } catch (error) {
    console.error("Corpus rebuild failed:", error)
    return Response.json(
      {
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}
