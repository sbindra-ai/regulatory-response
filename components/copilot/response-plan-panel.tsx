import type { ReactNode } from "react"

import type { CopilotResult } from "@/lib/server/copilot/schemas"
import { Badge } from "@/components/ui/badge"
import { FormattedText } from "@/components/copilot/formatted-text"
import { Separator } from "@/components/ui/separator"
import { HelpIcon } from "@/components/copilot/verbose-context"

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

export function ResponsePlanPanel({ pending, result }: ResponsePlanPanelProps) {
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

  return (
    <div className="stagger-children space-y-6">
      {/* Objective + approach */}
      <div>
        <SectionHeading tooltip="The recommended approach outlines the overall objective and strategy the copilot suggests for addressing your regulatory question, based on matched evidence and known output patterns.">
          Recommended approach
        </SectionHeading>
        <p className="mt-2 text-base font-semibold leading-snug text-foreground">
          {result.responsePlan.objective}
        </p>
        <div className="mt-2 text-[0.9375rem] leading-relaxed text-foreground/85">
          <FormattedText text={result.responsePlan.recommendedApproach} />
        </div>
      </div>

      {/* Deliverables */}
      {result.responsePlan.deliverables.length > 0 && (
        <div>
          <SectionHeading tooltip="Deliverables are the specific outputs the copilot recommends producing - e.g. tables, figures, or listings. Each is derived from matched SAS programs and dataset structures in the evidence corpus.">
            Deliverables
          </SectionHeading>
          <ol className="mt-2 space-y-1.5 pl-5">
            {result.responsePlan.deliverables.map((item, i) => (
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
      {result.responsePlan.responsibilities.length > 0 && (
        <>
          <Separator />
          <div>
            <SectionHeading tooltip="Responsibilities assign specific tasks to team roles - e.g. Statistician, SAS Programmer, Data Scientist - so each member knows what to deliver for this plan.">
              Responsibilities
            </SectionHeading>
            <div className="mt-2 space-y-3">
              {result.responsePlan.responsibilities.map((r) => (
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

      {/* Data sources + outputs in 2-col */}
      <div className="grid gap-6 sm:grid-cols-2">
        <div>
          <SectionHeading tooltip="Candidate data sources are the ADaM datasets and other data assets that the copilot identified as likely needed to produce the recommended deliverables.">
            Candidate data sources
          </SectionHeading>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {result.responsePlan.recommendedDatasets.map((ds) => (
              <Badge key={ds} variant="secondary" className="rounded-md text-[0.6875rem]">
                {ds}
              </Badge>
            ))}
          </div>
        </div>

        <div>
          <SectionHeading tooltip="Prior outputs are existing SAS programs, tables, or figures in the repo that could be reused or adapted for your request - reducing the need to build from scratch.">
            Prior outputs to reuse
          </SectionHeading>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {result.responsePlan.candidateOutputs.map((out) => (
              <Badge key={out} variant="outline" className="rounded-md text-[0.6875rem]">
                {out}
              </Badge>
            ))}
          </div>
        </div>
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
      {result.responsePlan.citations.length > 0 && (
        <>
          <Separator />
          <div>
            <SectionHeading tooltip="Citations reference specific repo files (SAS programs, README sections, define.xml entries) that grounded the copilot's recommendations. Use these to trace the plan back to source evidence.">
              Citations
            </SectionHeading>
            <div className="mt-2 flex flex-wrap gap-1.5">
              {result.responsePlan.citations.map((c) => (
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
