import { describe, expect, it } from "vitest"

import { filterRankedCodeAssetsForPlan } from "@/lib/copilot/ranked-code-plan"
import {
  buildCandidateDatasetPaths,
  buildRankedCodeAssets,
  macrosDefinedInSas,
  mergeResponsePlanWithEvidence,
} from "@/lib/server/copilot/enrich-response-plan"
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
  it("applies plan filter so merged assets are capped and can include nearby scores when few strong hits exist", () => {
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
    expect(filtered[0].relevancePercent).toBe(100)
    expect(filtered.length).toBeGreaterThan(1)
  })
})

describe("buildCandidateDatasetPaths", () => {
  it("links datasets to Define-XML metadata paths via document.datasetNames", () => {
    const datasetDoc: EvidenceHit["document"] = {
      id: "dataset:ADSL",
      title: "ADSL dataset metadata",
      sourceType: "dataset",
      path: "docs/examples/define.xml",
      summary: "ADSL metadata from Define-XML.",
      keywords: ["adsl"],
      datasetNames: ["ADSL"],
      outputFamilies: [],
      sourceText: "ADSL",
      embedding: null,
    }
    const hits: EvidenceHit[] = [
      {
        document: datasetDoc,
        score: 90,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 1,
      },
    ]
    const rows = buildCandidateDatasetPaths(["ADSL"], hits)
    expect(rows.some((r) => r.dataset === "ADSL" && r.path.endsWith("define.xml"))).toBe(true)
  })

  it("lists only derivation SAS (d_* / d-*) plus transports and define.xml — not t_/f_ programs", () => {
    const mk = (id: string, path: string, datasetNames: string[]): EvidenceHit => ({
      document: {
        id,
        title: id,
        sourceType: "program",
        path,
        summary: "Summary text here.",
        keywords: [],
        datasetNames,
        outputFamilies: [],
        sourceText: "data _null_; run;",
        embedding: null,
      },
      score: 80,
      matchedTerms: [],
      retrievalReason: "test",
      vectorSimilarity: null,
      keywordScore: 0,
      hybridRank: 1,
    })
    const hits: EvidenceHit[] = [
      mk("t1", "repo/t_adae_week12.sas", ["ADSL"]),
      mk("d1", "repo/d_adsl.sas", ["ADSL"]),
      mk("f1", "repo/f_10_2_8_2_adlb_inr.sas", ["ADSL"]),
      mk("x1", "study/adsl.xpt", ["ADSL"]),
    ]
    const rows = buildCandidateDatasetPaths(["ADSL"], hits)
    expect(rows.map((r) => r.path)).toContain("repo/d_adsl.sas")
    expect(rows.map((r) => r.path)).toContain("study/adsl.xpt")
    expect(rows.some((r) => r.path.includes("t_adae"))).toBe(false)
    expect(rows.some((r) => r.path.includes("f_10"))).toBe(false)
  })

  it("replaces sibling derivation jobs (d_adlb_*) with canonical docs/examples/programs/d_adlb.sas", () => {
    const hits: EvidenceHit[] = [
      {
        document: {
          id: "dili",
          title: "dili",
          sourceType: "program",
          path: "repo/d_adlb_dili_tab.sas",
          summary: "",
          keywords: [],
          datasetNames: ["ADLB"],
          outputFamilies: [],
          sourceText: "data adlb;",
          embedding: null,
        },
        score: 80,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 1,
      },
    ]
    const rows = buildCandidateDatasetPaths(["ADLB"], hits)
    expect(rows.map((r) => r.path)).toContain("docs/examples/programs/d_adlb.sas")
    expect(rows.some((r) => r.path.includes("dili_tab"))).toBe(false)
  })

  it("backfills canonical derivation path for each recommended dataset when evidence has no derivation SAS", () => {
    const hits: EvidenceHit[] = []
    const rows = buildCandidateDatasetPaths(["ADSL", "ADLB", "ADAE"], hits)
    const paths = rows.map((r) => r.path)
    expect(paths).toContain("docs/examples/programs/d_adsl.sas")
    expect(paths).toContain("docs/examples/programs/d_adlb.sas")
    expect(paths).toContain("docs/examples/programs/d_adae.sas")
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
