import type { RankedCodeAsset } from "@/lib/server/copilot/schemas"

/** Max rows in the response-plan “Most likely programs / macros” table. */
export const PLAN_RANKED_CODE_MAX = 20

/**
 * Keep rows within this many relevance points of the best hit (retrieval score 0–100).
 * Weaker matches are hidden so the list stays actionable; widened vs early builds so more “close” SAS rows appear.
 */
export const PLAN_RANKED_CODE_SCORE_SPREAD = 18

export function filterRankedCodeAssetsForPlan(rows: RankedCodeAsset[]): RankedCodeAsset[] {
  if (rows.length === 0) return []
  const sorted = [...rows].sort((a, b) => {
    if (b.relevancePercent !== a.relevancePercent) return b.relevancePercent - a.relevancePercent
    if (a.assetType !== b.assetType) return a.assetType.localeCompare(b.assetType)
    return `${a.path}\0${a.title}`.localeCompare(`${b.path}\0${b.title}`)
  })
  const top = sorted[0].relevancePercent
  let floor = Math.max(0, top - PLAN_RANKED_CODE_SCORE_SPREAD)
  let withinBand = sorted.filter((r) => r.relevancePercent >= floor)
  if (withinBand.length < 6 && sorted.length > withinBand.length) {
    const widerFloor = Math.max(0, top - PLAN_RANKED_CODE_SCORE_SPREAD * 2)
    const wider = sorted.filter((r) => r.relevancePercent >= widerFloor)
    if (wider.length > withinBand.length) withinBand = wider
  }
  if (withinBand.length < 4 && sorted.length > withinBand.length) {
    withinBand = sorted.slice(0, Math.min(PLAN_RANKED_CODE_MAX, Math.max(withinBand.length, 10)))
  }
  return withinBand.slice(0, PLAN_RANKED_CODE_MAX)
}
