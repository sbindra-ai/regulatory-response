import "server-only"

import { generateStructuredObject } from "@/lib/server/llm/openai"
import {
  buildInterpretationSystemPrompt,
  buildInterpretationUserPrompt,
} from "@/lib/server/copilot/prompts"
import {
  requestInterpretationSchema,
  type ConfidenceScore,
  type RequestInterpretation,
  type TokenUsage,
} from "@/lib/server/copilot/schemas"
import {
  logCopilotStageStarted,
  logCopilotStageSucceeded,
  type CopilotRunLogContext,
} from "@/lib/server/copilot/logging"
import { getKnowledgeBase } from "@/lib/server/copilot/knowledge-base"

function placeholderConfidenceScore(level: "low" | "medium" | "high"): ConfidenceScore {
  const overall = level === "high" ? 75 : level === "medium" ? 50 : 25
  return {
    overall,
    level,
    interpretationScore: overall,
    evidenceRelevanceScore: 0,
    evidenceCoverageScore: 0,
    reasons: ["Placeholder - will be recomputed after evidence retrieval"],
  }
}

function extractTimepoints(question: string): string[] {
  const weekMatches = [...question.matchAll(/\bweek(?:s)?\s*(\d+)/gi)].map((match) => `Week ${match[1]}`)

  if (weekMatches.length > 0) {
    return [...new Set(weekMatches)]
  }

  if (/during treatment/i.test(question)) {
    return ["During treatment"]
  }

  return ["Not explicitly stated"]
}

function extractPopulationFromQuestion(question: string): string {
  if (/safety analysis set|safety population/i.test(question)) {
    return "Safety analysis set"
  }

  if (/full analysis set|\bfas\b/i.test(question)) {
    return "Full analysis set"
  }

  if (/intent.to.treat|\bitt\b/i.test(question)) {
    return "Intent-to-treat population"
  }

  if (/per.protocol|\bpp\b/i.test(question)) {
    return "Per-protocol population"
  }

  if (/race/i.test(question)) {
    return "Race subgroup"
  }

  if (/subject-level/i.test(question)) {
    return "Subject-level follow-up"
  }

  return "Not explicitly stated"
}

function buildBaseInterpretation(question: string): RequestInterpretation {
  const { corpus } = getKnowledgeBase()
  const timepoints = extractTimepoints(question)
  const population = extractPopulationFromQuestion(question)

  // Scan the knowledge base for dataset and output family hints from the question
  const questionLower = question.toLowerCase()
  const datasetHints: string[] = []
  const outputFamilyHints: string[] = []

  const seenDatasets = new Set<string>()
  const seenFamilies = new Set<string>()

  for (const doc of corpus.documents) {
    if (doc.sourceType !== "program") continue

    // Check if any keyword or title term appears in the question
    const titleLower = doc.title.toLowerCase()
    const hasRelevance =
      doc.keywords.some((kw) => kw.length >= 4 && questionLower.includes(kw)) ||
      titleLower.split(/\s+/).some((word) => word.length >= 4 && questionLower.includes(word))

    if (hasRelevance) {
      for (const ds of doc.datasetNames) {
        if (!seenDatasets.has(ds)) {
          seenDatasets.add(ds)
          datasetHints.push(ds)
        }
      }
      for (const fam of doc.outputFamilies) {
        if (!seenFamilies.has(fam)) {
          seenFamilies.add(fam)
          outputFamilyHints.push(fam)
        }
      }
    }
  }

  return {
    requestType: "unknown",
    summary: question,
    population,
    endpoint: "To be determined by LLM",
    timepoints,
    analysisType: "To be determined by LLM",
    statisticalModel: null,
    outputTypes: ["plan"],
    datasetHints: datasetHints.slice(0, 6),
    outputFamilyHints: outputFamilyHints.slice(0, 4),
    confidence: "low",
    confidenceScore: placeholderConfidenceScore("low"),
  }
}

export type InterpretRequestResult = {
  interpretation: RequestInterpretation
  usage: TokenUsage
}

export async function interpretRequest(
  question: string,
  context?: CopilotRunLogContext,
  options?: { maxTokens?: number; temperature?: number },
): Promise<InterpretRequestResult> {
  const heuristicHint = buildBaseInterpretation(question)

  logCopilotStageStarted("interpretRequest", {
    context,
    questionLength: question.length,
  })

  const result = await generateStructuredObject({
    maxTokens: options?.maxTokens,
    runId: context?.runId,
    schema: requestInterpretationSchema,
    stage: "interpret-request",
    systemPrompt: buildInterpretationSystemPrompt(),
    temperature: options?.temperature,
    userPrompt: buildInterpretationUserPrompt(question, heuristicHint),
  })

  if (!result) {
    throw new Error("MGA did not return a valid interpretation. Is MGA_TOKEN set?")
  }

  logCopilotStageSucceeded("interpretRequest", {
    context,
    questionLength: question.length,
    requestType: result.data.requestType,
  })

  return { interpretation: result.data, usage: result.usage }
}
