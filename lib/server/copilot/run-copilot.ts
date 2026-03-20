import "server-only"

import { computeConfidenceScore } from "@/lib/server/copilot/confidence"
import { generatePlan } from "@/lib/server/copilot/generate-plan"
import { interpretRequest } from "@/lib/server/copilot/interpret-request"
import {
  createCopilotRunLogContext,
  logCopilotRunCompleted,
  logCopilotRunFailed,
  logCopilotRunRejected,
  logCopilotRunStarted,
  logCopilotStageCompleted,
} from "@/lib/server/copilot/logging"
import { retrieveEvidence } from "@/lib/server/copilot/retrieve-evidence"
import { generateEmbeddings } from "@/lib/server/llm/openai"
import { copilotResultSchema, type CopilotResult } from "@/lib/server/copilot/schemas"

export type CopilotOptions = {
  maxTokens?: number
  temperature?: number
}

export async function runCopilot(question: string, options?: CopilotOptions): Promise<CopilotResult> {
  const normalizedQuestion = question.trim()
  const context = createCopilotRunLogContext()
  const startedAt = Date.now()

  if (!normalizedQuestion) {
    logCopilotRunRejected(context, normalizedQuestion.length)
    throw new Error("Enter a regulatory question to run the copilot.")
  }

  logCopilotRunStarted(context, normalizedQuestion.length)

  try {
    // Stage 1 + embedding: run interpretation and embedding generation in parallel
    const stage1Start = Date.now()
    const [interpretResult, queryEmbeddings] = await Promise.all([
      interpretRequest(normalizedQuestion, context, options),
      generateEmbeddings(normalizedQuestion),
    ])
    const { interpretation, usage: interpretUsage } = interpretResult
    logCopilotStageCompleted(context, "interpret+embed", { latencyMs: Date.now() - stage1Start })

    // Stage 2: retrieve evidence using pre-computed embeddings
    const stage2Start = Date.now()
    const { evidence, retrievalMetadata } = await retrieveEvidence({
      interpretation,
      precomputedEmbeddings: queryEmbeddings,
      question: normalizedQuestion,
    })

    const confidenceScore = computeConfidenceScore({
      evidence,
      interpretation,
      retrievalMethod: retrievalMetadata.method,
    })
    interpretation.confidenceScore = confidenceScore
    interpretation.confidence = confidenceScore.level
    logCopilotStageCompleted(context, "retrieve+confidence", { latencyMs: Date.now() - stage2Start })

    // Stage 3: generate plan
    const stage3Start = Date.now()
    const planBundle = await generatePlan({
      context,
      evidence,
      interpretation,
      options,
      question: normalizedQuestion,
    })
    logCopilotStageCompleted(context, "generate-plan", { latencyMs: Date.now() - stage3Start })

    const tokenUsage = {
      promptTokens: interpretUsage.promptTokens + planBundle.usage.promptTokens,
      completionTokens: interpretUsage.completionTokens + planBundle.usage.completionTokens,
      totalTokens: interpretUsage.totalTokens + planBundle.usage.totalTokens,
    }

    const result = copilotResultSchema.parse({
      interpretation,
      evidence,
      ...planBundle,
      retrievalMetadata,
      tokenUsage,
    })

    logCopilotRunCompleted(context, {
      assumptionCount: result.assumptions.length,
      confidenceOverall: confidenceScore.overall,
      evidenceCount: result.evidence.length,
      evidenceGapCount: result.evidenceGaps.length,
      latencyMs: Date.now() - startedAt,
      openQuestionCount: result.openQuestions.length,
      questionLength: normalizedQuestion.length,
      retrievalMethod: retrievalMetadata.method,
      warningCount: result.warnings.length,
    })

    return result
  } catch (error) {
    logCopilotRunFailed(context, {
      errorName: error instanceof Error ? error.name : "UnknownError",
      latencyMs: Date.now() - startedAt,
      questionLength: normalizedQuestion.length,
    })
    throw error
  }
}
