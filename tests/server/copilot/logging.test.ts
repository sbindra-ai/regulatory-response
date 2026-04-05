import { afterEach, describe, expect, it, vi } from "vitest"

function createRunContext() {
  return {
    generatePlan: {
      fallbackReason: null,
      usedMga: false,
    },
    interpretRequest: {
      fallbackReason: null,
      usedMga: false,
    },
    runId: "run-123",
  }
}

function createInterpretation() {
  return {
    analysisType: "Overall summary",
    confidence: "high" as const,
    confidenceScore: {
      overall: 75,
      level: "high" as const,
      interpretationScore: 75,
      evidenceRelevanceScore: 0,
      evidenceCoverageScore: 0,
      reasons: ["Placeholder"],
    },
    datasetHints: ["ADAE", "ADSL"],
    endpoint: "Treatment-emergent adverse events",
    outputFamilyHints: ["ae-overall"],
    outputTypes: ["table"],
    population: "Safety analysis set",
    requestType: "ae-summary" as const,
    statisticalModel: "Mantel-Haenszel risk difference",
    summary: "Overall treatment-emergent adverse event summary request.",
    timepoints: ["Week 12"],
  }
}

function createEvidenceHit() {
  return {
    document: {
      datasetNames: ["ADAE", "ADSL"],
      id: "program:t_adae_iss_overall_week12",
      keywords: ["ae", "week12"],
      outputFamilies: ["ae-overall"],
      path: "docs/examples/programs/t_adae_iss_overall_week12.sas",
      sourceText: "proc report;",
      sourceType: "program" as const,
      summary: "Week 12 AE overall summary example.",
      title: "Week 12 AE Overall Summary",
      embedding: null,
    },
    matchedTerms: ["week 12", "adverse event"],
    retrievalReason: "Matched output family and dataset hints.",
    score: 0.92,
    vectorSimilarity: null,
    keywordScore: 0.92,
    hybridRank: 1,
  }
}

function createResponsePlan() {
  return {
    objective: "Create a grounded starter plan for a week 12 AE summary.",
    recommendedApproach: "Start from t_adae_iss_overall_week12 example.",
    recommendedDatasets: ["ADAE", "ADSL"],
    candidateOutputs: ["AE overall summary table"],
    deliverables: ["Internal response plan", "Draft table review"],
    citations: ["program:t_adae_iss_overall_week12"],
  }
}

describe("copilot logging", () => {
  afterEach(() => {
    vi.clearAllMocks()
    vi.restoreAllMocks()
    vi.resetModules()
    vi.unstubAllEnvs()
  })

  it("throws when MGA_TOKEN is missing instead of falling back", async () => {
    vi.spyOn(console, "info").mockImplementation(() => {})
    const question = "Provide an exposure-adjusted incidence rate summary through week 26 by system organ class and preferred term."
    const context = createRunContext()

    const { interpretRequest } = await import("@/lib/server/copilot/interpret-request")

    await expect(interpretRequest(question, context)).rejects.toThrow("MGA did not return a valid interpretation")
  })

  it("propagates MGA errors from generatePlan without falling back", async () => {
    vi.stubEnv("MGA_TOKEN", "test-token")

    vi.spyOn(console, "info").mockImplementation(() => {})
    vi.spyOn(console, "error").mockImplementation(() => {})
    const question = "Build a response plan for a week 12 overall treatment-emergent adverse event summary."
    const context = createRunContext()

    vi.doMock("@/lib/server/llm/openai", () => ({
      generateEmbeddings: vi.fn().mockResolvedValue(null),
      generateStructuredObject: vi.fn().mockRejectedValue(new Error("provider unavailable")),
    }))

    const { generatePlan } = await import("@/lib/server/copilot/generate-plan")

    await expect(
      generatePlan({
        context,
        evidence: [createEvidenceHit()],
        interpretation: createInterpretation(),
        question,
      }),
    ).rejects.toThrow("provider unavailable")
  })

  it("logs completed runs when MGA succeeds", async () => {
    vi.stubEnv("MGA_TOKEN", "test-token")

    const info = vi.spyOn(console, "info").mockImplementation(() => {})

    vi.doMock("@/lib/server/llm/openai", () => ({
      generateEmbeddings: vi.fn().mockResolvedValue(null),
      generateStructuredObject: vi
        .fn()
        .mockResolvedValueOnce({
          data: createInterpretation(),
          usage: { promptTokens: 500, completionTokens: 300, totalTokens: 800 },
        })
        .mockResolvedValueOnce({
          data: createResponsePlan(),
          usage: { promptTokens: 700, completionTokens: 350, totalTokens: 1050 },
        }),
    }))

    const { runCopilot } = await import("@/lib/server/copilot/run-copilot")

    const question =
      "What evidence supports a close liver observation follow-up request with subject-level plots and supporting datasets?"

    const result = await runCopilot(question)

    expect(result.interpretation).toBeDefined()
    expect(result.responsePlan).toBeDefined()
    expect(info).toHaveBeenCalledWith(
      expect.objectContaining({
        event: "copilot.run.started",
        questionLength: question.length,
        runId: expect.any(String),
      }),
    )
    expect(info).toHaveBeenCalledWith(
      expect.objectContaining({
        event: "copilot.run.completed",
        evidenceCount: result.evidence.length,
        runId: expect.any(String),
      }),
    )
  })

  it("logs rejected runs for the empty-question guard", async () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {})

    const { runCopilot } = await import("@/lib/server/copilot/run-copilot")

    await expect(runCopilot("   ")).rejects.toThrow("Enter a regulatory question to run the copilot.")

    expect(warn).toHaveBeenCalledWith(
      expect.objectContaining({
        event: "copilot.run.rejected",
        questionLength: 0,
        runId: expect.any(String),
      }),
    )
  })
})
