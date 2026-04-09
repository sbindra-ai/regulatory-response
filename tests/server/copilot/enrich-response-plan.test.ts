import { describe, expect, it } from "vitest"

import { filterRankedCodeAssetsForPlan } from "@/lib/copilot/ranked-code-plan"
import { buildRankedCodeAssets, macrosDefinedInSas, mergeResponsePlanWithEvidence } from "@/lib/server/copilot/enrich-response-plan"
import type { EvidenceHit, RequestInterpretation, ResponsePlan } from "@/lib/server/copilot/schemas"

function doc(
  id: string,
  path: string,
  sourceText: string,
  sourceType: "program" | "network-file" = "program",
): EvidenceHit["document"] {
  return {
    id,
    title: id,
    sourceType,
    path,
    summary: "",
    keywords: [],
    datasetNames: [],
    outputFamilies: [],
    sourceText,
    embedding: null,
  }
}

describe("macrosDefinedInSas", () => {
  it("collects macro names", () => {
    expect(macrosDefinedInSas(`%macro foo;\n%mend;\n%macro BAR ;\n%mend;`)).toEqual(["foo", "BAR"])
  })
})

describe("buildRankedCodeAssets", () => {
  it("adds one row per macro (callers column removed; paths stay on the defining file)", () => {
    const hits: EvidenceHit[] = [
      {
        document: doc("p1", "X:/a/km.sas", "%macro km_plot;\n%mend;\n", "network-file"),
        score: 100,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 1,
      },
      {
        document: doc("p2", "X:/b/caller.sas", "%km_plot(x=1);\n", "network-file"),
        score: 80,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 2,
      },
    ]

    const rows = buildRankedCodeAssets(hits)
    const macroRow = rows.find((r) => r.assetType === "macro" && r.title === "%km_plot")
    expect(macroRow).toBeDefined()
    expect(macroRow!.callingProgramPaths).toEqual([])
  })

  it("emits a program row when no macros are defined", () => {
    const hits: EvidenceHit[] = [
      {
        document: doc("p1", "X:/a/nomacro.sas", "data _null_; run;", "program"),
        score: 90,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 1,
      },
    ]
    expect(buildRankedCodeAssets(hits)).toEqual([
      expect.objectContaining({ assetType: "program", path: "X:/a/nomacro.sas", relevancePercent: 90 }),
    ])
  })
})

describe("mergeResponsePlanWithEvidence rankedCodeAssets", () => {
  it("applies plan filter so merged assets are capped and relevance-trimmed", () => {
    const built = buildRankedCodeAssets(
      Array.from({ length: 30 }, (_, i) => ({
        document: doc(`p${i}`, `X:/x${i}.sas`, "data _null_;", "program"),
        score: i === 0 ? 100 : 50,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: i + 1,
      })),
    )
    const filtered = filterRankedCodeAssetsForPlan(built)
    expect(filtered.length).toBeLessThanOrEqual(built.length)
    expect(filtered.every((r) => r.relevancePercent >= 88)).toBe(true)
  })
})

describe("mergeResponsePlanWithEvidence", () => {
  const interpretation: RequestInterpretation = {
    requestType: "km-survival",
    summary: "",
    population: "",
    endpoint: "",
    timepoints: [],
    analysisType: "",
    statisticalModel: null,
    outputTypes: [],
    datasetHints: ["ADSL"],
    outputFamilyHints: [],
    confidence: "medium",
    confidenceScore: {
      overall: 50,
      level: "medium",
      interpretationScore: 0,
      evidenceRelevanceScore: 0,
      evidenceCoverageScore: 0,
      reasons: [],
    },
  }

  const base: ResponsePlan = {
    objective: "o",
    recommendedApproach: "a",
    recommendedDatasets: ["ADSL"],
    candidateOutputs: [],
    deliverables: [],
    responsibilities: [],
    citations: ["brief:1"],
  }

  it("merges dataset path rows and ranked code from evidence", () => {
    const evidence: EvidenceHit[] = [
      {
        document: doc(
          "nf:1",
          "X:/study/adsl.sas7bdat",
          "",
          "network-file",
        ),
        score: 100,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 1,
      },
      {
        document: doc("prog:1", "X:/code/a.sas", "data x;", "program"),
        score: 95,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 2,
      },
    ]

    const merged = mergeResponsePlanWithEvidence(base, evidence, interpretation)
    expect(merged.candidateDatasetPaths.some((r) => r.path.includes("adsl.sas7bdat"))).toBe(true)
    expect(merged.rankedCodeAssets.some((r) => r.path === "X:/code/a.sas")).toBe(true)
    expect(merged.citations).toContain("nf:1")
  })
})
