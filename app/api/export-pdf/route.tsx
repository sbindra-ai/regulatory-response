import { renderToBuffer } from "@react-pdf/renderer"
import { z } from "zod"

import { CopilotReport } from "@/lib/server/pdf/copilot-report"
import { copilotResultSchema } from "@/lib/server/copilot/schemas"

const exportRequestSchema = z.object({
  question: z.string().min(1),
  result: copilotResultSchema,
})

export async function POST(request: Request): Promise<Response> {
  let body: unknown

  try {
    body = await request.json()
  } catch {
    return Response.json({ error: "Invalid JSON body." }, { status: 400 })
  }

  const parsed = exportRequestSchema.safeParse(body)

  if (!parsed.success) {
    return Response.json(
      { error: "Invalid request body.", details: parsed.error.issues },
      { status: 400 },
    )
  }

  const document = <CopilotReport question={parsed.data.question} result={parsed.data.result} />

  try {
    const buffer = await renderToBuffer(document)

    return new Response(new Uint8Array(buffer), {
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": 'attachment; filename="copilot-response-plan-specification.pdf"',
      },
    })
  } catch (error) {
    console.error("PDF render failed:", error)
    return Response.json({ error: "Failed to generate PDF." }, { status: 500 })
  }
}
