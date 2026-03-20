"use client"

import { useEffect, useState } from "react"

import { predictQuestionsAction } from "@/app/actions/predict-questions"
import { Badge } from "@/components/ui/badge"
import { getMgaToken } from "@/lib/copilot/mga-token"
import type { CopilotResult, PredictedQuestion } from "@/lib/server/copilot/schemas"

type PredictionsPanelProps = {
  copilotResult: CopilotResult | null
  originalQuestion: string
  onRunQuestion: (question: string) => void
  pending: boolean
}

const likelihoodColors: Record<string, string> = {
  high: "bg-emerald-100 text-emerald-800 border-emerald-200",
  medium: "bg-amber-100 text-amber-800 border-amber-200",
  low: "bg-gray-100 text-gray-600 border-gray-200",
}

export function PredictionsPanel({ copilotResult, originalQuestion, onRunQuestion, pending }: PredictionsPanelProps) {
  const [predictions, setPredictions] = useState<PredictedQuestion[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [generated, setGenerated] = useState(false)

  // Auto-generate predictions when copilotResult becomes available
  useEffect(() => {
    if (copilotResult && !generated && !loading) {
      generatePredictions()
    }
  }, [copilotResult])

  async function generatePredictions() {
    if (!copilotResult) return
    setLoading(true)
    setError(null)

    try {
      const result = await predictQuestionsAction(originalQuestion, copilotResult, getMgaToken() || undefined)
      if (result.error) {
        setError(result.error)
      } else {
        setPredictions(result.predictions)
      }
      setGenerated(true)
    } catch {
      setError("Failed to generate predictions. Please try again.")
      setGenerated(true)
    } finally {
      setLoading(false)
    }
  }

  if (pending) {
    return (
      <div className="space-y-4 animate-in">
        <div className="pipeline-progress" />
        <div className="skeleton-stagger space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="skeleton-block space-y-2 p-4">
              <div className="h-3 w-3/4 rounded bg-border/60" />
              <div className="h-3 w-full rounded bg-border/40" />
              <div className="h-3 w-2/3 rounded bg-border/40" />
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (!copilotResult) {
    return (
      <div className="py-12 text-center">
        <p className="text-sm text-muted-foreground">
          Run the copilot first to see anticipated follow-up questions from the health authority.
        </p>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="space-y-4 animate-in">
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <span className="inline-block h-3 w-3 animate-spin rounded-full border-2 border-[#00BCFF] border-t-transparent" />
          Predicting likely follow-up questions from the health authority...
        </div>
        <div className="skeleton-stagger space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="skeleton-block space-y-2 p-4">
              <div className="h-3 w-3/4 rounded bg-border/60" />
              <div className="h-3 w-full rounded bg-border/40" />
              <div className="h-3 w-2/3 rounded bg-border/40" />
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="space-y-4">
        <div className="rounded-xl border border-destructive/20 bg-[color-mix(in_srgb,var(--destructive)_4%,white)] px-5 py-4">
          <p className="text-sm font-semibold text-destructive">Prediction failed</p>
          <p className="mt-1 text-sm text-foreground">{error}</p>
        </div>
        <button
          type="button"
          onClick={generatePredictions}
          className="focus-ring rounded-lg border border-border/70 bg-white px-4 py-2 text-[0.8125rem] font-semibold text-foreground transition-all hover:border-[#00BCFF]/50 hover:shadow-[0_2px_8px_rgba(0,188,255,0.1)]"
        >
          Retry
        </button>
      </div>
    )
  }

  if (predictions.length === 0 && generated) {
    return (
      <div className="py-12 text-center">
        <p className="text-sm text-muted-foreground">No anticipated questions were generated.</p>
        <button
          type="button"
          onClick={generatePredictions}
          className="focus-ring mt-3 rounded-lg border border-border/70 bg-white px-4 py-2 text-[0.8125rem] font-semibold text-foreground transition-all hover:border-[#00BCFF]/50"
        >
          Try again
        </button>
      </div>
    )
  }

  if (predictions.length === 0) {
    return (
      <div className="py-12 text-center">
        <p className="text-sm text-muted-foreground">
          Predict what the health authority will likely ask next based on your current response plan.
        </p>
        <button
          type="button"
          onClick={generatePredictions}
          className="focus-ring mt-3 rounded-lg bg-[#10384F] px-5 py-2.5 text-[0.8125rem] font-semibold text-white transition-all hover:bg-[#10384F]/90 active:scale-[0.98]"
        >
          Generate Predictions
        </button>
      </div>
    )
  }

  return (
    <div className="stagger-children space-y-4">
      <p className="text-[0.8125rem] text-muted-foreground">
        Based on your response plan, the health authority is likely to follow up with these questions.
        Click &ldquo;Run this question&rdquo; to generate a full response plan for any of them.
      </p>

      {predictions.map((pred, i) => (
        <div
          key={i}
          className="rounded-md border border-border bg-white px-5 py-4 shadow-[0_1px_3px_rgba(16,56,79,0.04)] transition-all hover:shadow-[0_2px_8px_rgba(16,56,79,0.06)]"
        >
          <div className="flex items-start justify-between gap-3">
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary/10 text-[0.625rem] font-bold text-primary">
                  {i + 1}
                </span>
                <Badge
                  variant="outline"
                  className={`rounded-full text-[0.625rem] font-bold ${likelihoodColors[pred.likelihood] ?? likelihoodColors.low}`}
                >
                  {pred.likelihood} likelihood
                </Badge>
                <span className={`inline-flex items-center gap-1 text-[0.6875rem] font-medium ${pred.evidenceAvailable ? "text-emerald-700" : "text-amber-700"}`}>
                  {pred.evidenceAvailable ? (
                    <>
                      <svg className="h-3 w-3" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a7 7 0 110 14A7 7 0 018 1zm3.03 4.97a.75.75 0 00-1.06 0L7 8.94 5.53 7.47a.75.75 0 10-1.06 1.06l2 2a.75.75 0 001.06 0l3.5-3.5a.75.75 0 000-1.06z" /></svg>
                      Evidence available
                    </>
                  ) : (
                    <>
                      <svg className="h-3 w-3" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a7 7 0 110 14A7 7 0 018 1zM5.47 5.47a.75.75 0 011.06 0L8 6.94l1.47-1.47a.75.75 0 111.06 1.06L9.06 8l1.47 1.47a.75.75 0 11-1.06 1.06L8 9.06l-1.47 1.47a.75.75 0 01-1.06-1.06L6.94 8 5.47 6.53a.75.75 0 010-1.06z" /></svg>
                      Evidence gap
                    </>
                  )}
                </span>
              </div>
              <p className="mt-2 text-[0.9375rem] font-semibold leading-snug text-foreground">
                {pred.question}
              </p>
              <p className="mt-1.5 text-[0.8125rem] leading-relaxed text-muted-foreground">
                {pred.reasoning}
              </p>
              <p className="mt-1.5 text-[0.8125rem] italic text-foreground/70">
                Suggested action: {pred.suggestedAction}
              </p>
            </div>
            <button
              type="button"
              onClick={() => onRunQuestion(pred.question)}
              className="focus-ring shrink-0 rounded-lg border border-[#00BCFF]/30 bg-[#00BCFF]/5 px-3 py-1.5 text-[0.75rem] font-semibold text-[#00BCFF] transition-all hover:bg-[#00BCFF]/10 active:scale-[0.98]"
            >
              Run this question
            </button>
          </div>
        </div>
      ))}

      <button
        type="button"
        onClick={generatePredictions}
        className="focus-ring rounded-lg border border-border/70 bg-white px-4 py-2 text-[0.8125rem] font-semibold text-muted-foreground transition-all hover:border-[#00BCFF]/50 hover:text-foreground"
      >
        Regenerate predictions
      </button>
    </div>
  )
}
