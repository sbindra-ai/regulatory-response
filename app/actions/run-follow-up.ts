"use server"

import type { CopilotResult, FollowUpMessage, TokenUsage } from "@/lib/server/copilot/schemas"
import { generateFollowUp } from "@/lib/server/copilot/follow-up"
import { runWithMgaToken } from "@/lib/server/mga-token-context"

export type FollowUpActionResult = {
  answer: string | null
  usage: TokenUsage | null
  error: string | null
}

export async function runFollowUpAction(
  originalQuestion: string,
  copilotResult: CopilotResult,
  conversationHistory: FollowUpMessage[],
  newMessage: string,
  mgaToken?: string,
): Promise<FollowUpActionResult> {
  const trimmed = newMessage.trim()
  if (!trimmed) {
    return { answer: null, usage: null, error: "Please enter a follow-up question." }
  }

  try {
    const { answer, usage } = await runWithMgaToken(mgaToken, () =>
      generateFollowUp({
        originalQuestion,
        copilotResult,
        conversationHistory,
        newMessage: trimmed,
      }),
    )
    return { answer, usage, error: null }
  } catch (error) {
    return {
      answer: null,
      usage: null,
      error: error instanceof Error ? error.message : "Failed to generate follow-up response.",
    }
  }
}
