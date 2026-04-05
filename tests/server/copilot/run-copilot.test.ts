import { afterEach, describe, expect, it, vi } from "vitest"

describe("runCopilot", () => {
  afterEach(() => {
    vi.clearAllMocks()
    vi.restoreAllMocks()
    vi.resetModules()
    vi.unstubAllEnvs()
  })

  it("returns a grounded internal response plan for supported requests", async () => {
    vi.stubEnv("MGA_TOKEN", "test-token")
    vi.spyOn(console, "info").mockImplementation(() => {})

    vi.doMock("@/lib/server/llm/openai", () => ({
      generateEmbeddings: vi.fn().mockResolvedValue(null),
      generateStructuredObject: vi
        .fn()
        .mockResolvedValueOnce({
          data: {
            requestType: "liver-clo",
            summary: "Close liver observation follow-up request.",
            population: "Subject-level follow-up",
            endpoint: "Subject-level liver laboratory follow-up",
            timepoints: ["During treatment"],
            analysisType: "Close liver observation review",
            statisticalModel: null,
            outputTypes: ["figure", "dataset"],
            datasetHints: ["ADLB", "ADAE", "ADCM", "ADSL"],
            outputFamilyHints: ["liver-clo", "adlb-figure"],
            confidence: "medium",
            confidenceScore: {
              overall: 50,
              level: "medium",
              interpretationScore: 50,
              evidenceRelevanceScore: 0,
              evidenceCoverageScore: 0,
              reasons: ["Placeholder"],
            },
          },
          usage: { promptTokens: 500, completionTokens: 300, totalTokens: 800 },
        })
        .mockResolvedValueOnce({
          data: {
            objective: "Create a grounded starter plan for a liver follow-up request.",
            recommendedApproach: "Review subject-level ADLB plots and the CLO support dataset first.",
            recommendedDatasets: ["ADLB", "ADAE", "ADCM"],
            candidateOutputs: ["Subject-level ADLB figure", "Close liver observation support package"],
            deliverables: ["Internal response plan", "Draft figure review"],
            responsibilities: ["Lead programmer", "Statistician"],
            citations: ["program:f_10_2_8_2_adlb_over", "program:d_adlb_dili_tab"],
          },
          usage: { promptTokens: 800, completionTokens: 400, totalTokens: 1200 },
        }),
    }))

    const { runCopilot } = await import("@/lib/server/copilot/run-copilot")

    const result = await runCopilot(
      "What evidence supports a close liver observation follow-up request with subject-level plots and supporting datasets?",
    )

    expect(result.interpretation.requestType).toBe("liver-clo")
    expect(result.evidence.map((hit) => hit.document.id)).toContain("program:f_10_2_8_2_adlb_over")
    expect(result.responsePlan.citations).toEqual(
      expect.arrayContaining(["program:f_10_2_8_2_adlb_over", "program:d_adlb_dili_tab"]),
    )
    expect(result.responsePlan.recommendedDatasets).toEqual(expect.arrayContaining(["ADLB", "ADAE", "ADCM"]))
    expect(result.assumptions.length).toBeGreaterThan(0)
    expect(result.warnings.join(" ")).toContain("internal response plan")
  })

  it("throws when MGA is unavailable instead of falling back", async () => {
    vi.spyOn(console, "info").mockImplementation(() => {})
    vi.spyOn(console, "warn").mockImplementation(() => {})

    const { runCopilot } = await import("@/lib/server/copilot/run-copilot")

    await expect(
      runCopilot("Provide a survival tipping-point sensitivity analysis."),
    ).rejects.toThrow("MGA did not return a valid interpretation")
  })
})
