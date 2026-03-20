"use server"

import type { CopilotResult, PredictedQuestion, TokenUsage } from "@/lib/server/copilot/schemas"
import { predictNextQuestions } from "@/lib/server/copilot/predict-questions"
import { runWithMgaToken } from "@/lib/server/mga-token-context"

export type PredictQuestionsActionResult = {
  predictions: PredictedQuestion[]
  usage: TokenUsage | null
  error: string | null
}

export async function predictQuestionsAction(
  originalQuestion: string,
  copilotResult: CopilotResult,
  mgaToken?: string,
): Promise<PredictQuestionsActionResult> {
  try {
    const { predictions, usage } = await runWithMgaToken(mgaToken, () =>
      predictNextQuestions({
        originalQuestion,
        copilotResult,
      }),
    )
    return { predictions, usage, error: null }
  } catch (error) {
    return {
      predictions: [],
      usage: null,
      error: error instanceof Error ? error.message : "Failed to predict follow-up questions.",
    }
  }
}
