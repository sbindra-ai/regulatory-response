import "server-only"

import { generateStructuredObject } from "@/lib/server/llm/openai"
import {
  buildPredictionsSystemPrompt,
  buildPredictionsUserPrompt,
} from "@/lib/server/copilot/prompts"
import {
  predictionsResultSchema,
  type CopilotResult,
  type PredictedQuestion,
  type TokenUsage,
} from "@/lib/server/copilot/schemas"

type PredictNextQuestionsInput = {
  originalQuestion: string
  copilotResult: CopilotResult
}

export async function predictNextQuestions(
  input: PredictNextQuestionsInput,
): Promise<{ predictions: PredictedQuestion[]; usage: TokenUsage }> {
  const { originalQuestion, copilotResult } = input

  const result = await generateStructuredObject({
    schema: predictionsResultSchema,
    stage: "predict-questions",
    systemPrompt: buildPredictionsSystemPrompt(),
    userPrompt: buildPredictionsUserPrompt(
      originalQuestion,
      copilotResult.interpretation,
      copilotResult.evidence,
      copilotResult.responsePlan,
    ),
  })

  if (!result) {
    throw new Error("MGA did not return valid predictions. Is MGA_TOKEN set?")
  }

  return { predictions: result.data.predictedQuestions, usage: result.usage }
}
