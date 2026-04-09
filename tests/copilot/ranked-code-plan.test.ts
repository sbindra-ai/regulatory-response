import { describe, expect, it } from "vitest"

import {
  filterRankedCodeAssetsForPlan,
  PLAN_RANKED_CODE_MAX,
  PLAN_RANKED_CODE_SCORE_SPREAD,
} from "@/lib/copilot/ranked-code-plan"
import type { RankedCodeAsset } from "@/lib/server/copilot/schemas"

function row(
  path: string,
  relevancePercent: number,
  assetType: RankedCodeAsset["assetType"] = "program",
  title = "t",
): RankedCodeAsset {
  return {
    assetType,
    relevancePercent,
    title,
    path,
    documentId: `id:${path}`,
    callingProgramPaths: [],
  }
}

describe("filterRankedCodeAssetsForPlan", () => {
  it("caps at PLAN_RANKED_CODE_MAX when many ties at top score", () => {
    const rows = Array.from({ length: 40 }, (_, i) => row(`/p${i}.sas`, 100))
    const out = filterRankedCodeAssetsForPlan(rows)
    expect(out).toHaveLength(PLAN_RANKED_CODE_MAX)
  })

  it("drops rows more than PLAN_RANKED_CODE_SCORE_SPREAD below the top", () => {
    const rows = [
      row("/a.sas", 100),
      row("/b.sas", 95),
      row("/c.sas", 87), // 100 - 13 → excluded when spread is 12
      row("/d.sas", 88),
    ]
    const out = filterRankedCodeAssetsForPlan(rows)
    expect(out.map((r) => r.path)).toEqual(["/a.sas", "/b.sas", "/d.sas"])
  })
})
