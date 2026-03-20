"use server"

import type { CopilotResult } from "@/lib/server/copilot/schemas"
import { runCopilot } from "@/lib/server/copilot/run-copilot"
import { runWithMgaToken } from "@/lib/server/mga-token-context"

export type RunCopilotActionState = {
  error: string | null
  question: string
  result: CopilotResult | null
}

export async function runCopilotAction(
  _previousState: RunCopilotActionState,
  formData: FormData,
): Promise<RunCopilotActionState> {
  const question = String(formData.get("question") ?? "").trim()

  if (!question) {
    return {
      error: "Enter a regulatory question to run the copilot.",
      question,
      result: null,
    }
  }

  const maxTokensRaw = formData.get("maxTokens")
  const temperatureRaw = formData.get("temperature")
  const maxTokens = maxTokensRaw ? Number(maxTokensRaw) : undefined
  const temperature = temperatureRaw ? Number(temperatureRaw) : undefined
  const mgaToken = formData.get("mgaToken")?.toString().trim() || undefined

  try {
    return {
      error: null,
      question,
      result: await runWithMgaToken(mgaToken, () =>
        runCopilot(question, {
          maxTokens: maxTokens && maxTokens > 0 ? maxTokens : undefined,
          temperature: temperature !== undefined && !Number.isNaN(temperature) ? temperature : undefined,
        }),
      ),
    }
  } catch (error) {
    return {
      error: error instanceof Error ? error.message : "The copilot could not generate a response plan.",
      question,
      result: null,
    }
  }
}
