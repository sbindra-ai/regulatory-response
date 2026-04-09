import { basename } from "node:path"

import { filterRankedCodeAssetsForPlan } from "@/lib/copilot/ranked-code-plan"
import type {
  EvidenceHit,
  RankedCodeAsset,
  RequestInterpretation,
  ResponsePlan,
} from "@/lib/server/copilot/schemas"

const MAX_CITATIONS = 60
/** Build at most this many SAS/macro rows before relevance filtering (keeps work bounded). */
const MAX_CODE_ROWS = 200

export { filterRankedCodeAssetsForPlan, PLAN_RANKED_CODE_MAX, PLAN_RANKED_CODE_SCORE_SPREAD } from "@/lib/copilot/ranked-code-plan"

function uniqueStrings(values: string[]): string[] {
  return [...new Set(values.filter(Boolean))]
}

export function macrosDefinedInSas(sourceText: string): string[] {
  const names: string[] = []
  const re = /%macro\s+(\w+)/gi
  let match: RegExpExecArray | null
  while ((match = re.exec(sourceText)) !== null) {
    names.push(match[1])
  }
  return [...new Set(names)]
}

function isSasCodePath(path: string): boolean {
  return /\.sas$/i.test(path)
}

function isSasEvidenceHit(hit: EvidenceHit): boolean {
  const { document } = hit
  if (document.sourceType === "program") return true
  if (document.sourceType === "network-file" && isSasCodePath(document.path)) return true
  return false
}

export function buildCandidateDatasetPaths(
  datasetNames: string[],
  evidence: EvidenceHit[],
): Array<{ dataset: string; path: string }> {
  const rows: Array<{ dataset: string; path: string }> = []
  const seen = new Set<string>()

  for (const raw of datasetNames) {
    const ds = raw.trim()
    if (!ds) continue
    const u = ds.toUpperCase()
    const paths = new Set<string>()

    for (const hit of evidence) {
      const pNorm = hit.document.path.replace(/\\/g, "/")
      if (!pNorm) continue
      const base = basename(pNorm).toUpperCase().replace(/\.[^.]+$/, "")
      const pu = pNorm.toUpperCase()
      if (pu.includes(u) || base === u || base.startsWith(`${u}.`) || pu.includes(`${u}.`)) {
        paths.add(hit.document.path)
      }
    }

    for (const path of [...paths].sort((a, b) => a.localeCompare(b))) {
      const key = `${u}::${path.replace(/\\/g, "/")}`
      if (seen.has(key)) continue
      seen.add(key)
      rows.push({ dataset: ds, path })
      if (rows.filter((r) => r.dataset === ds).length >= 12) break
    }
  }

  return rows
}

export function buildRankedCodeAssets(evidence: EvidenceHit[]): RankedCodeAsset[] {
  const sasHits = evidence.filter(isSasEvidenceHit).sort((a, b) => b.score - a.score)

  const rows: RankedCodeAsset[] = []

  for (const hit of sasHits) {
    if (rows.length >= MAX_CODE_ROWS) break
    const { document } = hit
    const macros = macrosDefinedInSas(document.sourceText)

    if (macros.length === 0) {
      rows.push({
        assetType: "program",
        relevancePercent: hit.score,
        title: document.title,
        path: document.path,
        relativePath: document.relativePath,
        documentId: document.id,
        callingProgramPaths: [],
      })
      continue
    }

    for (const macro of macros) {
      if (rows.length >= MAX_CODE_ROWS) break
      rows.push({
        assetType: "macro",
        relevancePercent: hit.score,
        title: `%${macro}`,
        path: document.path,
        relativePath: document.relativePath,
        documentId: `${document.id}::macro:${macro}`,
        callingProgramPaths: [],
      })
    }
  }

  return rows
}

export function mergeResponsePlanWithEvidence(
  base: ResponsePlan,
  evidence: EvidenceHit[],
  interpretation: RequestInterpretation,
): ResponsePlan {
  const evidenceIds = evidence.map((h) => h.document.id)
  const mergedCitations = uniqueStrings([...base.citations, ...evidenceIds]).slice(0, MAX_CITATIONS)

  const datasetNames = uniqueStrings([
    ...base.recommendedDatasets,
    ...interpretation.datasetHints,
  ])

  return {
    ...base,
    citations: mergedCitations,
    candidateDatasetPaths: buildCandidateDatasetPaths(datasetNames, evidence),
    rankedCodeAssets: filterRankedCodeAssetsForPlan(buildRankedCodeAssets(evidence)),
  }
}
