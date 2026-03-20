import type { RequestInterpretation } from "@/lib/server/copilot/schemas"

type BuildQueryTermsInput = {
  interpretation: RequestInterpretation
  question: string
}

function uniqueTerms(terms: string[]): string[] {
  return [...new Set(terms.map((term) => term.trim()).filter(Boolean))]
}

function tokenizeQuestion(question: string): string[] {
  return question
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((token) => token.length >= 4)
}

export function buildQueryTerms({ interpretation, question }: BuildQueryTermsInput): string[] {
  return uniqueTerms([
    interpretation.requestType,
    interpretation.summary,
    interpretation.endpoint,
    interpretation.analysisType,
    ...interpretation.timepoints,
    ...interpretation.outputTypes,
    ...interpretation.datasetHints,
    ...interpretation.outputFamilyHints,
    ...tokenizeQuestion(question),
  ])
}
