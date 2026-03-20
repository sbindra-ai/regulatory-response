import "server-only"

import { randomUUID } from "node:crypto"

import { logServerEvent } from "@/lib/server/logger"

type CopilotStageSlot = {
  fallbackReason: null
  usedMga: boolean
}

export type CopilotRunLogContext = {
  generatePlan: CopilotStageSlot
  interpretRequest: CopilotStageSlot
  runId: string
}

type StageKind = "generatePlan" | "interpretRequest"

function getStageMetadata(stage: StageKind): { eventPrefix: string; stageName: string } {
  switch (stage) {
    case "generatePlan":
      return {
        eventPrefix: "copilot.plan",
        stageName: "generate-plan",
      }
    case "interpretRequest":
      return {
        eventPrefix: "copilot.interpret",
        stageName: "interpret-request",
      }
  }
}

function getStageSlot(context: CopilotRunLogContext, stage: StageKind): CopilotStageSlot {
  switch (stage) {
    case "generatePlan":
      return context.generatePlan
    case "interpretRequest":
      return context.interpretRequest
  }
}

export function createCopilotRunLogContext(): CopilotRunLogContext {
  return {
    generatePlan: {
      fallbackReason: null,
      usedMga: false,
    },
    interpretRequest: {
      fallbackReason: null,
      usedMga: false,
    },
    runId: randomUUID(),
  }
}

export function logCopilotStageStarted(
  stage: StageKind,
  metadata: { context?: CopilotRunLogContext; evidenceCount?: number; questionLength: number },
): void {
  const { eventPrefix, stageName } = getStageMetadata(stage)

  logServerEvent("info", `${eventPrefix}.started`, {
    evidenceCount: metadata.evidenceCount,
    questionLength: metadata.questionLength,
    runId: metadata.context?.runId,
    stage: stageName,
  })
}

export function logCopilotStageSucceeded(
  stage: StageKind,
  metadata: {
    context?: CopilotRunLogContext
    evidenceCount?: number
    gapCount?: number
    questionLength: number
    requestType?: string
    warningCount?: number
  },
): void {
  const { eventPrefix, stageName } = getStageMetadata(stage)

  if (metadata.context) {
    const slot = getStageSlot(metadata.context, stage)
    slot.fallbackReason = null
    slot.usedMga = true
  }

  logServerEvent("info", `${eventPrefix}.succeeded`, {
    evidenceCount: metadata.evidenceCount,
    gapCount: metadata.gapCount,
    questionLength: metadata.questionLength,
    requestType: metadata.requestType,
    runId: metadata.context?.runId,
    stage: stageName,
    usedMga: true,
    warningCount: metadata.warningCount,
  })
}

export function logCopilotStageCompleted(
  context: CopilotRunLogContext,
  stage: string,
  metadata: { latencyMs: number },
): void {
  logServerEvent("info", `copilot.stage.completed`, {
    latencyMs: metadata.latencyMs,
    runId: context.runId,
    stage,
  })
}

export function logCopilotRunStarted(context: CopilotRunLogContext, questionLength: number): void {
  logServerEvent("info", "copilot.run.started", {
    questionLength,
    runId: context.runId,
  })
}

export function logCopilotRunCompleted(
  context: CopilotRunLogContext,
  metadata: {
    assumptionCount: number
    confidenceOverall?: number
    evidenceCount: number
    evidenceGapCount: number
    latencyMs: number
    openQuestionCount: number
    questionLength: number
    retrievalMethod?: string
    warningCount: number
  },
): void {
  logServerEvent("info", "copilot.run.completed", {
    assumptionCount: metadata.assumptionCount,
    confidenceOverall: metadata.confidenceOverall,
    evidenceCount: metadata.evidenceCount,
    evidenceGapCount: metadata.evidenceGapCount,
    latencyMs: metadata.latencyMs,
    openQuestionCount: metadata.openQuestionCount,
    questionLength: metadata.questionLength,
    retrievalMethod: metadata.retrievalMethod,
    runId: context.runId,
    usedMgaForInterpretation: context.interpretRequest.usedMga,
    usedMgaForPlan: context.generatePlan.usedMga,
    warningCount: metadata.warningCount,
  })
}

export function logCopilotRunRejected(context: CopilotRunLogContext, questionLength: number): void {
  logServerEvent("warn", "copilot.run.rejected", {
    questionLength,
    runId: context.runId,
  })
}

export function logCopilotRunFailed(
  context: CopilotRunLogContext,
  metadata: { errorName: string; latencyMs: number; questionLength: number },
): void {
  logServerEvent("error", "copilot.run.failed", {
    errorName: metadata.errorName,
    hasErrorDetails: true,
    latencyMs: metadata.latencyMs,
    questionLength: metadata.questionLength,
    runId: context.runId,
    usedMgaForInterpretation: context.interpretRequest.usedMga,
    usedMgaForPlan: context.generatePlan.usedMga,
  })
}
