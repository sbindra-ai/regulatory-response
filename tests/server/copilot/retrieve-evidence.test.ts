import { describe, expect, it } from "vitest"

import { retrieveEvidence } from "@/lib/server/copilot/retrieve-evidence"
import type { RequestInterpretation } from "@/lib/server/copilot/schemas"

function makeInterpretation(overrides: Partial<RequestInterpretation>): RequestInterpretation {
  return {
    requestType: "unknown",
    summary: "",
    population: "Not explicitly stated",
    endpoint: "Unknown",
    timepoints: ["Not explicitly stated"],
    analysisType: "Needs clarification",
    statisticalModel: null,
    outputTypes: ["plan"],
    datasetHints: [],
    outputFamilyHints: [],
    confidence: "low",
    confidenceScore: {
      overall: 25,
      level: "low",
      interpretationScore: 25,
      evidenceRelevanceScore: 0,
      evidenceCoverageScore: 0,
      reasons: ["Placeholder"],
    },
    ...overrides,
  }
}

describe("retrieveEvidence", () => {
  it("surfaces the AE overall program for a week 12 AE summary interpretation", async () => {
    const { evidence } = await retrieveEvidence({
      interpretation: makeInterpretation({
        requestType: "ae-summary",
        summary: "Overall treatment-emergent adverse event summary request.",
        endpoint: "Treatment-emergent adverse events",
        timepoints: ["Week 12"],
        analysisType: "Overall summary",
        outputTypes: ["table"],
        datasetHints: ["ADAE", "ADSL"],
        outputFamilyHints: ["ae-overall"],
        confidence: "high",
      }),
      limit: 3,
      question:
        "Build a response plan for a week 12 overall treatment-emergent adverse event summary in the safety analysis set.",
    })

    expect(evidence[0]?.document.id).toBe("program:t_adae_iss_overall_week12")
  })

  it("surfaces AESI programs for an AESI interpretation", async () => {
    const { evidence } = await retrieveEvidence({
      interpretation: makeInterpretation({
        requestType: "aesi",
        summary: "Adverse events of special interest request.",
        endpoint: "Adverse events of special interest",
        timepoints: ["Week 12"],
        analysisType: "AESI incidence summary",
        outputTypes: ["table"],
        datasetHints: ["ADAE", "ADSL"],
        outputFamilyHints: ["aesi", "soc-pt"],
        confidence: "high",
      }),
      limit: 3,
      question:
        "Find prior evidence for treatment-emergent adverse events of special interest focused on somnolence or fatigue up to week 12.",
    })

    expect(evidence.map((hit) => hit.document.id)).toContain("program:t_adae_iss_soc_pt_aesi2_week12")
  })

  it("surfaces liver/CLO programs for a liver follow-up interpretation", async () => {
    const { evidence } = await retrieveEvidence({
      interpretation: makeInterpretation({
        requestType: "liver-clo",
        summary: "Close liver observation follow-up request.",
        endpoint: "Subject-level liver laboratory follow-up",
        timepoints: ["During treatment"],
        analysisType: "Close liver observation review",
        outputTypes: ["figure", "dataset"],
        datasetHints: ["ADLB", "ADAE", "ADCM", "ADSL"],
        outputFamilyHints: ["liver-clo", "adlb-figure"],
        confidence: "medium",
      }),
      limit: 5,
      question:
        "What evidence supports a close liver observation follow-up request with subject-level plots and supporting datasets?",
    })

    expect(evidence.map((hit) => hit.document.id)).toContain("program:f_10_2_8_2_adlb_over")
  })

  it("surfaces the BMD box plot program for a BMD interpretation", async () => {
    const { evidence } = await retrieveEvidence({
      interpretation: makeInterpretation({
        requestType: "bmd-figure",
        summary: "Bone mineral density figure request.",
        endpoint: "Percent change in bone mineral density from baseline",
        timepoints: ["Week 24", "Week 52"],
        analysisType: "Subgroup figure",
        outputTypes: ["figure"],
        datasetHints: ["ADMK", "ADSL"],
        outputFamilyHints: ["bmd-figure"],
        confidence: "high",
      }),
      limit: 3,
      question:
        "Draft a starter plan for a box plot of percent change in bone mineral density by race at weeks 24 and 52.",
    })

    expect(evidence.map((hit) => hit.document.id)).toContain("program:f_8_3_8_bmd_box")
  })
})
