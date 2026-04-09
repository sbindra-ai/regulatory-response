// @vitest-environment jsdom

import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { EvidencePanel } from "@/components/copilot/evidence-panel"
import { InterpretationPanel } from "@/components/copilot/interpretation-panel"
import { ResponsePlanPanel } from "@/components/copilot/response-plan-panel"

const interpretation = {
  requestType: "liver-clo" as const,
  summary: "Close liver observation follow-up request.",
  population: "Subject-level follow-up",
  endpoint: "Subject-level liver laboratory follow-up",
  timepoints: ["During treatment"],
  analysisType: "Close liver observation review",
  statisticalModel: null,
  outputTypes: ["figure", "dataset"],
  datasetHints: ["ADLB", "ADAE", "ADCM"],
  outputFamilyHints: ["liver-clo", "adlb-figure"],
  confidence: "medium" as const,
  confidenceScore: {
    overall: 68,
    level: "medium" as const,
    interpretationScore: 75,
    evidenceRelevanceScore: 87,
    evidenceCoverageScore: 42,
    reasons: [
      "Matched request type 'liver-clo' with high specificity",
      "Top evidence has 0.87 cosine similarity to query",
      "Found 2 of 3 expected datasets in evidence",
    ],
  },
}

const evidence = [
  {
    document: {
      id: "program:f_10_2_8_2_adlb_over",
      title: "LB test plot by subject",
      sourceType: "program" as const,
      path: "docs/examples/programs/f_10_2_8_2_adlb_over.sas",
      summary: "Subject-level liver plot with AE and CM overlays.",
      keywords: ["adlb", "liver", "plot"],
      datasetNames: ["ADLB", "ADAE", "ADCM"],
      outputFamilies: ["liver-clo", "adlb-figure"],
      sourceText: "Purpose: LB test plot by subject.",
      embedding: null,
    },
    score: 42,
    matchedTerms: ["liver", "subject-level"],
    retrievalReason: "Matches output family liver-clo. Grounded by datasets ADLB, ADAE, ADCM.",
    vectorSimilarity: 0.87,
    keywordScore: 15.3,
    hybridRank: 1,
  },
]

describe("copilot panels", () => {
  it("renders interpretation, evidence, and response-plan content", () => {
    render(
      <div>
        <InterpretationPanel interpretation={interpretation} pending={false} />
        <EvidencePanel evidence={evidence} pending={false} />
        <ResponsePlanPanel
          pending={false}
          result={{
            interpretation,
            evidence,
            responsePlan: {
              objective: "Create a grounded starter plan for a liver follow-up request.",
              recommendedApproach: "Review subject-level ADLB plots and the CLO support dataset first.",
              recommendedDatasets: ["ADLB", "ADAE", "ADCM"],
              candidateOutputs: ["Subject-level ADLB figure", "Close liver observation support package"],
              deliverables: ["Internal response plan", "Draft figure review"],
              responsibilities: [
                { role: "Statistician", tasks: ["Define analysis methodology"] },
                { role: "Data Scientist", tasks: ["Create exploratory charts"] },
              ],
              citations: ["program:f_10_2_8_2_adlb_over", "program:d_adlb_dili_tab"],
            },
            assumptions: [
              {
                title: "Closest available repo analogs",
                detail: "This plan is grounded in the closest matching repo examples.",
              },
            ],
            openQuestions: [
              {
                title: "Confirm target subjects",
                detail: "The exact subject cohort still needs confirmation.",
              },
            ],
            evidenceGaps: [
              {
                title: "No final response template",
                detail: "The repo supports planning, not final authority-facing text.",
              },
            ],
            warnings: ["This output is an internal response plan, not final authority-facing wording."],
            retrievalMetadata: {
              method: "hybrid" as const,
              documentCount: 1,
              topSimilarity: 0.87,
              evidencePool: "repository" as const,
            },
            tokenUsage: {
              promptTokens: 1200,
              completionTokens: 800,
              totalTokens: 2000,
            },
          }}
        />
      </div>,
    )

    expect(screen.getByText("Close liver observation review")).toBeInTheDocument()
    expect(screen.getByText("docs/examples/programs/f_10_2_8_2_adlb_over.sas")).toBeInTheDocument()
    expect(screen.getByText("Create a grounded starter plan for a liver follow-up request.")).toBeInTheDocument()
    expect(screen.getByText("This output is an internal response plan, not final authority-facing wording.")).toBeInTheDocument()
    expect(screen.getByText(/medium confidence \(68\/100\)/i)).toBeInTheDocument()
    expect(screen.getByText("87% semantic")).toBeInTheDocument()
  })
})
