"use client"

import { useCallback, useEffect, useRef, useState } from "react"

import type { RunCopilotActionState } from "@/app/actions/run-copilot"
import type { BatchCopilotState } from "@/lib/server/copilot/batch-types"
import type { Confidence } from "@/lib/server/copilot/schemas"

// ── Types ──────────────────────────────────────────────────

export type HistoryEntry = {
  id: string
  timestamp: number
  type: "single" | "batch"
  question: string
  questionCount: number
  confidenceLevel: Confidence | null
  confidenceScore: number | null
  evidenceCount: number
  singleState: RunCopilotActionState | null
  batchState: BatchCopilotState | null
}

export type NewHistoryEntry = Omit<HistoryEntry, "id" | "timestamp">

// ── Constants ──────────────────────────────────────────────

const STORAGE_KEY = "copilot-query-history"
const MAX_ENTRIES = 50

// ── Helpers ────────────────────────────────────────────────

function generateId(): string {
  return `h_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`
}

/** Strip heavy fields before serializing to keep localStorage lean. */
function stripHeavyFields(entry: HistoryEntry): HistoryEntry {
  const strip = (state: RunCopilotActionState | null): RunCopilotActionState | null => {
    if (!state?.result) return state
    return {
      ...state,
      result: {
        ...state.result,
        evidence: state.result.evidence.map((hit) => ({
          ...hit,
          document: {
            ...hit.document,
            sourceText: "",
            embedding: null,
          },
        })),
      },
    }
  }

  const stripBatch = (batch: BatchCopilotState | null): BatchCopilotState | null => {
    if (!batch) return batch
    return {
      ...batch,
      results: batch.results.map((r) => ({
        ...r,
        result: r.result
          ? {
              ...r.result,
              evidence: r.result.evidence.map((hit) => ({
                ...hit,
                document: {
                  ...hit.document,
                  sourceText: "",
                  embedding: null,
                },
              })),
            }
          : null,
      })),
    }
  }

  return {
    ...entry,
    singleState: strip(entry.singleState),
    batchState: stripBatch(entry.batchState),
  }
}

function readFromStorage(): HistoryEntry[] {
  if (typeof window === "undefined") return []
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw) as HistoryEntry[]
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

function writeToStorage(entries: HistoryEntry[]): void {
  if (typeof window === "undefined") return
  const data = JSON.stringify(entries)
  try {
    localStorage.setItem(STORAGE_KEY, data)
  } catch {
    // QuotaExceededError — evict oldest entries and retry
    const trimmed = entries.slice(0, Math.max(1, entries.length - 5))
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(trimmed))
    } catch {
      // Give up silently
    }
  }
}

// ── Relative time formatting ───────────────────────────────

export function formatRelativeTime(timestamp: number): string {
  const seconds = Math.floor((Date.now() - timestamp) / 1000)
  if (seconds < 60) return "just now"
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  if (days === 1) return "yesterday"
  if (days < 7) return `${days}d ago`
  return new Date(timestamp).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  })
}

// ── Hook ───────────────────────────────────────────────────

export function useQueryHistory() {
  const [entries, setEntries] = useState<HistoryEntry[]>([])
  const [activeId, setActiveId] = useState<string | null>(null)
  const initialized = useRef(false)

  // Load from localStorage on mount
  useEffect(() => {
    if (!initialized.current) {
      setEntries(readFromStorage())
      initialized.current = true
    }
  }, [])

  // Persist on every change (skip the initial load)
  useEffect(() => {
    if (initialized.current) {
      writeToStorage(entries)
    }
  }, [entries])

  const addEntry = useCallback((data: NewHistoryEntry): string => {
    const id = generateId()
    const entry: HistoryEntry = {
      ...data,
      id,
      timestamp: Date.now(),
    }
    const stripped = stripHeavyFields(entry)

    setEntries((prev) => {
      const next = [stripped, ...prev]
      return next.length > MAX_ENTRIES ? next.slice(0, MAX_ENTRIES) : next
    })
    setActiveId(id)
    return id
  }, [])

  const removeEntry = useCallback(
    (id: string) => {
      setEntries((prev) => prev.filter((e) => e.id !== id))
      if (activeId === id) setActiveId(null)
    },
    [activeId],
  )

  const clearAll = useCallback(() => {
    setEntries([])
    setActiveId(null)
  }, [])

  return {
    entries,
    activeId,
    addEntry,
    removeEntry,
    clearAll,
    setActiveId,
  }
}
