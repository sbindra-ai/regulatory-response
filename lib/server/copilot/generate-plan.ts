import "server-only"

import { generateStructuredObject } from "@/lib/server/llm/openai"
import {
  logCopilotStageStarted,
  logCopilotStageSucceeded,
  type CopilotRunLogContext,
} from "@/lib/server/copilot/logging"
import {
  buildPlanGenerationSystemPrompt,
  buildPlanGenerationUserPrompt,
} from "@/lib/server/copilot/prompts"
import {
  responsePlanSchema,
  type EvidenceHit,
  type RequestInterpretation,
  type ResponsePlan,
  type TokenUsage,
  type UncertaintyItem,
} from "@/lib/server/copilot/schemas"
import { getKnowledgeBase } from "@/lib/server/copilot/knowledge-base"

type GeneratePlanInput = {
  context?: CopilotRunLogContext
  evidence: EvidenceHit[]
  interpretation: RequestInterpretation
  options?: { maxTokens?: number; temperature?: number }
  question: string
}

export type GeneratedPlanBundle = {
  assumptions: UncertaintyItem[]
  evidenceGaps: UncertaintyItem[]
  openQuestions: UncertaintyItem[]
  responsePlan: ResponsePlan
  warnings: string[]
  usage: TokenUsage
}

type UncertaintyMetadata = Omit<GeneratedPlanBundle, "usage">

function unique(values: string[]): string[] {
  return [...new Set(values.filter(Boolean))]
}

function humanizeOutputFamily(outputFamily: string): string {
  const { corpus } = getKnowledgeBase()
  const match = corpus.documents.find(
    (d) => d.sourceType === "program" && d.outputFamilies.includes(outputFamily),
  )
  return match?.title ?? outputFamily
}

function buildUncertaintyMetadata({
  evidence,
  interpretation,
  question,
}: GeneratePlanInput): UncertaintyMetadata {
  const hasStrongEvidence =
    interpretation.requestType !== "unknown" &&
    evidence.some(
      (hit) =>
        hit.document.outputFamilies.some((family) => interpretation.outputFamilyHints.includes(family)) ||
        hit.document.datasetNames.some((datasetName) => interpretation.datasetHints.includes(datasetName)),
    )
  const citations = (hasStrongEvidence ? evidence : evidence.filter((hit) => hit.document.sourceType === "brief")).map(
    (hit) => hit.document.id,
  )
  const recommendedDatasets = hasStrongEvidence
    ? unique([...interpretation.datasetHints, ...evidence.flatMap((hit) => hit.document.datasetNames)]).slice(0, 6)
    : []
  const candidateOutputs = hasStrongEvidence
    ? unique([
        ...interpretation.outputFamilyHints.map(humanizeOutputFamily),
        ...evidence.flatMap((hit) => hit.document.outputFamilies.map(humanizeOutputFamily)),
        ...evidence.slice(0, 3).map((hit) => hit.document.title),
      ]).slice(0, 5)
    : []
  const assumptions: UncertaintyItem[] = [
    {
      title: "Closest available repo analogs",
      detail: "This plan is grounded in the closest matching repo examples rather than study-specific source data.",
    },
  ]
  const openQuestions: UncertaintyItem[] = []
  const evidenceGaps: UncertaintyItem[] = []
  const warnings = ["This output is an internal response plan, not final authority-facing wording."]

  if (interpretation.population === "Not explicitly stated") {
    openQuestions.push({
      title: "Confirm target population",
      detail: "The request does not clearly identify the final analysis population.",
    })
  }

  if (interpretation.timepoints.includes("Not explicitly stated")) {
    openQuestions.push({
      title: "Confirm timing window",
      detail: "The closest repo evidence was found, but the final request timing still needs confirmation.",
    })
  }

  if (interpretation.requestType === "unknown") {
    evidenceGaps.push({
      title: "No close evidence family found",
      detail: "The current repo examples do not directly cover this request family.",
    })
    warnings.push("Evidence is weak for this request, so the plan stays deliberately conservative.")
  }

  if (evidence.length === 0) {
    evidenceGaps.push({
      title: "No evidence hits returned",
      detail: "The retrieval stage did not surface any matching repo assets.",
    })
    warnings.push("No directly relevant repo evidence was found.")
  }

  const responsePlan: ResponsePlan = {
    objective: `Create a grounded starter plan for: ${question}`,
    recommendedApproach:
      hasStrongEvidence
        ? `Start from ${evidence
            .slice(0, 2)
            .map((hit) => hit.document.title)
            .join(" and ")}, then validate the exact scope before drafting deliverables.`
        : "Clarify the request scope first, then identify any study-specific assets outside the current repo examples.",
    recommendedDatasets,
    candidateOutputs,
    deliverables: unique(["Internal response plan", ...interpretation.outputTypes.map((outputType) => `Draft ${outputType} review`)])
      .slice(0, 4),
    responsibilities: [
      { role: "Statistician", tasks: ["Define analysis methodology", "Review statistical outputs"] },
      { role: "SAS Programmer", tasks: ["Adapt existing programs to new scope", "Generate TLFs"] },
      { role: "Data Scientist", tasks: ["Create exploratory charts and visualizations"] },
    ],
    citations: citations.slice(0, 5),
  }

  return {
    assumptions,
    evidenceGaps,
    openQuestions,
    responsePlan,
    warnings,
  }
}

export async function generatePlan(input: GeneratePlanInput): Promise<GeneratedPlanBundle> {
  const uncertaintyMetadata = buildUncertaintyMetadata(input)

  logCopilotStageStarted("generatePlan", {
    context: input.context,
    evidenceCount: input.evidence.length,
    questionLength: input.question.length,
  })

  const llmResult = await generateStructuredObject({
    maxTokens: input.options?.maxTokens,
    runId: input.context?.runId,
    schema: responsePlanSchema,
    stage: "generate-plan",
    systemPrompt: buildPlanGenerationSystemPrompt(),
    temperature: input.options?.temperature,
    userPrompt: buildPlanGenerationUserPrompt(input.question, input.interpretation, input.evidence),
  })

  if (!llmResult) {
    throw new Error("MGA did not return a valid response plan. Is MGA_TOKEN set?")
  }

  const result = {
    ...uncertaintyMetadata,
    responsePlan: llmResult.data,
    usage: llmResult.usage,
  }

  logCopilotStageSucceeded("generatePlan", {
    context: input.context,
    evidenceCount: input.evidence.length,
    gapCount: result.evidenceGaps.length,
    questionLength: input.question.length,
    requestType: input.interpretation.requestType,
    warningCount: result.warnings.length,
  })

  return result
}
