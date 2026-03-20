"use server"

import type { DetectedQuestion } from "@/lib/copilot/question-detection"
import { splitQuestions } from "@/lib/copilot/question-detection"
import { runWithMgaToken } from "@/lib/server/mga-token-context"

export type ExtractionResult = {
  questions: DetectedQuestion[]
  rawText: string | null
  error: string | null
}

export async function extractQuestionsFromPdf(
  formData: FormData,
): Promise<ExtractionResult> {
  const file = formData.get("file") as File | null
  if (!file) return { questions: [], rawText: null, error: "No file provided." }
  if (file.size > 10 * 1024 * 1024) return { questions: [], rawText: null, error: "PDF exceeds 10 MB limit." }
  if (file.type !== "application/pdf") return { questions: [], rawText: null, error: "File is not a PDF." }

  try {
    const buffer = Buffer.from(await file.arrayBuffer())
    const { PDFParse } = await import("pdf-parse")
    const pdf = new PDFParse({ data: new Uint8Array(buffer) })
    const { text } = await pdf.getText()
    await pdf.destroy()

    if (!text || text.trim().length === 0) {
      return { questions: [], rawText: null, error: "PDF contained no extractable text." }
    }

    return { questions: splitQuestions(text, "pdf"), rawText: text, error: null }
  } catch (error) {
    return {
      questions: [],
      rawText: null,
      error: error instanceof Error ? error.message : "Failed to parse PDF.",
    }
  }
}

export async function extractQuestionsFromImage(
  formData: FormData,
  mgaToken?: string,
): Promise<ExtractionResult> {
  const file = formData.get("file") as File | null
  if (!file) return { questions: [], rawText: null, error: "No file provided." }
  if (file.size > 5 * 1024 * 1024) return { questions: [], rawText: null, error: "Image exceeds 5 MB limit." }
  if (!["image/png", "image/jpeg", "image/webp"].includes(file.type)) {
    return { questions: [], rawText: null, error: "Unsupported image format. Use PNG, JPEG, or WebP." }
  }

  try {
    const buffer = Buffer.from(await file.arrayBuffer())
    const base64 = buffer.toString("base64")

    const { generateTextFromVision } = await import("@/lib/server/llm/openai")
    const visionResult = await runWithMgaToken(mgaToken, () =>
      generateTextFromVision({
        systemPrompt: "You are a document extraction assistant. Extract text accurately.",
        userPrompt:
          "Extract all text from this image exactly as it appears. If the text contains questions, return them as a numbered list.",
        imageBase64: base64,
        mimeType: file.type,
        maxTokens: 4000,
      }),
    )

    if (!visionResult) {
      return { questions: [], rawText: null, error: "Vision API is not configured (missing MGA_TOKEN)." }
    }

    const rawText = visionResult.text
    const questions = splitQuestions(rawText, "image")
    return { questions, rawText, error: null }
  } catch (error) {
    return {
      questions: [],
      rawText: null,
      error: error instanceof Error ? error.message : "Failed to extract questions from image.",
    }
  }
}
