"use client"

import { useState } from "react"

import type { EvidenceHit } from "@/lib/server/copilot/schemas"
import { Badge } from "@/components/ui/badge"
import { FormattedText } from "@/components/copilot/formatted-text"
import { Separator } from "@/components/ui/separator"
import { HelpIcon } from "@/components/copilot/verbose-context"

type EvidencePanelProps = {
  evidence: EvidenceHit[]
  pending: boolean
}

const EVIDENCE_DISPLAY_LIMIT = 8

function EvidenceRow({ hit, index }: { hit: EvidenceHit; index: number }) {
  return (
    <div className="evidence-row group">
      {/* Left: rank indicator */}
      <div className="evidence-rank">
        <span className="text-[0.6875rem] font-semibold tabular-nums text-muted-foreground">
          {String(index + 1).padStart(2, "0")}
        </span>
      </div>

      {/* Main content */}
      <div className="min-w-0 flex-1">
        <div className="flex items-start justify-between gap-4">
          <h3 className="text-[0.9375rem] font-semibold leading-snug text-foreground">
            {hit.document.title}
            <HelpIcon tooltip="The evidence title identifies the matched repo asset - a SAS program, dataset definition, or README section. Click to understand what this asset contains." />
          </h3>
          <Badge
            variant="outline"
            className="shrink-0 rounded-md font-heading text-[0.625rem] uppercase tracking-wider"
          >
            {hit.document.sourceType}
          </Badge>
        </div>

        <div className="mt-1.5 flex items-center gap-2">
          <div className="text-sm leading-relaxed text-foreground/80">
            <FormattedText text={hit.retrievalReason} />
            <HelpIcon tooltip="The retrieval reason explains why this particular evidence item was ranked here - e.g. keyword overlap with your question, matching dataset names, or output family alignment." />
          </div>
          {hit.vectorSimilarity !== null && hit.vectorSimilarity > 0 && (
            <Badge
              variant="outline"
              className="shrink-0 rounded-md text-[0.625rem] font-mono tabular-nums border-blue-200 bg-blue-50 text-blue-700"
            >
              {Math.round(hit.vectorSimilarity * 100)}% semantic
            </Badge>
          )}
        </div>

        {/* Tags row */}
        {(hit.document.datasetNames.length > 0 || hit.document.outputFamilies.length > 0) && (
          <div className="mt-2.5 flex flex-wrap items-center gap-1.5">
            {hit.document.datasetNames.map((name) => (
              <Badge
                key={`ds-${name}`}
                variant="secondary"
                className="rounded-md text-[0.6875rem]"
              >
                {name}
              </Badge>
            ))}
            {hit.document.outputFamilies.map((family) => (
              <Badge
                key={`of-${family}`}
                variant="outline"
                className="rounded-md text-[0.6875rem]"
              >
                {family}
              </Badge>
            ))}
            <HelpIcon tooltip="Tags show which ADaM datasets this evidence uses and which output family it belongs to (e.g. ae-overall, soc-pt, eair). These help you understand the evidence's scope." />
          </div>
        )}

        {/* File path */}
        <p className="mt-2 font-mono text-[0.6875rem] leading-snug text-muted-foreground/70">
          {hit.document.path}
        </p>
      </div>
    </div>
  )
}

export function EvidencePanel({ evidence, pending }: EvidencePanelProps) {
  const [expanded, setExpanded] = useState(false)

  const visibleEvidence =
    !expanded && evidence.length > EVIDENCE_DISPLAY_LIMIT
      ? evidence.slice(0, EVIDENCE_DISPLAY_LIMIT)
      : evidence

  if (pending) {
    return (
      <div className="space-y-4 animate-in">
        <div className="pipeline-progress" />
        <div className="skeleton-stagger space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="skeleton-block flex gap-4 p-4">
              <div className="h-5 w-8 shrink-0 rounded bg-border/50" />
              <div className="flex-1 space-y-2">
                <div className="h-4 w-3/5 rounded bg-border/60" />
                <div className="h-3 w-full rounded bg-border/40" />
                <div className="flex gap-2">
                  <div className="h-5 w-14 rounded-full bg-border/50" />
                  <div className="h-5 w-16 rounded-full bg-border/50" />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (evidence.length === 0) {
    return (
      <div className="py-12 text-center">
        <p className="text-sm text-muted-foreground">
          No evidence ranked yet. Results appear here after the copilot retrieves matching repo assets.
        </p>
      </div>
    )
  }

  return (
    <div className="stagger-children space-y-0">
      {/* Column headers */}
      <div className="flex items-center gap-4 px-4 pb-3">
        <span className="w-8 text-[0.625rem] font-semibold uppercase tracking-wider text-muted-foreground">
          #
        </span>
        <span className="text-[0.625rem] font-semibold uppercase tracking-wider text-muted-foreground">
          Source &middot; Relevance &middot; Tags
          <HelpIcon tooltip="Evidence items are ranked by relevance score. Each row shows a matched repo asset (SAS program, dataset, or brief), why it was retrieved, and its associated datasets and output families." />
        </span>
      </div>
      <Separator />

      {visibleEvidence.map((hit, index) => (
        <EvidenceRow key={hit.document.id} hit={hit} index={index} />
      ))}

      {evidence.length > EVIDENCE_DISPLAY_LIMIT && (
        <div className="pt-4 text-center">
          <button
            type="button"
            onClick={() => setExpanded((prev) => !prev)}
            className="focus-ring rounded-md px-4 py-2 text-sm font-semibold text-primary transition-colors hover:bg-secondary"
          >
            {expanded
              ? "Show fewer"
              : `Show all ${evidence.length} evidence items`}
          </button>
        </div>
      )}
    </div>
  )
}
