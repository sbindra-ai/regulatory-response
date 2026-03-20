"use client"

import type { ConfidenceScore, RequestInterpretation } from "@/lib/server/copilot/schemas"
import { Badge } from "@/components/ui/badge"
import { FormattedText } from "@/components/copilot/formatted-text"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { Separator } from "@/components/ui/separator"
import { HelpIcon } from "@/components/copilot/verbose-context"

type InterpretationPanelProps = {
  interpretation: RequestInterpretation | null
  pending: boolean
}

function Field({ label, tooltip, children }: { label: string; tooltip: string; children: React.ReactNode }) {
  return (
    <div className="space-y-1">
      <dt className="text-[0.6875rem] font-semibold uppercase tracking-wider text-muted-foreground">
        {label}
        <HelpIcon tooltip={tooltip} />
      </dt>
      <dd className="text-[0.9375rem] leading-snug text-foreground">{children}</dd>
    </div>
  )
}



function SubScoreBar({ label, score }: { label: string; score: number }) {
  const color =
    score >= 70
      ? "bg-emerald-500"
      : score >= 40
        ? "bg-amber-500"
        : "bg-red-500"

  return (
    <div className="flex items-center gap-2 text-[0.6875rem]">
      <span className="w-24 shrink-0 text-muted-foreground">{label}</span>
      <div className="h-1.5 flex-1 rounded-full bg-muted">
        <div className={`h-full rounded-full ${color}`} style={{ width: `${score}%` }} />
      </div>
      <span className="w-8 text-right tabular-nums text-muted-foreground">{score}</span>
    </div>
  )
}

function ConfidenceBadge({ confidenceScore }: { confidenceScore: ConfidenceScore }) {
  const level = confidenceScore.level
  const styles =
    level === "high"
      ? "border-emerald-200 bg-emerald-50 text-emerald-700"
      : level === "medium"
        ? "border-amber-200 bg-amber-50 text-amber-700"
        : "border-red-200 bg-red-50 text-red-700"
  const dotColor =
    level === "high"
      ? "bg-emerald-500"
      : level === "medium"
        ? "bg-amber-500"
        : "bg-red-500"
  return (
    <Popover>
      <PopoverTrigger asChild>
        <button type="button" className="focus-ring rounded-md">
          <Badge variant="outline" className={`rounded-md font-heading text-[0.6875rem] uppercase tracking-wider gap-1.5 cursor-pointer ${styles}`}>
            <span className={`inline-block h-2 w-2 rounded-full ${dotColor}`} />
            <span className="capitalize">{level} confidence ({confidenceScore.overall}/100)</span>
          </Badge>
        </button>
      </PopoverTrigger>

      <PopoverContent className="w-80">
        <div className="space-y-3">
          <p className="text-[0.8125rem] font-semibold text-foreground">Confidence breakdown</p>

          <div className="space-y-2">
            <SubScoreBar label="Interpretation" score={confidenceScore.interpretationScore} />
            <SubScoreBar label="Relevance" score={confidenceScore.evidenceRelevanceScore} />
            <SubScoreBar label="Coverage" score={confidenceScore.evidenceCoverageScore} />
          </div>

          {confidenceScore.reasons.length > 0 && (
            <>
              <Separator />
              <ul className="space-y-1">
                {confidenceScore.reasons.map((reason) => (
                  <li key={reason} className="text-[0.75rem] leading-snug text-muted-foreground">
                    <span className="mr-1.5 text-foreground/40">&bull;</span>
                    {reason}
                  </li>
                ))}
              </ul>
            </>
          )}
        </div>
      </PopoverContent>
    </Popover>
  )
}

export function InterpretationPanel({ interpretation, pending }: InterpretationPanelProps) {
  if (pending) {
    return (
      <div className="interpretation-strip animate-in">
        <div className="pipeline-progress" />
        <div className="mt-3 flex flex-wrap gap-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="skeleton-block h-6 w-20 rounded-full" />
          ))}
        </div>
        <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="skeleton-block h-12 rounded-md" />
          ))}
        </div>
      </div>
    )
  }

  if (!interpretation) {
    return (
      <div className="interpretation-strip">
        <p className="text-sm text-muted-foreground">
          Run the copilot to see how the regulatory question is classified, what datasets are likely needed,
          and the confidence level of the interpretation.
        </p>
      </div>
    )
  }

  return (
    <div className="interpretation-strip animate-in">
      {/* Row 1: Signal badges */}
      <div className="flex flex-wrap items-center gap-2">
        <Badge variant="default" className="rounded-md font-heading text-[0.6875rem] uppercase tracking-wider">
          {interpretation.requestType}
        </Badge>
        <HelpIcon tooltip="The detected request type classifies your question into a supported evidence family (e.g. AE summary, EAIR, BMD figure). This determines which datasets, programs, and output templates are searched." />
        <ConfidenceBadge confidenceScore={interpretation.confidenceScore} />
        <HelpIcon tooltip="Confidence is computed from three sub-scores: interpretation quality, evidence relevance (semantic similarity), and evidence coverage (dataset/family match). Click the badge to see the breakdown." />
        {interpretation.outputTypes.map((t) => (
          <Badge key={t} variant="secondary" className="rounded-md font-heading text-[0.6875rem] uppercase tracking-wider">
            {t}
          </Badge>
        ))}
        <HelpIcon tooltip="Output types indicate the expected deliverable format - table, figure, or plan - based on the detected request type." />
      </div>

      <Separator className="my-4" />

      {/* Row 2: Reading (full width) */}
      <dl>
        <Field
          label="Reading"
          tooltip="A one-line summary of how the copilot interpreted your regulatory question. This drives all downstream retrieval and plan generation."
        >
          <FormattedText text={interpretation.summary} />
        </Field>
      </dl>

      {/* Row 3: Compact fields */}
      <dl className="mt-4 grid gap-x-8 gap-y-4 sm:grid-cols-3">
        <Field
          label="Analysis lens"
          tooltip="The type of statistical analysis the copilot expects is needed - e.g. overall AE summary, SOC/PT incidence, or EAIR calculation. The statistical model (if any) is shown below."
        >
          <span>{interpretation.analysisType}</span>
          {interpretation.statisticalModel && (
            <span className="mt-0.5 block text-sm text-muted-foreground">
              {interpretation.statisticalModel}
            </span>
          )}
        </Field>
        <Field
          label="Population"
          tooltip="The analysis population inferred from your question - e.g. Safety Analysis Set, Full Analysis Set, or a specific subgroup. Defaults to Safety Analysis Set if not stated."
        >
          {interpretation.population}
        </Field>
        <Field
          label="Endpoint"
          tooltip="The clinical endpoint or measure the copilot identified from your question - e.g. treatment-emergent AEs, bone mineral density, or laboratory values."
        >
          {interpretation.endpoint}
        </Field>
      </dl>

      {/* Row 4: Compact inline details */}
      {(interpretation.timepoints.length > 0 || interpretation.datasetHints.length > 0) && (
        <>
          <Separator className="my-4" />
          <div className="flex flex-wrap items-start gap-x-10 gap-y-3">
            {interpretation.timepoints.length > 0 && (
              <div className="flex items-center gap-2">
                <span className="text-[0.6875rem] font-semibold uppercase tracking-wider text-muted-foreground">
                  Timepoints
                  <HelpIcon tooltip="Timepoints extracted from your question (e.g. Week 12, Week 26). These help the copilot focus on the correct analysis window and match relevant SAS programs." />
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {interpretation.timepoints.map((t) => (
                    <Badge key={t} variant="outline" className="rounded-md text-[0.6875rem]">
                      {t}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            {interpretation.datasetHints.length > 0 && (
              <div className="flex items-center gap-2">
                <span className="text-[0.6875rem] font-semibold uppercase tracking-wider text-muted-foreground">
                  Likely datasets
                  <HelpIcon tooltip="ADaM datasets the copilot predicts are needed based on your request type - e.g. ADAE for adverse events, ADLB for lab data, ADSL for subject-level demographics." />
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {interpretation.datasetHints.map((d) => (
                    <Badge key={d} variant="secondary" className="rounded-md text-[0.6875rem]">
                      {d}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  )
}
