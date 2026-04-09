import { describe, expect, it } from "vitest"

import { computeConfidenceScore } from "@/lib/server/copilot/confidence"
import type { EvidenceHit, RequestInterpretation } from "@/lib/server/copilot/schemas"

function makeInterpretation(overrides: Partial<RequestInterpretation> = {}): RequestInterpretation {
  return {
    requestType: "ae-summary",
    summary: "Overall AE summary request.",
    population: "Safety analysis set",
    endpoint: "Treatment-emergent adverse events",
    timepoints: ["Week 12"],
    analysisType: "Overall summary",
    statisticalModel: null,
    outputTypes: ["table"],
    datasetHints: ["ADAE", "ADSL"],
    outputFamilyHints: ["ae-overall"],
    confidence: "high",
    confidenceScore: {
      overall: 75,
      level: "high",
      interpretationScore: 75,
      evidenceRelevanceScore: 0,
      evidenceCoverageScore: 0,
      reasons: ["Placeholder"],
    },
    ...overrides,
  }
}

function makeEvidenceHit(overrides: Partial<EvidenceHit> = {}): EvidenceHit {
  return {
    document: {
      id: "program:test",
      title: "Test program",
      sourceType: "program",
      path: "test.sas",
      summary: "Test",
      keywords: ["ae"],
      datasetNames: ["ADAE"],
      outputFamilies: ["ae-overall"],
      sourceText: "test",
      embedding: null,
    },
    score: 50,
    matchedTerms: ["ae"],
    retrievalReason: "Test reason",
    vectorSimilarity: 0.85,
    keywordScore: 20,
    hybridRank: 1,
    ...overrides,
  }
}

describe("computeConfidenceScore", () => {
  it("returns high confidence for a well-specified known request type with good evidence", () => {
    const result = computeConfidenceScore({
      evidence: [makeEvidenceHit()],
      interpretation: makeInterpretation(),
      retrievalMethod: "hybrid",
    })

    expect(result.level).toBe("high")
    expect(result.overall).toBeGreaterThanOrEqual(70)
    expect(result.interpretationScore).toBe(100)
    expect(result.evidenceRelevanceScore).toBe(85)
    expect(result.reasons.length).toBeGreaterThan(0)
  })

  it("returns low confidence for unknown request type with no evidence", () => {
    const result = computeConfidenceScore({
      evidence: [],
      interpretation: makeInterpretation({
        requestType: "unknown",
        population: "Not explicitly stated",
        timepoints: ["Not explicitly stated"],
        datasetHints: [],
        outputFamilyHints: [],
      }),
      retrievalMethod: "keyword-only",
    })

    expect(result.level).toBe("low")
    expect(result.overall).toBeLessThan(40)
    expect(result.reasons).toContainEqual(expect.stringContaining("Request type could not be mapped"))
  })

  it("penalizes missing population", () => {
    const withPop = computeConfidenceScore({
      evidence: [makeEvidenceHit()],
      interpretation: makeInterpretation({ population: "Safety analysis set" }),
      retrievalMethod: "hybrid",
    })

    const withoutPop = computeConfidenceScore({
      evidence: [makeEvidenceHit()],
      interpretation: makeInterpretation({ population: "Not explicitly stated" }),
      retrievalMethod: "hybrid",
    })

    expect(withPop.interpretationScore).toBeGreaterThan(withoutPop.interpretationScore)
  })

  it("penalizes missing timepoints", () => {
    const withTp = computeConfidenceScore({
      evidence: [makeEvidenceHit()],
      interpretation: makeInterpretation({ timepoints: ["Week 12"] }),
      retrievalMethod: "hybrid",
    })

    const withoutTp = computeConfidenceScore({
      evidence: [makeEvidenceHit()],
      interpretation: makeInterpretation({ timepoints: ["Not explicitly stated"] }),
      retrievalMethod: "hybrid",
    })

    expect(withTp.interpretationScore).toBeGreaterThan(withoutTp.interpretationScore)
  })

  it("caps keyword-only relevance at 80", () => {
    const result = computeConfidenceScore({
      evidence: [
        makeEvidenceHit({
          vectorSimilarity: null,
          score: 0,
          keywordScore: 100,
        }),
      ],
      interpretation: makeInterpretation(),
      retrievalMethod: "keyword-only",
    })

    expect(result.evidenceRelevanceScore).toBeLessThanOrEqual(80)
    expect(result.reasons).toContainEqual(expect.stringContaining("keyword matching"))
  })

  it("computes coverage from matched datasets and families", () => {
    const fullCoverage = computeConfidenceScore({
      evidence: [
        makeEvidenceHit({
          document: {
            ...makeEvidenceHit().document,
            datasetNames: ["ADAE", "ADSL"],
            outputFamilies: ["ae-overall"],
          },
        }),
      ],
      interpretation: makeInterpretation({
        datasetHints: ["ADAE", "ADSL"],
        outputFamilyHints: ["ae-overall"],
      }),
      retrievalMethod: "hybrid",
    })

    expect(fullCoverage.evidenceCoverageScore).toBe(100)

    const partialCoverage = computeConfidenceScore({
      evidence: [
        makeEvidenceHit({
          document: {
            ...makeEvidenceHit().document,
            datasetNames: ["ADAE"],
            outputFamilies: [],
          },
        }),
      ],
      interpretation: makeInterpretation({
        datasetHints: ["ADAE", "ADSL"],
        outputFamilyHints: ["ae-overall"],
      }),
      retrievalMethod: "hybrid",
    })

    expect(partialCoverage.evidenceCoverageScore).toBeLessThan(100)
    expect(partialCoverage.evidenceCoverageScore).toBeGreaterThan(0)
  })

  it("assigns correct levels based on overall score", () => {
    // Known type + good hybrid evidence = high
    const highResult = computeConfidenceScore({
      evidence: [makeEvidenceHit({ vectorSimilarity: 0.9 })],
      interpretation: makeInterpretation(),
      retrievalMethod: "hybrid",
    })
    expect(highResult.level).toBe("high")

    // Unknown type, no evidence = low
    const lowResult = computeConfidenceScore({
      evidence: [],
      interpretation: makeInterpretation({
        requestType: "unknown",
        population: "Not explicitly stated",
        timepoints: ["Not explicitly stated"],
        datasetHints: [],
        outputFamilyHints: [],
      }),
      retrievalMethod: "keyword-only",
    })
    expect(lowResult.level).toBe("low")
  })
})
