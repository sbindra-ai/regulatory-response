import { describe, expect, it } from "vitest"

import {
  isAbsoluteStoragePath,
  joinScanRootToRelativePath,
  normalizeEvidenceHitsForNetworkShare,
} from "@/lib/server/copilot/network-path-resolve"
import type { EvidenceHit } from "@/lib/server/copilot/schemas"

describe("isAbsoluteStoragePath", () => {
  it("detects UNC and drive paths", () => {
    expect(isAbsoluteStoragePath("\\\\srv\\share\\a.sas")).toBe(true)
    expect(isAbsoluteStoragePath("X:/code/a.sas")).toBe(true)
    expect(isAbsoluteStoragePath("/opt/repo/a.sas")).toBe(true)
    expect(isAbsoluteStoragePath("pgms/a.sas")).toBe(false)
  })
})

describe("joinScanRootToRelativePath", () => {
  it("joins scan root with a relative path segment", () => {
    const joined = joinScanRootToRelativePath("\\\\by-swanPRD\\swan\\root", "pgms/start.sas")
    expect(joined.replace(/\\/g, "/").toLowerCase()).toContain("by-swanprd/swan/root/pgms/start.sas")
  })
})

describe("normalizeEvidenceHitsForNetworkShare", () => {
  it("rewrites relative document.path using scan root without mutating absolute paths", () => {
    const root = "\\\\server\\share\\study"
    const hits: EvidenceHit[] = [
      {
        document: {
          id: "a",
          title: "a",
          sourceType: "network-file",
          path: "pgms/x.sas",
          relativePath: "pgms/x.sas",
          summary: "",
          keywords: [],
          datasetNames: [],
          outputFamilies: [],
          sourceText: "%macro m;",
          embedding: null,
        },
        score: 100,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 1,
      },
      {
        document: {
          id: "b",
          title: "b",
          sourceType: "network-file",
          path: "\\\\server\\share\\study\\pgms\\y.sas",
          relativePath: "pgms/y.sas",
          summary: "",
          keywords: [],
          datasetNames: [],
          outputFamilies: [],
          sourceText: "data _null_;",
          embedding: null,
        },
        score: 90,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 2,
      },
    ]

    const out = normalizeEvidenceHitsForNetworkShare(hits, root)
    expect(out[0]!.document.path.replace(/\\/g, "/")).toBe("//server/share/study/pgms/x.sas")
    expect(out[1]!.document.path).toBe(hits[1]!.document.path)
  })
})
