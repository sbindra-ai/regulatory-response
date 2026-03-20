# Query History Sidebar

## Summary

Add a left-side collapsible sidebar using shadcn Sidebar that tracks all copilot queries (single and batch) in the current session, persisted to localStorage. Users can click back to any previous result instantly without re-running the pipeline.

## Motivation

Regulatory teams process 5-20 questions per request. Currently, running a new question discards previous results, forcing wasteful re-execution. A persistent history lets users compare results, revisit earlier analyses, and work through question stacks efficiently.

## Architecture

### New files

- `lib/copilot/query-history.ts` — `HistoryEntry` type and `useQueryHistory` hook
- `components/copilot/query-history-sidebar.tsx` — Sidebar UI component

### Modified files

- `app/page.tsx` — Wrap workbench section with `SidebarProvider`, add sidebar alongside workbench content. ShaderHero and PipelineExplainer remain outside the sidebar layout since they are full-bleed sections. `page.tsx` becomes a client component (or uses a client wrapper) since `SidebarProvider` is a client component.
- `components/copilot/copilot-workbench.tsx` — Accept history callbacks (onSaveEntry, onRestoreEntry), call save after pipeline completes, restore state on entry selection

### Installed components

- `npx shadcn@latest add sidebar` (installs sidebar + required deps like sheet, tooltip, input)

## Data Model

```typescript
import type { RunCopilotActionState } from "@/app/actions/run-copilot"
import type { BatchCopilotState } from "@/lib/server/copilot/batch-types"

type HistoryEntry = {
  id: string
  timestamp: number
  type: "single" | "batch"
  question: string              // single question text, or first question for batch
  questionCount: number         // 1 for single, N for batch
  confidenceLevel: "low" | "medium" | "high" | null
  confidenceScore: number | null
  evidenceCount: number
  singleState: RunCopilotActionState | null
  batchState: BatchCopilotState | null
}
```

localStorage key: `"copilot-query-history"`
Collapsed state key: managed by shadcn SidebarProvider (cookie-based)

Before serializing to localStorage, strip `sourceText` and `embedding` fields from evidence documents to reduce storage size (~60-80% reduction per entry).

## useQueryHistory Hook

```typescript
function useQueryHistory(): {
  entries: HistoryEntry[]
  activeId: string | null
  addEntry(entry: Omit<HistoryEntry, "id" | "timestamp">): string
  removeEntry(id: string): void
  clearAll(): void
  setActiveId(id: string | null): void
}
```

- Reads from localStorage on mount
- Writes to localStorage on every mutation, wrapped in try/catch for `QuotaExceededError` — on overflow, evict oldest entries until write succeeds
- Newest entries first
- Cap at 50 entries, evict oldest on overflow

## Sidebar UI

Uses shadcn Sidebar primitives:
- `Sidebar` with `side="left"` and `collapsible="icon"`
- `SidebarHeader`: "Query History" title + clear all button
- `SidebarContent > SidebarGroup > SidebarGroupContent > SidebarMenu`: list of entries
- `SidebarFooter`: entry count
- `SidebarTrigger`: toggle collapse/expand

Each `SidebarMenuItem` shows:
- Truncated question text (~60 chars)
- Relative timestamp (e.g. "2m ago")
- Confidence badge (color-coded low/medium/high)
- Evidence count pill
- Type indicator (single vs batch with question count)
- Delete button (X) visible on hover
- Active entry gets highlighted background

Collapsed state: Lucide `History` icon with absolute-positioned entry count badge.

## Page Layout Changes

ShaderHero and PipelineExplainer remain outside the sidebar layout (they are full-bleed sections). Only the workbench section is wrapped:

```
ShaderHero
PipelineExplainer
SidebarProvider
  QueryHistorySidebar
  SidebarInset
    CopilotWorkbench
```

`page.tsx` uses a client wrapper component for the SidebarProvider section since it needs client-side state.

## Data Flow

1. User runs copilot (single or batch)
2. Pipeline completes -> workbench calls `addEntry` with result data
3. Entry appears at top of sidebar list, marked as active
4. User clicks a different entry -> `setActiveId` called, workbench restores that entry's state
5. User can delete individual entries or clear all
6. On page refresh, history loads from localStorage, no entry is active
7. When user starts a new copilot run, `activeId` is cleared (no entry appears selected while pipeline is in progress)

## Restoring State

When an entry is selected:
- **Single**: restore `state` (RunCopilotActionState) AND `question` input field state via `setQuestion(entry.singleState.question)` to keep the textarea in sync
- **Batch**: restore `batchState` in workbench, clear single-question state

When user modifies the question input or starts a new run, `activeId` is cleared so the sidebar no longer highlights a stale entry.

The workbench receives a callback `onRestoreEntry(entry: HistoryEntry)` that sets the appropriate state variables.

## Styling

- Sidebar follows the project's existing color scheme (Bayer teal `#10384F`, accent `#00BCFF`)
- Confidence badges reuse the existing color coding from InterpretationPanel
- Transitions use the project's standard `transition-all` patterns
