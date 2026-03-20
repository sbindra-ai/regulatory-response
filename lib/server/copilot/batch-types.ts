import type { CopilotResult } from "@/lib/server/copilot/schemas"

export type BatchQuestionItem = {
  id: string
  text: string
  source: "text" | "pdf" | "image"
}

export type BatchQuestionResult = {
  questionId: string
  questionText: string
  result: CopilotResult | null
  error: string | null
}

export type BatchCopilotState = {
  results: BatchQuestionResult[]
  error: string | null
}
