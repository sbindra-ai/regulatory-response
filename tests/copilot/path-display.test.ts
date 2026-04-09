import { describe, expect, it } from "vitest"

import {
  displayFullPathForNetworkAsset,
  fullPathForRankedCodeRow,
  isAbsolutePathDisplay,
  normalizeScanRootForUi,
} from "@/lib/copilot/path-display"
import type { EvidenceHit, RankedCodeAsset } from "@/lib/server/copilot/schemas"

describe("displayFullPathForNetworkAsset", () => {
  it("keeps absolute paths", () => {
    expect(displayFullPathForNetworkAsset("\\\\srv\\a\\b.sas", undefined, undefined)).toBe("\\\\srv\\a\\b.sas")
    expect(displayFullPathForNetworkAsset("X:/c/d.sas", undefined, undefined)).toBe("X:/c/d.sas")
  })

  it("joins relative path with network scan root from metadata", () => {
    const joined = displayFullPathForNetworkAsset(
      "pgms/t_adae.sas",
      "pgms/t_adae.sas",
      "\\\\by-swanPRD\\swan\\root\\bhc\\3427080",
    )
    expect(joined.replace(/\\/g, "/").toLowerCase()).toContain("by-swanprd/swan/root/bhc/3427080/pgms/t_adae.sas")
  })

  it("normalizes URL-style scan root pasted in env", () => {
    const joined = displayFullPathForNetworkAsset("pgms/x.sas", undefined, "//server/share/study")
    expect(joined.replace(/\\/g, "/").toLowerCase()).toContain("server/share/study/pgms/x.sas")
  })
})

describe("fullPathForRankedCodeRow", () => {
  it("prefers evidence document path when resolving", () => {
    const row: RankedCodeAsset = {
      assetType: "program",
      relevancePercent: 100,
      title: "x.sas",
      path: "pgms/x.sas",
      relativePath: "pgms/x.sas",
      documentId: "net:abc",
      callingProgramPaths: [],
    }
    const evidence: EvidenceHit[] = [
      {
        document: {
          id: "net:abc",
          title: "x.sas",
          sourceType: "network-file",
          path: "\\\\host\\share\\pgms\\x.sas",
          relativePath: "pgms/x.sas",
          summary: "",
          keywords: [],
          datasetNames: [],
          outputFamilies: [],
          sourceText: "data _null_;",
          embedding: null,
        },
        score: 100,
        matchedTerms: [],
        retrievalReason: "",
        vectorSimilarity: null,
        keywordScore: 0,
        hybridRank: 1,
      },
    ]
    expect(fullPathForRankedCodeRow(row, evidence, undefined)).toBe("\\\\host\\share\\pgms\\x.sas")
  })
})

describe("normalizeScanRootForUi", () => {
  it("strips wrapping quotes and normalizes //server/share", () => {
    expect(normalizeScanRootForUi('"//srv/share/study"')).toBe("\\\\srv\\share\\study")
  })
})

describe("isAbsolutePathDisplay", () => {
  it("treats repo-style relative paths as not absolute", () => {
    expect(isAbsolutePathDisplay("docs/a.sas")).toBe(false)
    expect(isAbsolutePathDisplay("pgms/a.sas")).toBe(false)
  })
})
