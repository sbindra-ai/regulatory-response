"use client"

import { useMemo, useState, type ReactNode } from "react"

import { fileNameFromPath, fullPathForRankedCodeRow } from "@/lib/copilot/path-display"
import { PLAN_RANKED_CODE_MAX, PLAN_RANKED_CODE_SCORE_SPREAD } from "@/lib/copilot/ranked-code-plan"
import type { CopilotResult, EvidenceHit, RequestInterpretation } from "@/lib/server/copilot/schemas"
import { Badge } from "@/components/ui/badge"
import { FormattedText } from "@/components/copilot/formatted-text"
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible"
import { Separator } from "@/components/ui/separator"
import { HelpIcon } from "@/components/copilot/verbose-context"
import { Button } from "@/components/ui/button"

type ResponsePlanPanelProps = {
  pending: boolean
  result: CopilotResult | null
}

function SectionHeading({ tooltip, children }: { tooltip: string; children: ReactNode }) {
  return (
    <h3 className="text-[0.6875rem] font-semibold uppercase tracking-wider text-muted-foreground">
      {children}
      <HelpIcon tooltip={tooltip} />
    </h3>
  )
}

function UncertaintyBlock({
  items,
  variant = "default",
}: {
  items: Array<{ detail: string; title: string }>
  variant?: "default" | "warning"
}) {
  if (items.length === 0) return null
  const isWarning = variant === "warning"
  return (
    <div className="space-y-2.5">
      {items.map((item) => (
        <div
          key={item.title}
          className={
            isWarning
              ? "rounded-md border border-destructive/15 bg-destructive/[0.03] px-4 py-3"
              : "rounded-md border border-border bg-muted/50 px-4 py-3"
          }
        >
          <p className={`text-sm font-semibold ${isWarning ? "text-destructive" : "text-foreground"}`}>
            {item.title}
          </p>
          <div className="mt-0.5 text-sm leading-relaxed text-muted-foreground">
            <FormattedText text={item.detail} />
          </div>
        </div>
      ))}
    </div>
  )
}

type AnalysisDatasetRow = {
  dataset: string
  path: string | null
  hasTransport: boolean
}

/** ADaM-style datasets from this run: transport filenames, dataset tags on hits, then interpretation hints. */
function buildAnalysisDatasetRows(
  evidence: EvidenceHit[],
  interpretation: Pick<RequestInterpretation, "datasetHints">,
): AnalysisDatasetRow[] {
  const byDs = new Map<string, AnalysisDatasetRow>()

  for (const hit of evidence) {
    const p = hit.document.path.replace(/\\/g, "/")
    const isTransport = /\.(sas7bdat|xpt)$/i.test(p)

    if (isTransport) {
      const fn = fileNameFromPath(p)
      const ds = fn.replace(/\.[^.]+$/i, "").toUpperCase()
      if (!ds) continue
      const cur = byDs.get(ds)
      if (!cur) {
        byDs.set(ds, { dataset: ds, path: hit.document.path, hasTransport: true })
      } else {
        cur.path = hit.document.path
        cur.hasTransport = true
      }
    }

    for (const raw of hit.document.datasetNames) {
      const ds = raw.trim().toUpperCase()
      if (!ds) continue
      const cur = byDs.get(ds)
      if (!cur) {
        byDs.set(ds, {
          dataset: ds,
          path: hit.document.path,
          hasTransport: isTransport,
        })
      } else {
        if (isTransport) {
          cur.path = hit.document.path
          cur.hasTransport = true
        } else if (!cur.path) {
          cur.path = hit.document.path
        }
      }
    }
  }

  if (byDs.size === 0) {
    for (const raw of interpretation.datasetHints) {
      const ds = raw.trim().toUpperCase()
      if (!ds) continue
      byDs.set(ds, { dataset: ds, path: null, hasTransport: false })
    }
  }

  return [...byDs.values()].sort((a, b) => a.dataset.localeCompare(b.dataset))
}

function pathBuckets(evidence: EvidenceHit[]) {
  const sas: string[] = []
  const seenS = new Set<string>()
  for (const hit of evidence) {
    const p = hit.document.path.replace(/\\/g, "/")
    if (/\.sas$/i.test(p) && !seenS.has(p)) {
      seenS.add(p)
      sas.push(p)
    }
  }
  return {
    sas: sas.sort(),
  }
}

function resolveDocIdForAsset(assetDocumentId: string): string {
  return assetDocumentId.split("::macro:")[0] ?? assetDocumentId
}

function findSourceText(assetDocumentId: string, evidence: EvidenceHit[]): string | null {
  const baseId = resolveDocIdForAsset(assetDocumentId)
  const hit = evidence.find((h) => h.document.id === baseId)
  return hit?.document.sourceText ?? null
}

export function ResponsePlanPanel({ pending, result }: ResponsePlanPanelProps) {
  const [openCodeId, setOpenCodeId] = useState<string | null>(null)

  const buckets = useMemo(() => (result ? pathBuckets(result.evidence) : { sas: [] }), [result])
  const analysisDatasetRows = useMemo(
    () => (result ? buildAnalysisDatasetRows(result.evidence, result.interpretation) : []),
    [result],
  )

  if (pending) {
    return (
      <div className="space-y-4 animate-in">
        <div className="pipeline-progress" />
        <div className="skeleton-stagger space-y-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="skeleton-block space-y-2 p-4">
              <div className="h-3 w-1/4 rounded bg-border/60" />
              <div className="h-3 w-full rounded bg-border/40" />
              <div className="h-3 w-4/5 rounded bg-border/40" />
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (!result) {
    return (
      <div className="py-12 text-center">
        <p className="text-sm text-muted-foreground">
          The response plan turns evidence into a traceable internal starter plan.
          Run the copilot to generate one.
        </p>
      </div>
    )
  }

  const { responsePlan, evidence, retrievalMetadata } = result
  const candidateDatasetPaths = responsePlan.candidateDatasetPaths ?? []
  const rankedCodeAssets = responsePlan.rankedCodeAssets ?? []

  const pathsByDataset = new Map<string, string[]>()
  for (const row of candidateDatasetPaths) {
    const list = pathsByDataset.get(row.dataset) ?? []
    if (!list.includes(row.path)) list.push(row.path)
    pathsByDataset.set(row.dataset, list)
  }

  return (
    <div className="stagger-children space-y-6">
      {/* Evidence base — same run as plan (always visible so empty retrieval is obvious) */}
      <div className="rounded-xl border border-[#10384F]/15 bg-gradient-to-br from-[#10384F]/[0.04] to-white px-5 py-4 shadow-sm">
        <div className="flex items-center justify-between gap-2">
          <SectionHeading tooltip="Counts and paths from the evidence retrieved for this question (same list as the Evidence tab). If this shows zero hits, switch pool, re-run ingest, or narrow your question.">
            Evidence base (this run)
          </SectionHeading>
          <Badge variant="outline" className="shrink-0 text-[0.625rem]">
            {retrievalMetadata.evidencePool === "network" ? "Network index" : "Repository"}
          </Badge>
        </div>
        <p className="mt-1 text-[0.8125rem] text-muted-foreground">
          Open the <span className="font-semibold text-foreground">Evidence</span> tab for full text, scores, and
          reasons. Below is a compact path index from the same hits.
        </p>
        {evidence.length === 0 ? (
          <p className="mt-4 rounded-lg border border-dashed border-border/80 bg-muted/20 px-4 py-3 text-[0.8125rem] leading-relaxed text-muted-foreground">
            No evidence documents were retrieved for this question. Try the other evidence pool (repository vs network
            share), run corpus ingest so paths exist in the index, or add more specific analysis and dataset terms.
          </p>
        ) : (
          <div className="mt-4 grid gap-4 lg:grid-cols-3">
            <div className="rounded-lg border border-border/70 bg-card p-3">
              <p className="text-[0.6875rem] font-semibold uppercase tracking-wide text-muted-foreground">
                Total evidence hits
              </p>
              <p className="mt-1 text-2xl font-bold tabular-nums text-[#10384F]">{evidence.length}</p>
            </div>
            <div className="rounded-lg border border-border/70 bg-card p-3">
              <p className="text-[0.6875rem] font-semibold uppercase tracking-wide text-muted-foreground">
                Analysis datasets
                <HelpIcon tooltip="Lists ADaM-style datasets for this run: (1) names from .sas7bdat/.xpt paths in hits, (2) dataset tags on retrieved documents (programs, Define-XML slices, PDF chunks), and (3) if still empty, dataset hints from interpretation. The demo corpus often has no transport binaries — tags still show ADSL, ADAE, etc." />
              </p>
              <p className="mt-1 text-2xl font-bold tabular-nums text-[#10384F]">{analysisDatasetRows.length}</p>
              <div className="mt-2 max-h-36 space-y-2 overflow-auto rounded border border-border/40 bg-muted/30 p-2 text-[0.65rem] leading-snug">
                {analysisDatasetRows.length === 0 ? (
                  <span className="text-muted-foreground/70">No datasets inferred for this run.</span>
                ) : (
                  analysisDatasetRows.slice(0, 80).map((row) => (
                    <div key={row.dataset} className="border-b border-border/25 pb-2 last:border-0 last:pb-0">
                      <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
                        <span className="font-semibold text-foreground">{row.dataset}</span>
                        {row.hasTransport ? (
                          <span className="text-[0.6rem] font-medium uppercase tracking-wide text-emerald-700/90">
                            transport
                          </span>
                        ) : null}
                      </div>
                      {row.path ? (
                        <div className="font-mono text-muted-foreground break-all">{row.path}</div>
                      ) : (
                        <div className="text-muted-foreground/80">From interpreted question — ingest or retrieve evidence that tags this dataset.</div>
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>
            <div className="rounded-lg border border-border/70 bg-card p-3">
              <p className="text-[0.6875rem] font-semibold uppercase tracking-wide text-muted-foreground">
                SAS programs (in hits)
              </p>
              <p className="mt-1 text-2xl font-bold tabular-nums text-[#10384F]">{buckets.sas.length}</p>
              <div className="mt-2 max-h-36 space-y-2 overflow-auto rounded border border-border/40 bg-muted/30 p-2 text-[0.65rem] leading-snug">
                {buckets.sas.length === 0 ? (
                  <span className="text-muted-foreground/70">None in hits</span>
                ) : (
                  buckets.sas.slice(0, 80).map((p) => (
                    <div key={p} className="border-b border-border/25 pb-2 last:border-0 last:pb-0">
                      <span className="font-medium text-foreground">{fileNameFromPath(p)}</span>
                      <div className="font-mono text-muted-foreground break-all">{p}</div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Objective + approach */}
      <div>
        <SectionHeading tooltip="The recommended approach outlines the overall objective and strategy the copilot suggests for addressing your regulatory question, based on matched evidence and known output patterns.">
          Recommended approach
        </SectionHeading>
        <p className="mt-2 text-base font-semibold leading-snug text-foreground">
          {responsePlan.objective}
        </p>
        <div className="mt-2 text-[0.9375rem] leading-relaxed text-foreground/85">
          <FormattedText text={responsePlan.recommendedApproach} />
        </div>
      </div>

      {/* Deliverables */}
      {responsePlan.deliverables.length > 0 && (
        <div>
          <SectionHeading tooltip="Deliverables are the specific outputs the copilot recommends producing - e.g. tables, figures, or listings. Each is derived from matched SAS programs and dataset structures in the evidence corpus.">
            Deliverables
          </SectionHeading>
          <ol className="mt-2 space-y-1.5 pl-5">
            {responsePlan.deliverables.map((item, i) => (
              <li key={item} className="text-[0.9375rem] leading-relaxed text-foreground/85">
                <span className="mr-2 inline-flex h-5 w-5 items-center justify-center rounded-full bg-primary/10 text-[0.625rem] font-bold text-primary">
                  {i + 1}
                </span>
                {item}
              </li>
            ))}
          </ol>
        </div>
      )}

      {/* Responsibilities */}
      {responsePlan.responsibilities.length > 0 && (
        <>
          <Separator />
          <div>
            <SectionHeading tooltip="Responsibilities assign specific tasks to team roles - e.g. Statistician, SAS Programmer, Data Scientist - so each member knows what to deliver for this plan.">
              Responsibilities
            </SectionHeading>
            <div className="mt-2 space-y-3">
              {responsePlan.responsibilities.map((r) => (
                <div key={r.role} className="rounded-md border border-border bg-muted/50 px-4 py-3">
                  <p className="text-sm font-semibold text-foreground">{r.role}</p>
                  <ul className="mt-1 space-y-0.5 pl-4">
                    {r.tasks.map((task) => (
                      <li key={task} className="list-disc text-[0.9375rem] leading-relaxed text-muted-foreground">
                        {task}
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      <Separator />

      {/* Candidate data sources with paths */}
      <div className="grid gap-6 lg:grid-cols-2">
        <div>
          <SectionHeading tooltip="Each dataset name is matched to concrete paths found in retrieved evidence (e.g. ADSL in a .sas7bdat or .xpt path). Re-run network ingest if paths are missing.">
            Candidate data sources
          </SectionHeading>
          <div className="mt-3 space-y-4">
            {responsePlan.recommendedDatasets.length === 0 ? (
              <p className="text-sm text-muted-foreground">No datasets inferred for this run.</p>
            ) : (
              responsePlan.recommendedDatasets.map((ds) => {
                const paths = pathsByDataset.get(ds) ?? []
                return (
                  <div key={ds} className="rounded-lg border border-border/70 bg-muted/20 px-4 py-3">
                    <p className="text-sm font-bold text-foreground">{ds}</p>
                    {paths.length === 0 ? (
                      <p className="mt-1 text-[0.8125rem] text-muted-foreground">
                        No indexed path matched this run&apos;s evidence for {ds} (transport files or dataset-tagged
                        chunks). Re-ingest, switch pool, or broaden the question so hits include {ds} or a{" "}
                        <span className="font-mono text-foreground/80">.sas7bdat</span> /{" "}
                        <span className="font-mono text-foreground/80">.xpt</span> path.
                      </p>
                    ) : (
                      <ul className="mt-2 max-h-40 space-y-1 overflow-y-auto font-mono text-[0.6875rem] leading-snug text-muted-foreground">
                        {paths.map((p) => (
                          <li key={p} className="break-all border-b border-border/30 pb-1 last:border-0">
                            {p}
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                )
              })
            )}
          </div>
        </div>

        <div>
          <SectionHeading tooltip="Prior outputs are titles and families drawn from evidence and interpretation — reuse candidates, not final deliverables.">
            Prior outputs to reuse
          </SectionHeading>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {responsePlan.candidateOutputs.map((out) => (
              <Badge key={out} variant="outline" className="rounded-md text-[0.6875rem]">
                {out}
              </Badge>
            ))}
          </div>
          <p className="mt-3 text-[0.75rem] leading-snug text-muted-foreground">
            The table below lists the strongest SAS matches for this question: up to {PLAN_RANKED_CODE_MAX} rows, within{" "}
            {PLAN_RANKED_CODE_SCORE_SPREAD} relevance points of the top hit.             If the full path column still shows only{" "}
            <span className="font-mono text-foreground/80">pgms/…</span>, run{" "}
            <span className="font-medium text-foreground">Rebuild network index</span> so the corpus stores{" "}
            <span className="font-mono text-foreground/80">networkScanRoot</span>, or set{" "}
            <span className="font-medium text-foreground">EVIDENCE_SCAN_ROOT</span> to that same folder, then re-run the
            copilot.
          </p>
        </div>
      </div>

      {/* Programs / macros table */}
      <Separator />
      <div>
        <SectionHeading tooltip={`Up to ${PLAN_RANKED_CODE_MAX} SAS rows closest to your question (by retrieval score). Rows within ~${PLAN_RANKED_CODE_SCORE_SPREAD} points of the top hit are shown first; the list widens if there are fewer than six strong matches so nearby programs still appear. Macros are one row per %macro in the source file.`}>
          Most likely programs / macros for this question
        </SectionHeading>
        {rankedCodeAssets.length === 0 ? (
          <p className="mt-3 text-[0.8125rem] text-muted-foreground">
            No .sas programs appeared in this run&apos;s evidence list. Retrieval now backfills SAS from the ranked
            index when possible—if this stays empty, your corpus may have no indexed programs for this pool or scores
            filtered everything out.
          </p>
        ) : (
          <div className="mt-3 overflow-x-auto rounded-lg border border-border">
              <table className="table-fixed w-full min-w-[48rem] border-collapse text-left text-[0.75rem]">
                <colgroup>
                  <col className="w-[4.5rem]" />
                  <col className="w-[4.25rem]" />
                  <col className="w-[10rem]" />
                  <col className="w-[min(40%,22rem)]" />
                  <col />
                </colgroup>
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-1.5 py-1.5 font-heading text-[0.5625rem] font-bold uppercase tracking-wider text-muted-foreground">
                      Type
                    </th>
                    <th className="px-1.5 py-1.5 font-heading text-[0.5625rem] font-bold uppercase tracking-wider text-muted-foreground">
                      Rel.
                    </th>
                    <th className="px-1.5 py-1.5 font-heading text-[0.5625rem] font-bold uppercase leading-tight text-muted-foreground">
                      Program / macro
                    </th>
                    <th className="px-1.5 py-1.5 font-heading text-[0.5625rem] font-bold uppercase leading-tight text-muted-foreground">
                      Full path (UNC / absolute)
                    </th>
                    <th className="min-w-0 px-1.5 py-1.5 font-heading text-[0.5625rem] font-bold uppercase tracking-wider text-muted-foreground">
                      Code
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {rankedCodeAssets.map((row) => {
                    const codeKey = row.documentId
                    const source = findSourceText(row.documentId, evidence)
                    const fullPathCell = fullPathForRankedCodeRow(
                      row,
                      evidence,
                      retrievalMetadata.networkScanRootUsed,
                    )
                    return (
                      <tr key={codeKey} className="border-b border-border/60 align-top">
                        <td className="px-1.5 py-1.5 capitalize whitespace-nowrap">{row.assetType}</td>
                        <td className="px-1.5 py-1.5 tabular-nums font-medium whitespace-nowrap">
                          {row.relevancePercent}%
                        </td>
                        <td className="min-w-0 px-1.5 py-1.5 align-top">
                          <span className="block font-semibold leading-tight text-foreground">
                            {row.assetType === "program" ? fileNameFromPath(row.path) : row.title}
                          </span>
                          {row.assetType === "macro" ? (
                            <span className="mt-0.5 block text-[0.625rem] leading-tight text-muted-foreground">
                              in {fileNameFromPath(row.path)}
                            </span>
                          ) : null}
                          {row.relativePath ? (
                            <span className="mt-0.5 block font-mono text-[0.625rem] leading-tight text-muted-foreground break-all">
                              {row.relativePath}
                            </span>
                          ) : null}
                        </td>
                        <td
                          className="min-w-[14rem] px-1.5 py-1.5 align-top font-mono text-[0.625rem] leading-snug break-all text-muted-foreground"
                          title={fullPathCell}
                        >
                          {fullPathCell}
                        </td>
                        <td className="min-w-0 px-1.5 py-1.5">
                          {source ? (
                            <Collapsible
                              open={openCodeId === codeKey}
                              onOpenChange={(o) => setOpenCodeId(o ? codeKey : null)}
                            >
                              <CollapsibleTrigger asChild>
                                <Button variant="outline" size="sm" className="h-7 shrink-0 text-[0.625rem]">
                                  {openCodeId === codeKey ? "Hide" : "Code"}
                                </Button>
                              </CollapsibleTrigger>
                              <CollapsibleContent>
                                <pre className="mt-2 max-h-[min(70vh,36rem)] w-full min-w-0 overflow-auto rounded border border-border bg-muted/40 p-2.5 font-mono text-[0.625rem] leading-snug">
                                  {source.slice(0, 24_000)}
                                  {source.length > 24_000 ? "\n\n… truncated …" : ""}
                                </pre>
                              </CollapsibleContent>
                            </Collapsible>
                          ) : (
                            <span className="text-muted-foreground/60">—</span>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
        )}
      </div>

      {/* Uncertainty sections */}
      {(result.assumptions.length > 0 || result.openQuestions.length > 0 || result.evidenceGaps.length > 0) && (
        <>
          <Separator />
          <div className="grid gap-6 lg:grid-cols-3">
            {result.assumptions.length > 0 && (
              <div>
                <SectionHeading tooltip="Assumptions are decisions the copilot made to fill in gaps - e.g. defaulting to the Safety Analysis Set when no population was specified. Verify these before using the plan.">
                  Assumptions
                </SectionHeading>
                <div className="mt-2">
                  <UncertaintyBlock items={result.assumptions} />
                </div>
              </div>
            )}
            {result.openQuestions.length > 0 && (
              <div>
                <SectionHeading tooltip="Open questions are ambiguities the copilot couldn't resolve from the evidence alone. These may need clarification from the requesting party or a statistician before proceeding.">
                  Open questions
                </SectionHeading>
                <div className="mt-2">
                  <UncertaintyBlock items={result.openQuestions} />
                </div>
              </div>
            )}
            {result.evidenceGaps.length > 0 && (
              <div>
                <SectionHeading tooltip="Evidence gaps indicate areas where the repo corpus didn't contain sufficient supporting material - e.g. missing SAS programs, undocumented datasets, or no prior output for this analysis type.">
                  Evidence gaps
                </SectionHeading>
                <div className="mt-2">
                  <UncertaintyBlock items={result.evidenceGaps} />
                </div>
              </div>
            )}
          </div>
        </>
      )}

      {/* Citations */}
      {responsePlan.citations.length > 0 && (
        <>
          <Separator />
          <div>
            <SectionHeading tooltip="Citations include evidence document IDs merged from the LLM and the full retrieval set so you can trace every surfaced asset.">
              Citations
            </SectionHeading>
            <div className="mt-2 flex max-h-48 flex-wrap gap-1.5 overflow-y-auto">
              {responsePlan.citations.map((c) => (
                <Badge key={c} variant="outline" className="rounded-md text-[0.6875rem]">
                  {c}
                </Badge>
              ))}
            </div>
          </div>
        </>
      )}

      {/* Warnings */}
      {result.warnings.length > 0 && (
        <>
          <Separator />
          <div>
            <SectionHeading tooltip="Warnings flag potential issues - e.g. low confidence in the interpretation, missing critical datasets, or conflicting evidence. Address these before relying on the plan.">
              Warnings
            </SectionHeading>
            <div className="mt-2">
              <UncertaintyBlock
                items={result.warnings.map((w) => ({ title: w, detail: "" }))}
                variant="warning"
              />
            </div>
          </div>
        </>
      )}
    </div>
  )
}
