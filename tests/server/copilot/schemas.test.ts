import { describe, expect, it } from "vitest"

import {
  copilotResultSchema,
  evidenceDocumentSchema,
  requestInterpretationSchema,
} from "@/lib/server/copilot/schemas"

describe("requestInterpretationSchema", () => {
  it("parses a structured interpretation for a supported request", () => {
    const parsed = requestInterpretationSchema.parse({
      requestType: "ae-summary",
      summary: "Summarize treatment-emergent adverse events up to week 12.",
      population: "Safety analysis set",
      endpoint: "Treatment-emergent adverse events",
      timepoints: ["Week 12"],
      analysisType: "Overall summary",
      statisticalModel: "Mantel-Haenszel risk difference",
      outputTypes: ["table"],
      datasetHints: ["ADAE", "ADSL"],
      outputFamilyHints: ["ae-overall"],
      confidence: "high",
      confidenceScore: {
        overall: 75,
        level: "high",
        interpretationScore: 100,
        evidenceRelevanceScore: 0,
        evidenceCoverageScore: 0,
        reasons: ["Placeholder"],
      },
    })

    expect(parsed.datasetHints).toEqual(["ADAE", "ADSL"])
    expect(parsed.outputFamilyHints).toEqual(["ae-overall"])
  })
})

describe("evidenceDocumentSchema", () => {
  it("captures repo-grounded evidence metadata", () => {
    const parsed = evidenceDocumentSchema.parse({
      id: "program:t_adae_iss_overall_week12",
      title: "Week 12 overall AE summary",
      sourceType: "program",
      path: "docs/examples/programs/t_adae_iss_overall_week12.sas",
      summary: "Treatment-emergent AE overall summary through week 12.",
      keywords: ["AE", "week 12", "summary"],
      datasetNames: ["ADAE", "ADSL"],
      outputFamilies: ["ae-overall"],
      sourceText:
        "Purpose: Treatment-emergent adverse events up to week 12: overall summary of number of subjects by integrated analysis treatment group.",
    })

    expect(parsed.sourceType).toBe("program")
    expect(parsed.outputFamilies).toContain("ae-overall")
  })
})

describe("copilotResultSchema", () => {
  it("requires explicit uncertainty buckets in the result", () => {
    const parsed = copilotResultSchema.parse({
      interpretation: {
        requestType: "liver-clo",
        summary: "Investigate liver close observation evidence.",
        population: "Safety analysis set",
        endpoint: "Liver laboratory follow-up",
        timepoints: ["During treatment"],
        analysisType: "Subject-level follow-up",
        statisticalModel: null,
        outputTypes: ["figure", "dataset"],
        datasetHints: ["ADLB", "ADCM", "ADAE"],
        outputFamilyHints: ["liver-clo"],
        confidence: "medium",
        confidenceScore: {
          overall: 60,
          level: "medium",
          interpretationScore: 75,
          evidenceRelevanceScore: 85,
          evidenceCoverageScore: 20,
          reasons: ["Matched request type 'liver-clo'"],
        },
      },
      evidence: [
        {
          document: {
            id: "program:f_10_2_8_2_adlb_over",
            title: "Lab test plot by subject",
            sourceType: "program",
            path: "docs/examples/programs/f_10_2_8_2_adlb_over.sas",
            summary: "Subject-level ALT/AST/TBIL/AP plots with AE and CM overlays.",
            keywords: ["ADLB", "liver", "plot"],
            datasetNames: ["ADLB", "ADAE", "ADCM"],
            outputFamilies: ["liver-clo"],
            sourceText: "Purpose: LB test plot by subject.",
            embedding: null,
          },
          score: 0.95,
          matchedTerms: ["liver", "subject-level"],
          retrievalReason: "Uses ADLB with AE and CM overlays for CLO-oriented liver follow-up.",
          vectorSimilarity: 0.85,
          keywordScore: 12.5,
          hybridRank: 1,
        },
      ],
      responsePlan: {
        objective: "Assemble a grounded starter plan for a liver follow-up request.",
        recommendedApproach:
          "Review subject-level ADLB liver plots and CLO-supporting derived datasets before drafting deliverables.",
        recommendedDatasets: ["ADLB", "ADAE", "ADCM"],
        candidateOutputs: ["Subject-level liver plot", "Derived CLO narrative-support dataset"],
        deliverables: ["Internal response plan", "Evidence-backed next steps"],
        citations: ["program:f_10_2_8_2_adlb_over"],
      },
      assumptions: [
        {
          title: "Close liver observation is in scope",
          detail: "The request appears to concern CLO-style follow-up based on ADLB-oriented evidence.",
        },
      ],
      openQuestions: [
        {
          title: "Confirm triggering subjects",
          detail: "The source evidence shows CLO-oriented outputs but does not identify the exact request cohort.",
        },
      ],
      evidenceGaps: [
        {
          title: "No final narrative template in repo",
          detail: "The examples support planning and evidence reuse, not final authority-facing response language.",
        },
      ],
      warnings: ["Plan is grounded in repo examples and may need study-specific confirmation."],
      retrievalMetadata: {
        method: "hybrid",
        documentCount: 1,
        topSimilarity: 0.85,
      },
      tokenUsage: {
        promptTokens: 1500,
        completionTokens: 900,
        totalTokens: 2400,
      },
    })

    expect(parsed.assumptions).toHaveLength(1)
    expect(parsed.openQuestions).toHaveLength(1)
    expect(parsed.evidenceGaps).toHaveLength(1)
  })
})
