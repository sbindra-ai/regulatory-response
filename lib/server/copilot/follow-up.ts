import "server-only"

import { generateStructuredObject } from "@/lib/server/llm/openai"
import {
  buildFollowUpSystemPrompt,
  buildFollowUpUserPrompt,
} from "@/lib/server/copilot/prompts"
import {
  followUpResultSchema,
  type CopilotResult,
  type FollowUpMessage,
  type TokenUsage,
} from "@/lib/server/copilot/schemas"

type GenerateFollowUpInput = {
  originalQuestion: string
  copilotResult: CopilotResult
  conversationHistory: FollowUpMessage[]
  newMessage: string
}

export async function generateFollowUp(input: GenerateFollowUpInput): Promise<{ answer: string; usage: TokenUsage }> {
  const { originalQuestion, copilotResult, conversationHistory, newMessage } = input

  const result = await generateStructuredObject({
    schema: followUpResultSchema,
    stage: "follow-up",
    systemPrompt: buildFollowUpSystemPrompt(),
    userPrompt: buildFollowUpUserPrompt(
      originalQuestion,
      copilotResult.interpretation,
      copilotResult.evidence,
      copilotResult.responsePlan,
      conversationHistory,
      newMessage,
    ),
  })

  if (!result) {
    throw new Error("MGA did not return a valid follow-up response. Is MGA_TOKEN set?")
  }

  return { answer: result.data.answer, usage: result.usage }
}
