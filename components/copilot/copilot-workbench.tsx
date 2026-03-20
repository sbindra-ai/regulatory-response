"use client"

import { useImperativeHandle, useRef, useState, forwardRef, useCallback } from "react"

import { type RunCopilotActionState, runCopilotAction } from "@/app/actions/run-copilot"
import { runBatchCopilotAction } from "@/app/actions/run-batch-copilot"
import { BatchResultsView } from "@/components/copilot/batch-results-view"
import { EvidencePanel } from "@/components/copilot/evidence-panel"
import { FollowUpChat } from "@/components/copilot/follow-up-chat"
import { InterpretationPanel } from "@/components/copilot/interpretation-panel"
import { PredictionsPanel } from "@/components/copilot/predictions-panel"
import { QuestionForm } from "@/components/copilot/question-form"
import { ResponsePlanPanel } from "@/components/copilot/response-plan-panel"
import { VerboseProvider, VerboseToggle } from "@/components/copilot/verbose-context"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { demoPrompts } from "@/lib/copilot/demo-prompts"
import { getMgaToken } from "@/lib/copilot/mga-token"
import type { HistoryEntry, NewHistoryEntry } from "@/lib/copilot/query-history"
import type { DetectedQuestion } from "@/lib/copilot/question-detection"
import type { BatchCopilotState } from "@/lib/server/copilot/batch-types"
import type { TokenUsage } from "@/lib/server/copilot/schemas"

function formatTokenCount(count: number): string {
  if (count >= 1000) {
    return `${(count / 1000).toFixed(1)}k`
  }
  return String(count)
}

function ContextUsageBadge({ usage }: { usage: TokenUsage }) {
  return (
    <div className="flex items-center gap-2 rounded-md border border-border/50 bg-muted/50 px-2.5 py-1 text-[0.6875rem] tabular-nums text-muted-foreground">
      <span title="Total tokens used across all LLM calls">
        {formatTokenCount(usage.totalTokens)} tokens
      </span>
      <span className="text-border">|</span>
      <span title="Prompt (input) tokens">
        {formatTokenCount(usage.promptTokens)} in
      </span>
      <span className="text-border">|</span>
      <span title="Completion (output) tokens">
        {formatTokenCount(usage.completionTokens)} out
      </span>
    </div>
  )
}

const initialRunCopilotActionState: RunCopilotActionState = {
  error: null,
  question: "",
  result: null,
}

export type CopilotWorkbenchHandle = {
  restoreFromHistory: (entry: HistoryEntry) => void
}

type CopilotWorkbenchProps = {
  onSaveEntry?: (entry: NewHistoryEntry) => string
  onClearActiveId?: () => void
}

export const CopilotWorkbench = forwardRef<CopilotWorkbenchHandle, CopilotWorkbenchProps>(function CopilotWorkbench({ onSaveEntry, onClearActiveId }, ref) {
  const [state, setState] = useState<RunCopilotActionState>({
    ...initialRunCopilotActionState,
    question: demoPrompts[0]?.question ?? "",
  })
  const [pending, setPending] = useState(false)
  const [question, setQuestion] = useState(demoPrompts[0]?.question ?? "")
  const abortRef = useRef<AbortController | null>(null)

  // Batch state
  const [batchState, setBatchState] = useState<BatchCopilotState | null>(null)
  const [batchPending, setBatchPending] = useState(false)
  const [detectedQuestions, setDetectedQuestions] = useState<DetectedQuestion[]>([])
  const [uploadPending, setUploadPending] = useState(false)

  // Key that increments on each new copilot run to reset follow-up chat state
  const [runKey, setRunKey] = useState(0)

  async function formAction(formData: FormData) {
    // Clear batch state when running single question
    setBatchState(null)
    onClearActiveId?.()
    abortRef.current?.abort()
    const controller = new AbortController()
    abortRef.current = controller
    setState((prev) => ({ ...prev, error: null, result: null }))
    setPending(true)
    setRunKey((k) => k + 1)
    try {
      const result = await runCopilotAction(state, formData)
      if (!controller.signal.aborted) {
        setState(result)
        // Save to history on successful completion
        if (result.result && onSaveEntry) {
          const interp = result.result.interpretation
          onSaveEntry({
            type: "single",
            question: result.question,
            questionCount: 1,
            confidenceLevel: interp?.confidence ?? null,
            confidenceScore: interp?.confidenceScore?.overall ?? null,
            evidenceCount: result.result.evidence?.length ?? 0,
            singleState: result,
            batchState: null,
          })
        }
      }
    } finally {
      if (!controller.signal.aborted) {
        setPending(false)
      }
    }
  }

  function handleInterrupt() {
    abortRef.current?.abort()
    abortRef.current = null
    setPending(false)
    setBatchPending(false)
  }

  async function handleBatchSubmit(questions: DetectedQuestion[]) {
    // Clear single-question state
    setState(initialRunCopilotActionState)
    setDetectedQuestions([])
    onClearActiveId?.()
    setBatchPending(true)
    setBatchState({ results: [], error: null })

    try {
      const result = await runBatchCopilotAction(
        questions.map((q) => ({ id: q.id, text: q.text, source: q.source })),
        {},
        getMgaToken() || undefined,
      )
      setBatchState(result)
      // Save batch to history
      if (onSaveEntry && result.results.length > 0) {
        const firstResult = result.results[0]?.result
        const interp = firstResult?.interpretation
        const totalEvidence = result.results.reduce(
          (sum, r) => sum + (r.result?.evidence?.length ?? 0),
          0,
        )
        onSaveEntry({
          type: "batch",
          question: questions[0]?.text ?? "",
          questionCount: questions.length,
          confidenceLevel: interp?.confidence ?? null,
          confidenceScore: interp?.confidenceScore?.overall ?? null,
          evidenceCount: totalEvidence,
          singleState: null,
          batchState: result,
        })
      }
    } catch (error) {
      setBatchState({
        results: [],
        error: error instanceof Error ? error.message : "Batch processing failed.",
      })
    } finally {
      setBatchPending(false)
    }
  }

  // Expose restore to parent via ref
  useImperativeHandle(ref, () => ({ restoreFromHistory }), [])

  // Restore state from a history entry
  function restoreFromHistory(entry: HistoryEntry) {
    if (entry.type === "single" && entry.singleState) {
      setState(entry.singleState)
      setQuestion(entry.singleState.question)
      setBatchState(null)
    } else if (entry.type === "batch" && entry.batchState) {
      setBatchState(entry.batchState)
      setState(initialRunCopilotActionState)
      setQuestion(entry.question)
    }
    setPending(false)
    setBatchPending(false)
  }

  const [exporting, setExporting] = useState(false)
  const [rebuilding, setRebuilding] = useState(false)
  const [rebuildResult, setRebuildResult] = useState<{ documentCount: number; embeddingCount: number } | null>(null)

  const hasResult = state.result !== null
  const evidenceCount = state.result?.evidence?.length ?? 0
  const interpretation = state.result?.interpretation
  const needsBetterPrompt =
    !pending &&
    hasResult &&
    interpretation &&
    (interpretation.requestType === "unknown" || interpretation.confidenceScore.overall < 40)

  async function exportPdf() {
    if (!state.result) return
    setExporting(true)

    try {
      const response = await fetch("/api/export-pdf", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question: state.question, result: state.result }),
      })

      if (!response.ok) {
        throw new Error("Export failed")
      }

      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const link = document.createElement("a")
      link.href = url
      link.download = "copilot-report.pdf"
      link.click()
      URL.revokeObjectURL(url)
    } catch (error) {
      console.error("PDF export failed:", error)
    } finally {
      setExporting(false)
    }
  }

  async function rebuildCorpus() {
    setRebuilding(true)
    setRebuildResult(null)

    try {
      const response = await fetch("/api/rebuild-corpus", { method: "POST" })
      const data = await response.json()

      if (!response.ok || !data.success) {
        throw new Error(data.error ?? "Rebuild failed")
      }

      setRebuildResult({
        documentCount: data.documentCount ?? 0,
        embeddingCount: data.embeddingCount ?? 0,
      })
    } catch (error) {
      console.error("Corpus rebuild failed:", error)
    } finally {
      setRebuilding(false)
    }
  }

  const handleRunPredictedQuestion = useCallback((predictedQuestion: string) => {
    setQuestion(predictedQuestion)
    const fd = new FormData()
    fd.set("question", predictedQuestion)
    formAction(fd)
  }, [])

  const showBatchResults = batchState !== null && (batchState.results.length > 0 || batchState.error)

  return (
    <VerboseProvider>
      <div className="space-y-6">
        <QuestionForm
          error={state.error}
          formAction={formAction}
          onInterrupt={handleInterrupt}
          pending={pending || batchPending}
          question={question}
          samplePrompts={demoPrompts}
          setQuestion={setQuestion}
          onRebuild={rebuildCorpus}
          rebuildResult={rebuildResult}
          rebuilding={rebuilding}
          detectedQuestions={detectedQuestions}
          setDetectedQuestions={setDetectedQuestions}
          onBatchSubmit={handleBatchSubmit}
          uploadPending={uploadPending}
          setUploadPending={setUploadPending}
        />

        {/* Batch results view */}
        {showBatchResults && (
          <BatchResultsView batchState={batchState} pending={batchPending} />
        )}

        {/* Single-question results (unchanged) */}
        {!showBatchResults && (
          <>
            {/* Interpretation: compact summary strip (always visible when pending or has result) */}
            {(pending || hasResult) && (
              <div>
                <div className="mb-2 flex items-center justify-between">
                  <h2 className="font-heading text-[0.9375rem] font-bold text-foreground">
                    Interpretation
                  </h2>
                  <div className="flex items-center gap-4">
                    {hasResult && state.result?.tokenUsage && (
                      <ContextUsageBadge usage={state.result.tokenUsage} />
                    )}
                    <VerboseToggle />
                    {hasResult && (
                      <Button onClick={exportPdf} disabled={exporting} variant="outline" size="sm">
                        {exporting ? "Exporting\u2026" : "Export PDF"}
                      </Button>
                    )}
                  </div>
                </div>
                <InterpretationPanel interpretation={state.result?.interpretation ?? null} pending={pending} />
              </div>
            )}

            {/* Prompt quality feedback */}
            {needsBetterPrompt && (
              <div className="animate-in rounded-xl border border-amber-200 bg-amber-50 px-5 py-4">
                <div className="flex items-start gap-3">
                  <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-amber-200 text-sm">
                    !
                  </span>
                  <div>
                    <p className="text-sm font-semibold text-amber-900">
                      Your question could use more detail
                    </p>
                    <p className="mt-1 text-sm leading-relaxed text-amber-800/80">
                      The copilot wasn&apos;t able to confidently map your question to a supported evidence family.
                      Try adding specifics like the analysis type (e.g. &ldquo;AE summary&rdquo;, &ldquo;EAIR&rdquo;),
                      the target population, timepoints (e.g. &ldquo;week 12&rdquo;), or relevant datasets.
                      You can also try one of the sample prompts for a well-supported starting point.
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Evidence + Response Plan + Predictions in full-width tabs */}
            {(pending || hasResult) && (
              <Tabs defaultValue="plan" className="w-full">
                <TabsList className="results-tab-list">
                  <TabsTrigger value="plan" className="results-tab-trigger">
                    Response Plan
                  </TabsTrigger>
                  <TabsTrigger value="predictions" className="results-tab-trigger">
                    Anticipated Questions
                  </TabsTrigger>
                  <TabsTrigger value="evidence" className="results-tab-trigger">
                    Evidence
                    {evidenceCount > 0 && (
                      <span className="ml-1.5 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-primary/10 px-1.5 text-[0.625rem] font-bold tabular-nums text-primary">
                        {evidenceCount}
                      </span>
                    )}
                  </TabsTrigger>
                </TabsList>

                <TabsContent value="plan" className="results-tab-content">
                  <ResponsePlanPanel pending={pending} result={state.result} />
                  {hasResult && state.result && (
                    <FollowUpChat
                      key={runKey}
                      copilotResult={state.result}
                      originalQuestion={state.question}
                    />
                  )}
                </TabsContent>

                <TabsContent value="predictions" className="results-tab-content">
                  <PredictionsPanel
                    key={runKey}
                    copilotResult={state.result}
                    originalQuestion={state.question}
                    onRunQuestion={handleRunPredictedQuestion}
                    pending={pending}
                  />
                </TabsContent>

                <TabsContent value="evidence" className="results-tab-content">
                  <EvidencePanel evidence={state.result?.evidence ?? []} pending={pending} />
                </TabsContent>
              </Tabs>
            )}
          </>
        )}
      </div>
    </VerboseProvider>
  )
})
