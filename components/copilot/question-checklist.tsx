"use client"

import type { DetectedQuestion } from "@/lib/copilot/question-detection"

type QuestionChecklistProps = {
  questions: DetectedQuestion[]
  onToggle: (id: string) => void
  onToggleAll: (selected: boolean) => void
  onRemove: (id: string) => void
  onConfirm: () => void
  onCancel: () => void
  pending: boolean
  source: "text" | "pdf" | "image"
}

const sourceLabels: Record<string, string> = {
  text: "pasted text",
  pdf: "uploaded PDF",
  image: "uploaded image",
}

export function QuestionChecklist({
  questions,
  onToggle,
  onToggleAll,
  onRemove,
  onConfirm,
  onCancel,
  pending,
  source,
}: QuestionChecklistProps) {
  const selectedCount = questions.filter((q) => q.selected).length
  const allSelected = selectedCount === questions.length

  return (
    <div className="rounded-xl border border-border/70 bg-white px-5 py-4 shadow-[0_1px_3px_rgba(16,56,79,0.04),0_4px_16px_-6px_rgba(16,56,79,0.06)]">
      <div className="mb-3 flex items-center justify-between">
        <p className="text-[0.875rem] font-bold text-foreground">
          {questions.length} question{questions.length !== 1 ? "s" : ""} detected from{" "}
          {sourceLabels[source] ?? source}
        </p>
        <button
          type="button"
          onClick={() => onToggleAll(!allSelected)}
          className="text-[0.8125rem] font-medium text-[#00BCFF] hover:underline"
        >
          {allSelected ? "Deselect All" : "Select All"}
        </button>
      </div>

      <div className="max-h-80 space-y-1.5 overflow-y-auto">
        {questions.map((q, idx) => (
          <label
            key={q.id}
            className="flex items-start gap-3 rounded-lg px-2 py-2 transition-colors hover:bg-muted/40"
          >
            <input
              type="checkbox"
              checked={q.selected}
              onChange={() => onToggle(q.id)}
              className="mt-0.5 h-4 w-4 shrink-0 accent-[#00BCFF]"
            />
            <span className="min-w-0 flex-1 text-[0.8125rem] leading-snug text-foreground">
              <span className="font-semibold text-muted-foreground">Q{idx + 1}:</span>{" "}
              {q.text.length > 120 ? `${q.text.slice(0, 120)}…` : q.text}
            </span>
            <button
              type="button"
              onClick={(e) => {
                e.preventDefault()
                onRemove(q.id)
              }}
              className="shrink-0 text-muted-foreground/50 hover:text-destructive"
              title="Remove question"
            >
              <svg className="h-4 w-4" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                <path d="M4 4l8 8M12 4l-8 8" />
              </svg>
            </button>
          </label>
        ))}
      </div>

      <div className="mt-4 flex items-center gap-3">
        <button
          type="button"
          onClick={onConfirm}
          disabled={pending || selectedCount === 0}
          className="focus-ring h-11 cursor-pointer rounded-xl bg-[#10384F] px-6 text-[0.875rem] font-bold text-white shadow-[0_2px_8px_rgba(16,56,79,0.3)] transition-all hover:translate-y-[-1px] hover:shadow-[0_4px_16px_rgba(16,56,79,0.35)] active:translate-y-[0.5px] disabled:pointer-events-none disabled:opacity-60"
        >
          {pending
            ? "Running…"
            : `Run Copilot on ${selectedCount} selected`}
        </button>
        <button
          type="button"
          onClick={onCancel}
          className="text-[0.8125rem] font-medium text-muted-foreground hover:text-foreground hover:underline"
        >
          Cancel
        </button>
      </div>
    </div>
  )
}
