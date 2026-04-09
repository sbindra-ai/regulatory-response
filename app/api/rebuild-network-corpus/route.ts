import { clearKnowledgeBaseCache } from "@/lib/server/copilot/knowledge-base"
import { runNetworkIngest } from "@/lib/server/knowledge/run-network-ingest"

export const maxDuration = 600

export async function POST(request: Request): Promise<Response> {
  try {
    let scanRoot: string | undefined
    try {
      const body = (await request.json()) as { scanRoot?: string }
      scanRoot = typeof body?.scanRoot === "string" ? body.scanRoot : undefined
    } catch {
      // No JSON body — use env / default root
    }

    const result = await runNetworkIngest({ scanRootOverride: scanRoot })
    clearKnowledgeBaseCache()

    if (!result.success) {
      return Response.json(
        {
          success: false,
          error: result.error,
          scanRootUsed: result.scanRootUsed,
          documentCount: null,
          embeddingCount: null,
          warnings: result.warnings,
        },
        { status: 422 },
      )
    }

    return Response.json({
      success: true,
      documentCount: result.fileDocCount,
      embeddingCount: result.embeddedCount,
      scanRootUsed: result.scanRootUsed,
      outputPath: result.outputPath,
      warnings: result.warnings,
    })
  } catch (error) {
    console.error("Network corpus rebuild failed:", error)
    clearKnowledgeBaseCache()
    return Response.json(
      {
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 },
    )
  }
}
