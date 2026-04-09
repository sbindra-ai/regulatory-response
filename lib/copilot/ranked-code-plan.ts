import type { RankedCodeAsset } from "@/lib/server/copilot/schemas"

/** Max rows in the response-plan “Most likely programs / macros” table. */
export const PLAN_RANKED_CODE_MAX = 20

/**
 * Keep rows within this many relevance points of the best hit (retrieval score 0–100).
 * Weaker matches are hidden so the list stays actionable.
 */
export const PLAN_RANKED_CODE_SCORE_SPREAD = 12

export function filterRankedCodeAssetsForPlan(rows: RankedCodeAsset[]): RankedCodeAsset[] {
  if (rows.length === 0) return []
  const sorted = [...rows].sort((a, b) => {
    if (b.relevancePercent !== a.relevancePercent) return b.relevancePercent - a.relevancePercent
    if (a.assetType !== b.assetType) return a.assetType.localeCompare(b.assetType)
    return `${a.path}\0${a.title}`.localeCompare(`${b.path}\0${b.title}`)
  })
  const top = sorted[0].relevancePercent
  const floor = Math.max(0, top - PLAN_RANKED_CODE_SCORE_SPREAD)
  const withinBand = sorted.filter((r) => r.relevancePercent >= floor)
  return withinBand.slice(0, PLAN_RANKED_CODE_MAX)
}
