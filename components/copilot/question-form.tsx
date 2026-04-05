"use client"

import { useEffect, useRef, useState } from "react"

import { extractQuestionsFromImage, extractQuestionsFromPdf } from "@/app/actions/extract-questions"
import { QuestionChecklist } from "@/components/copilot/question-checklist"
import { PipelineStatus } from "@/components/copilot/pipeline-status"
import type { DetectedQuestion } from "@/lib/copilot/question-detection"
import { splitQuestions } from "@/lib/copilot/question-detection"
import type { DemoPrompt } from "@/lib/copilot/demo-prompts"
import { getMgaToken, setMgaToken } from "@/lib/copilot/mga-token"

const DEFAULT_MAX_TOKENS = 64_000
const DEFAULT_TEMPERATURE = 0.7

type QuestionFormProps = {
  error: string | null
  formAction: (payload: FormData) => void
  onInterrupt: () => void
  onRebuild: () => void
  pending: boolean
  question: string
  rebuildResult: { documentCount: number; embeddingCount: number } | null
  rebuilding: boolean
  samplePrompts: DemoPrompt[]
  setQuestion: (question: string) => void
  detectedQuestions: DetectedQuestion[]
  setDetectedQuestions: (questions: DetectedQuestion[]) => void
  onBatchSubmit: (questions: DetectedQuestion[]) => void
  uploadPending: boolean
  setUploadPending: (pending: boolean) => void
}

function PromptChip({
  onSelect,
  prompt,
}: {
  onSelect: (question: string) => void
  prompt: DemoPrompt
}) {
  return (
    <button
      type="button"
      onClick={() => onSelect(prompt.question)}
      className="focus-ring rounded-full border border-border/60 bg-white px-4 py-2 text-left text-[0.8125rem] font-medium text-foreground shadow-[0_1px_2px_rgba(16,56,79,0.06)] transition-all hover:border-[#00BCFF]/50 hover:shadow-[0_2px_8px_rgba(0,188,255,0.12)] active:scale-[0.98]"
    >
      {prompt.label}
    </button>
  )
}

function RunButton({
  pending,
  onInterrupt,
}: {
  pending: boolean
  onInterrupt: () => void
}) {
  return (
    <button
      type="submit"
      onClick={(e) => {
        if (pending) {
          e.preventDefault()
          onInterrupt()
        }
      }}
      className={`focus-ring group relative isolate h-13 w-[12rem] cursor-pointer overflow-hidden whitespace-nowrap rounded-xl px-9 text-base font-bold text-white transition-all duration-500 ease-in-out active:translate-y-[0.5px] focus-visible:outline-2 focus-visible:outline-offset-2 ${pending
          ? "bg-[#b54848] shadow-[0_2px_8px_rgba(181,72,72,0.3)] hover:bg-[#a03e3e] focus-visible:outline-[#b54848]"
          : "bg-[#10384F] shadow-[0_2px_8px_rgba(16,56,79,0.3)] hover:shadow-[0_4px_16px_rgba(16,56,79,0.35)] hover:translate-y-[-1px] focus-visible:outline-[#00BCFF]"
        }`}
    >
      {/* Shimmer layer - fades out when pending */}
      <div
        className={`absolute inset-0 overflow-visible -z-30 blur-[2px] [container-type:size] transition-opacity duration-500 ${pending ? "opacity-0" : "opacity-100"
          }`}
      >
        <div className="animate-shimmer-slide absolute inset-0 h-[100cqh] [aspect-ratio:1] [border-radius:0] [mask:none]">
          <div className="animate-spin-around absolute -inset-full w-auto rotate-0 [background:conic-gradient(from_calc(270deg-(90deg*0.5)),transparent_0,#00BCFF_90deg,transparent_90deg)] [translate:0_0]" />
        </div>
      </div>

      {/* Inner glow - fades out when pending */}
      <div
        className={`pointer-events-none absolute inset-0 rounded-xl shadow-[inset_0_-8px_10px_#ffffff1f] transition-opacity duration-500 ${pending ? "opacity-0" : "opacity-100"
          }`}
      />

      {/* Background fill for shimmer cut */}
      <div
        className={`pointer-events-none absolute -z-20 rounded-[0.75rem] [inset:0.05em] transition-colors duration-500 ${pending ? "bg-[#b54848]" : "bg-[#10384F]"
          }`}
      />

      {/* Content crossfade */}
      <span className="relative flex items-center justify-center">
        <span
          className={`flex items-center gap-2 transition-all duration-300 ${pending
              ? "opacity-100 translate-y-0"
              : "opacity-0 translate-y-2 absolute"
            }`}
        >
          <svg className="h-4 w-4" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
            <rect x="3" y="3" width="10" height="10" rx="1.5" />
          </svg>
          Stop Copilot
        </span>
        <span
          className={`transition-all duration-300 ${pending
              ? "opacity-0 -translate-y-2 absolute"
              : "opacity-100 translate-y-0"
            }`}
        >
          Run Copilot
        </span>
      </span>
    </button>
  )
}

const ACCEPTED_TYPES = new Set([
  "application/pdf",
  "image/png",
  "image/jpeg",
  "image/webp",
])

export function QuestionForm({
  error,
  formAction,
  onInterrupt,
  onRebuild,
  pending,
  question,
  rebuildResult,
  rebuilding,
  samplePrompts,
  setQuestion,
  detectedQuestions,
  setDetectedQuestions,
  onBatchSubmit,
  uploadPending,
  setUploadPending,
}: QuestionFormProps) {
  const [showSettings, setShowSettings] = useState(false)
  const [maxTokens, setMaxTokens] = useState(DEFAULT_MAX_TOKENS)
  const [temperature, setTemperature] = useState(DEFAULT_TEMPERATURE)
  const [mgaToken, setMgaTokenState] = useState("")
  const [uploadError, setUploadError] = useState<string | null>(null)
  const [dragOver, setDragOver] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    setMgaTokenState(getMgaToken())
  }, [])

  // Detect multi-question from textarea content
  const textQuestions = splitQuestions(question)
  const multiQuestionDetected = textQuestions.length > 1

  function applyExtracted(questions: DetectedQuestion[], rawText: string | null) {
    if (questions.length === 0) {
      // No structured questions found - fall back to raw extracted text
      if (rawText?.trim()) setQuestion(rawText.trim())
      return
    }
    if (questions.length === 1) {
      // Single question - put it directly in the textarea
      setQuestion(questions[0].text)
    } else {
      // Multiple questions - show checklist for review
      setDetectedQuestions(questions)
    }
  }

  async function handleFile(file: File) {
    setUploadError(null)
    setUploadPending(true)
    try {
      const formData = new FormData()
      formData.append("file", file)
      if (file.type === "application/pdf") {
        const result = await extractQuestionsFromPdf(formData)
        if (result.error) setUploadError(result.error)
        else applyExtracted(result.questions, result.rawText)
      } else if (file.type.startsWith("image/")) {
        const result = await extractQuestionsFromImage(formData, mgaToken || undefined)
        if (result.error) setUploadError(result.error)
        else applyExtracted(result.questions, result.rawText)
      } else {
        setUploadError("Unsupported file type. Drop a PDF or image (PNG, JPEG, WebP).")
      }
    } finally {
      setUploadPending(false)
    }
  }

  function handlePaste(e: React.ClipboardEvent) {
    const items = e.clipboardData.items
    for (const item of items) {
      if (item.type.startsWith("image/")) {
        e.preventDefault()
        const file = item.getAsFile()
        if (file) handleFile(file)
        return
      }
    }
    // If no image found, let the default paste (text) happen
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault()
    setDragOver(false)
    const file = e.dataTransfer.files[0]
    if (file) handleFile(file)
  }

  function handleDragOver(e: React.DragEvent) {
    e.preventDefault()
    if (e.dataTransfer.types.includes("Files")) setDragOver(true)
  }

  function handleDragLeave(e: React.DragEvent) {
    // Only trigger if leaving the drop zone (not entering a child)
    if (e.currentTarget.contains(e.relatedTarget as Node)) return
    setDragOver(false)
  }

  function handleFileInput(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (file) handleFile(file)
    if (fileInputRef.current) fileInputRef.current.value = ""
  }

  function handleTextMultiSubmit() {
    setDetectedQuestions(textQuestions)
  }

  function handleToggle(id: string) {
    setDetectedQuestions(
      detectedQuestions.map((q) => (q.id === id ? { ...q, selected: !q.selected } : q)),
    )
  }

  function handleToggleAll(selected: boolean) {
    setDetectedQuestions(detectedQuestions.map((q) => ({ ...q, selected })))
  }

  function handleRemove(id: string) {
    const updated = detectedQuestions.filter((q) => q.id !== id)
    if (updated.length === 0) setDetectedQuestions([])
    else setDetectedQuestions(updated)
  }

  function handleConfirm() {
    const selected = detectedQuestions.filter((q) => q.selected)
    if (selected.length > 0) onBatchSubmit(selected)
  }

  function handleCancel() {
    setDetectedQuestions([])
  }

  // Show checklist when questions are detected from upload or multi-question text
  if (detectedQuestions.length > 1) {
    return (
      <div className="intake-shell space-y-4">
        <QuestionChecklist
          questions={detectedQuestions}
          onToggle={handleToggle}
          onToggleAll={handleToggleAll}
          onRemove={handleRemove}
          onConfirm={handleConfirm}
          onCancel={handleCancel}
          pending={pending}
          source={detectedQuestions[0]?.source ?? "text"}
        />
      </div>
    )
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        formAction(new FormData(e.currentTarget))
      }}
      className="intake-shell"
    >
      <input type="hidden" name="maxTokens" value={maxTokens} />
      <input type="hidden" name="temperature" value={temperature} />
      <input type="hidden" name="mgaToken" value={mgaToken} />
      <input
        ref={fileInputRef}
        type="file"
        accept=".pdf,image/png,image/jpeg,image/webp"
        onChange={handleFileInput}
        className="hidden"
      />

      {!mgaToken && (
        <div className="flex items-start gap-3 rounded-xl border border-amber-200 bg-amber-50 px-5 py-4 shadow-sm">
          <svg className="mt-0.5 h-5 w-5 shrink-0 text-amber-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fillRule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.168 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 6a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 6zm0 9a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
          </svg>
          <div>
            <p className="text-sm font-semibold text-amber-800">MGA Token not configured</p>
            <p className="mt-0.5 text-sm text-amber-700">
              The copilot requires a myGenAssist token to call the AI API. Open{" "}
              <button type="button" onClick={() => setShowSettings(true)} className="font-semibold underline underline-offset-2 hover:text-amber-900">Settings</button>
              {" "}and paste your token to get started.
            </p>
          </div>
        </div>
      )}

      <div className="grid gap-8 xl:grid-cols-2">
        {/* Left: input area */}
        <div className="space-y-5">
          {/* Textarea with drag-and-drop */}
          <div
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            className="relative"
          >
            <textarea
              name="question"
              value={question}
              onChange={(event) => setQuestion(event.target.value)}
              onPaste={handlePaste}
              placeholder="Type or paste questions here - you can also paste a screenshot, or drag & drop a PDF / image…"
              className={`focus-ring min-h-48 w-full resize-y rounded-xl border bg-white px-5 py-4 text-[0.9375rem] leading-relaxed text-foreground shadow-[0_1px_3px_rgba(16,56,79,0.04),0_4px_16px_-6px_rgba(16,56,79,0.06)] outline-none transition-all placeholder:text-muted-foreground/50 focus:border-[#00BCFF]/50 focus:shadow-[0_0_0_3px_rgba(0,188,255,0.08),0_1px_3px_rgba(16,56,79,0.04)] ${dragOver
                  ? "border-[#00BCFF] bg-[#00BCFF]/[0.03] shadow-[0_0_0_3px_rgba(0,188,255,0.12)]"
                  : "border-border/70"
                }`}
            />

            {/* Drag overlay */}
            {dragOver && (
              <div className="pointer-events-none absolute inset-0 flex items-center justify-center rounded-xl border-2 border-dashed border-[#00BCFF]/60 bg-[#00BCFF]/[0.06]">
                <div className="flex items-center gap-2 rounded-lg bg-white/90 px-4 py-2 shadow-sm">
                  <svg className="h-5 w-5 text-[#00BCFF]" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M8 10V2M8 2L5 5M8 2l3 3" />
                    <path d="M2 10v2.5A1.5 1.5 0 003.5 14h9a1.5 1.5 0 001.5-1.5V10" />
                  </svg>
                  <span className="text-[0.875rem] font-semibold text-[#00BCFF]">
                    Drop PDF or image
                  </span>
                </div>
              </div>
            )}

            {/* Upload processing indicator */}
            {uploadPending && (
              <div className="pointer-events-none absolute inset-0 flex items-center justify-center rounded-xl bg-white/70">
                <div className="flex items-center gap-2 rounded-lg bg-white px-4 py-2 shadow-md">
                  <span className="inline-block h-3 w-3 animate-spin rounded-full border-2 border-[#00BCFF] border-t-transparent" />
                  <span className="text-[0.875rem] font-medium text-foreground">
                    Extracting questions…
                  </span>
                </div>
              </div>
            )}

            {/* Bottom bar inside textarea area */}
            {!dragOver && !uploadPending && !question && (
              <div className="pointer-events-none absolute bottom-3 left-0 right-0 flex justify-center">
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="pointer-events-auto flex items-center gap-1.5 rounded-full border border-border/50 bg-white/90 px-3 py-1.5 text-[0.75rem] font-medium text-muted-foreground shadow-sm transition-all hover:border-[#00BCFF]/40 hover:text-foreground"
                >
                  <svg className="h-3.5 w-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M8 10V2M8 2L5 5M8 2l3 3" />
                    <path d="M2 10v2.5A1.5 1.5 0 003.5 14h9a1.5 1.5 0 001.5-1.5V10" />
                  </svg>
                  or browse for a PDF / image
                </button>
              </div>
            )}
          </div>

          {/* Multi-question badge */}
          {multiQuestionDetected && (
            <button
              type="button"
              onClick={handleTextMultiSubmit}
              className="inline-flex items-center gap-1.5 rounded-full border border-[#00BCFF]/30 bg-[#00BCFF]/5 px-3 py-1.5 text-[0.8125rem] font-medium text-[#00BCFF] transition-all hover:bg-[#00BCFF]/10"
            >
              <svg className="h-3.5 w-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                <path d="M2 4h12M2 8h12M2 12h8" />
              </svg>
              {textQuestions.length} questions detected - click to review
            </button>
          )}

          <div className="flex flex-wrap items-center gap-3">
            <RunButton pending={pending} onInterrupt={onInterrupt} />
            <button
              type="button"
              disabled={rebuilding}
              onClick={onRebuild}
              className="focus-ring h-13 cursor-pointer rounded-xl border border-border/70 bg-white px-6 text-[0.875rem] font-semibold text-foreground shadow-[0_1px_3px_rgba(16,56,79,0.06)] transition-all hover:border-[#00BCFF]/50 hover:shadow-[0_2px_8px_rgba(0,188,255,0.1)] active:scale-[0.98] disabled:pointer-events-none disabled:opacity-60"
            >
              {rebuilding ? "Rebuilding\u2026" : "Rebuild Knowledge Base"}
            </button>
            <button
              type="button"
              onClick={() => setShowSettings((prev) => !prev)}
              className="focus-ring h-13 cursor-pointer rounded-xl border border-border/70 bg-white px-4 text-[0.875rem] font-semibold text-muted-foreground shadow-[0_1px_3px_rgba(16,56,79,0.06)] transition-all hover:border-[#00BCFF]/50 hover:text-foreground hover:shadow-[0_2px_8px_rgba(0,188,255,0.1)] active:scale-[0.98]"
              title="Model settings"
            >
              <span className="flex items-center gap-1.5">
                <svg className="h-4 w-4" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" aria-hidden="true">
                  <path d="M8 1v2M8 13v2M1 8h2M13 8h2M3.05 3.05l1.41 1.41M11.54 11.54l1.41 1.41M3.05 12.95l1.41-1.41M11.54 4.46l1.41-1.41" />
                  <circle cx="8" cy="8" r="2.5" />
                </svg>
                Settings
                <svg className={`h-3 w-3 transition-transform ${showSettings ? "rotate-180" : ""}`} viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                  <path d="M3 4.5l3 3 3-3" />
                </svg>
              </span>
            </button>
            {rebuildResult && (
              <span className="text-[0.75rem] tabular-nums text-muted-foreground">
                {rebuildResult.documentCount} docs, {rebuildResult.embeddingCount} embedded
              </span>
            )}
            {pending ? <PipelineStatus /> : null}
          </div>

          {/* Model settings panel */}
          {showSettings && (
            <div className="animate-in rounded-xl border border-border/60 bg-white px-5 py-4 shadow-[0_1px_3px_rgba(16,56,79,0.04)]">
              <p className="mb-3 text-[0.8125rem] font-bold text-foreground/70">Model Settings</p>
              <div className="grid gap-5 sm:grid-cols-2">
                {/* MGA Token */}
                <label className="block space-y-1.5 sm:col-span-2">
                  <span className="text-[0.75rem] font-semibold text-muted-foreground">
                    MGA Token
                  </span>
                  <input
                    type="password"
                    value={mgaToken}
                    onChange={(e) => {
                      setMgaTokenState(e.target.value)
                      setMgaToken(e.target.value)
                    }}
                    placeholder="Paste your myGenAssist token here"
                    className="focus-ring block w-full rounded-lg border border-border/70 bg-muted/30 px-3 py-2 text-sm font-mono text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-[#00BCFF]/50"
                  />
                  <span className="block text-[0.6875rem] text-muted-foreground">
                    Your MGA bearer token for the Bayer AI API. Stored locally in your browser only.
                  </span>
                </label>

                {/* Max Tokens */}
                <label className="block space-y-1.5">
                  <span className="text-[0.75rem] font-semibold text-muted-foreground">
                    Max Tokens
                  </span>
                  <input
                    type="number"
                    min={1000}
                    max={128_000}
                    step={1000}
                    value={maxTokens}
                    onChange={(e) => setMaxTokens(Number(e.target.value))}
                    className="focus-ring block w-full rounded-lg border border-border/70 bg-muted/30 px-3 py-2 text-sm tabular-nums text-foreground outline-none transition-colors focus:border-[#00BCFF]/50"
                  />
                  <span className="block text-[0.6875rem] text-muted-foreground">
                    Maximum output tokens per LLM call (1k{"\u2013"}128k)
                  </span>
                </label>

                {/* Temperature */}
                <label className="block space-y-1.5">
                  <span className="text-[0.75rem] font-semibold text-muted-foreground">
                    Temperature: {temperature.toFixed(2)}
                  </span>
                  <input
                    type="range"
                    min={0}
                    max={2}
                    step={0.05}
                    value={temperature}
                    onChange={(e) => setTemperature(Number(e.target.value))}
                    className="block w-full accent-[#00BCFF]"
                  />
                  <span className="flex justify-between text-[0.6875rem] text-muted-foreground">
                    <span>Precise (0)</span>
                    <span>Creative (2)</span>
                  </span>
                </label>
              </div>
            </div>
          )}

          {(error || uploadError) && (
            <div className="rounded-xl border border-destructive/20 bg-[color-mix(in_srgb,var(--destructive)_4%,white)] px-5 py-4 shadow-sm">
              <p className="text-sm font-semibold text-destructive">
                {uploadError ? "Upload failed" : "Unable to build grounded plan"}
              </p>
              <p className="mt-1.5 text-sm text-foreground">{uploadError ?? error}</p>
              <p className="mt-1 text-sm text-muted-foreground">
                {uploadError
                  ? "Try a different file or paste questions directly."
                  : "Try editing your question or selecting a sample prompt."}
              </p>
            </div>
          )}
        </div>

        {/* Right: sample prompts */}
        <aside className="space-y-4">
          <div>
            <p className="font-heading text-[0.8125rem] font-bold tracking-wide text-foreground/70 uppercase">
              Sample prompts
            </p>
            <p className="mt-1 text-sm leading-snug text-muted-foreground">
              Pick one to get started quickly with a supported evidence family.
            </p>
          </div>
          <div className="flex flex-wrap gap-2.5">
            {samplePrompts.map((prompt) => (
              <PromptChip key={prompt.id} prompt={prompt} onSelect={setQuestion} />
            ))}
          </div>
        </aside>
      </div>
    </form>
  )
}
