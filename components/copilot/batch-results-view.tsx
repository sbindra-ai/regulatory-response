"use client"

import type { BatchCopilotState } from "@/lib/server/copilot/batch-types"
import { EvidencePanel } from "@/components/copilot/evidence-panel"
import { InterpretationPanel } from "@/components/copilot/interpretation-panel"
import { ResponsePlanPanel } from "@/components/copilot/response-plan-panel"
import { VerboseToggle } from "@/components/copilot/verbose-context"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

function truncate(text: string, max: number) {
  return text.length > max ? `${text.slice(0, max)}…` : text
}

function formatTokenCount(count: number): string {
  return count >= 1000 ? `${(count / 1000).toFixed(1)}k` : String(count)
}

export function BatchResultsView({
  batchState,
  pending,
}: {
  batchState: BatchCopilotState
  pending: boolean
}) {
  const completedResults = batchState.results.filter((r) => r.result !== null)
  const totalTokens = completedResults.reduce(
    (acc, r) => ({
      promptTokens: acc.promptTokens + (r.result?.tokenUsage.promptTokens ?? 0),
      completionTokens: acc.completionTokens + (r.result?.tokenUsage.completionTokens ?? 0),
      totalTokens: acc.totalTokens + (r.result?.tokenUsage.totalTokens ?? 0),
    }),
    { promptTokens: 0, completionTokens: 0, totalTokens: 0 },
  )

  return (
    <div className="space-y-4">
      {/* Summary header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h2 className="font-heading text-[0.9375rem] font-bold text-foreground">
            Batch Results
            <span className="ml-2 text-[0.8125rem] font-normal text-muted-foreground">
              ({batchState.results.length} question{batchState.results.length !== 1 ? "s" : ""})
            </span>
          </h2>
          {pending && (
            <span className="inline-flex items-center gap-1.5 text-[0.75rem] font-medium text-[#00BCFF]">
              <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-[#00BCFF]" />
              Processing…
            </span>
          )}
        </div>
        <div className="flex items-center gap-4">
          {totalTokens.totalTokens > 0 && (
            <div className="flex items-center gap-2 rounded-md border border-border/50 bg-muted/50 px-2.5 py-1 text-[0.6875rem] tabular-nums text-muted-foreground">
              <span>{formatTokenCount(totalTokens.totalTokens)} tokens</span>
              <span className="text-border">|</span>
              <span>{formatTokenCount(totalTokens.promptTokens)} in</span>
              <span className="text-border">|</span>
              <span>{formatTokenCount(totalTokens.completionTokens)} out</span>
            </div>
          )}
          <VerboseToggle />
        </div>
      </div>

      {batchState.error && (
        <div className="rounded-xl border border-destructive/20 bg-[color-mix(in_srgb,var(--destructive)_4%,white)] px-5 py-4">
          <p className="text-sm font-semibold text-destructive">{batchState.error}</p>
        </div>
      )}

      {/* Accordion per question */}
      <Accordion type="multiple" defaultValue={[batchState.results[0]?.questionId ?? ""]} className="space-y-3">
        {batchState.results.map((item, idx) => (
          <AccordionItem
            key={item.questionId}
            value={item.questionId}
            className="rounded-xl border border-border/70 bg-white shadow-[0_1px_3px_rgba(16,56,79,0.04)] overflow-hidden"
          >
            <AccordionTrigger className="px-5 py-3 hover:no-underline">
              <div className="flex items-center gap-3 text-left">
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-muted text-[0.6875rem] font-bold tabular-nums text-muted-foreground">
                  {idx + 1}
                </span>
                <span className="text-[0.875rem] font-medium text-foreground">
                  {truncate(item.questionText, 100)}
                </span>
                {item.error ? (
                  <span className="shrink-0 rounded-full bg-destructive/10 px-2 py-0.5 text-[0.6875rem] font-semibold text-destructive">
                    Error
                  </span>
                ) : item.result ? (
                  <span
                    className={`shrink-0 rounded-full px-2 py-0.5 text-[0.6875rem] font-semibold ${
                      item.result.interpretation.confidence === "high"
                        ? "bg-emerald-100 text-emerald-700"
                        : item.result.interpretation.confidence === "medium"
                          ? "bg-amber-100 text-amber-700"
                          : "bg-red-100 text-red-700"
                    }`}
                  >
                    {item.result.interpretation.confidence}
                  </span>
                ) : null}
              </div>
            </AccordionTrigger>
            <AccordionContent className="px-5 pb-5">
              {item.error ? (
                <div className="rounded-lg border border-destructive/20 bg-[color-mix(in_srgb,var(--destructive)_4%,white)] px-4 py-3">
                  <p className="text-sm text-destructive">{item.error}</p>
                </div>
              ) : item.result ? (
                <div className="space-y-4">
                  <InterpretationPanel
                    interpretation={item.result.interpretation}
                    pending={false}
                  />
                  <Tabs defaultValue="plan" className="w-full">
                    <TabsList className="results-tab-list">
                      <TabsTrigger value="plan" className="results-tab-trigger">
                        Response Plan
                      </TabsTrigger>
                      <TabsTrigger value="evidence" className="results-tab-trigger">
                        Evidence
                        {item.result.evidence.length > 0 && (
                          <span className="ml-1.5 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-primary/10 px-1.5 text-[0.625rem] font-bold tabular-nums text-primary">
                            {item.result.evidence.length}
                          </span>
                        )}
                      </TabsTrigger>
                    </TabsList>
                    <TabsContent value="plan" className="results-tab-content">
                      <ResponsePlanPanel pending={false} result={item.result} />
                    </TabsContent>
                    <TabsContent value="evidence" className="results-tab-content">
                      <EvidencePanel evidence={item.result.evidence} pending={false} />
                    </TabsContent>
                  </Tabs>
                </div>
              ) : null}
            </AccordionContent>
          </AccordionItem>
        ))}
      </Accordion>
    </div>
  )
}
