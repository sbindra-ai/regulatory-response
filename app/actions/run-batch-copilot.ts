"use server"

import type {
  BatchCopilotState,
  BatchQuestionItem,
  BatchQuestionResult,
} from "@/lib/server/copilot/batch-types"
import { runCopilot } from "@/lib/server/copilot/run-copilot"
import { runWithMgaToken } from "@/lib/server/mga-token-context"

export async function runBatchCopilotAction(
  questions: BatchQuestionItem[],
  options: { maxTokens?: number; temperature?: number },
  mgaToken?: string,
): Promise<BatchCopilotState> {
  if (questions.length === 0 || questions.length > 20) {
    return {
      results: [],
      error: `Expected 1–20 questions, received ${questions.length}.`,
    }
  }

  const results: BatchQuestionResult[] = []

  for (const q of questions) {
    try {
      const result = await runWithMgaToken(mgaToken, () => runCopilot(q.text, options))
      results.push({
        questionId: q.id,
        questionText: q.text,
        result,
        error: null,
      })
    } catch (error) {
      results.push({
        questionId: q.id,
        questionText: q.text,
        result: null,
        error: error instanceof Error ? error.message : "Unknown error",
      })
    }
  }

  return { results, error: null }
}
