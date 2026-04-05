"use client"

import { History, Layers, Search, Trash2, X } from "lucide-react"

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuAction,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
  SidebarSeparator,
  useSidebar,
} from "@/components/ui/sidebar"
import type { HistoryEntry } from "@/lib/copilot/query-history"
import { formatRelativeTime } from "@/lib/copilot/query-history"

// ── Confidence indicator ───────────────────────────────────

const confidenceConfig = {
  high: {
    label: "High",
    dot: "bg-emerald-500",
    text: "text-emerald-600",
  },
  medium: {
    label: "Med",
    dot: "bg-amber-500",
    text: "text-amber-600",
  },
  low: {
    label: "Low",
    dot: "bg-red-500",
    text: "text-red-600",
  },
} as const

function ConfidenceIndicator({ level }: { level: "low" | "medium" | "high" | null }) {
  if (!level) return null
  const config = confidenceConfig[level]
  return (
    <span className={`inline-flex items-center gap-1 ${config.text}`}>
      <span className={`h-1.5 w-1.5 rounded-full ${config.dot}`} />
      <span className="text-[0.5625rem] font-semibold leading-none tracking-wide">
        {config.label}
      </span>
    </span>
  )
}

// ── Single history item ────────────────────────────────────

function HistoryItem({
  entry,
  isActive,
  onSelect,
  onRemove,
}: {
  entry: HistoryEntry
  isActive: boolean
  onSelect: (entry: HistoryEntry) => void
  onRemove: (id: string) => void
}) {
  const truncated =
    entry.question.length > 55
      ? `${entry.question.slice(0, 52)}\u2026`
      : entry.question

  return (
    <SidebarMenuItem>
      <SidebarMenuButton
        isActive={isActive}
        onClick={() => onSelect(entry)}
        tooltip={entry.question}
        className={`h-auto items-start gap-2.5 rounded-lg py-2.5 pl-3 pr-7 transition-all ${
          isActive
            ? "border-l-2 border-l-[#0a7ccf] bg-[#e7f0f8] pl-[0.625rem]"
            : "border-l-2 border-l-transparent"
        }`}
      >
        <div className="mt-[3px] flex h-5 w-5 shrink-0 items-center justify-center rounded bg-sidebar-foreground/[0.06]">
          {entry.type === "batch" ? (
            <Layers className="size-3 text-sidebar-foreground/50" />
          ) : (
            <Search className="size-3 text-sidebar-foreground/50" />
          )}
        </div>
        <div className="flex min-w-0 flex-col gap-1.5">
          <span className="text-[0.8125rem] leading-[1.35] font-medium text-sidebar-foreground/90">
            {truncated}
          </span>
          <div className="flex items-center gap-2">
            <span className="text-[0.625rem] tabular-nums text-sidebar-foreground/40">
              {formatRelativeTime(entry.timestamp)}
            </span>
            <ConfidenceIndicator level={entry.confidenceLevel} />
            {entry.evidenceCount > 0 && (
              <span className="inline-flex items-center gap-0.5 text-[0.5625rem] tabular-nums text-sidebar-foreground/40">
                <span className="font-semibold text-sidebar-primary">{entry.evidenceCount}</span>
                <span>ev</span>
              </span>
            )}
            {entry.type === "batch" && (
              <span className="inline-flex items-center gap-0.5 text-[0.5625rem] tabular-nums text-sidebar-foreground/40">
                <span className="font-semibold">{entry.questionCount}</span>
                <span>qs</span>
              </span>
            )}
          </div>
        </div>
      </SidebarMenuButton>
      <SidebarMenuAction
        showOnHover
        onClick={(e) => {
          e.stopPropagation()
          onRemove(entry.id)
        }}
        title="Remove from history"
        className="opacity-0 transition-opacity group-hover/menu-item:opacity-100"
      >
        <X className="size-3.5" />
      </SidebarMenuAction>
    </SidebarMenuItem>
  )
}

// ── Empty state ────────────────────────────────────────────

function EmptyState() {
  return (
    <div className="px-3 py-8">
      <div className="flex flex-col gap-4">
        <div className="mx-auto flex h-9 w-9 items-center justify-center rounded-md border border-sidebar-border bg-sidebar">
          <History className="h-4 w-4 text-sidebar-foreground/30" />
        </div>
        <div className="space-y-1 text-center">
          <p className="font-heading text-[0.8125rem] font-semibold text-sidebar-foreground/60">
            No queries yet
          </p>
          <p className="text-[0.6875rem] leading-relaxed text-sidebar-foreground/35">
            Results from each copilot run appear here for quick access.
          </p>
        </div>
        <div className="mx-auto flex items-center gap-1.5 text-[0.625rem] text-sidebar-foreground/25">
          <kbd className="rounded border border-sidebar-border bg-sidebar px-1 py-px font-mono text-[0.5625rem]">\u2318B</kbd>
          <span>to toggle</span>
        </div>
      </div>
    </div>
  )
}

// ── Collapsed icon with count badge ────────────────────────

function CollapsedBadge({ count }: { count: number }) {
  const { state } = useSidebar()
  if (state !== "collapsed" || count === 0) return null

  return (
    <div className="absolute -right-1 -top-1 flex h-3.5 min-w-3.5 items-center justify-center rounded-full bg-[#0a7ccf] px-0.5 text-[0.5rem] font-bold tabular-nums text-white shadow-sm">
      {count > 99 ? "99+" : count}
    </div>
  )
}

// ── Main sidebar ───────────────────────────────────────────

type QueryHistorySidebarProps = {
  entries: HistoryEntry[]
  activeId: string | null
  onSelect: (entry: HistoryEntry) => void
  onRemove: (id: string) => void
  onClearAll: () => void
}

export function QueryHistorySidebar({
  entries,
  activeId,
  onSelect,
  onRemove,
  onClearAll,
}: QueryHistorySidebarProps) {
  return (
    <Sidebar side="left" collapsible="icon">
      <SidebarHeader>
        <div className="flex items-center gap-2.5 px-1 py-0.5">
          <div className="relative">
            <History className="h-4 w-4 text-sidebar-foreground/50" />
            <CollapsedBadge count={entries.length} />
          </div>
          <span className="font-heading text-[0.8125rem] font-bold tracking-tight text-sidebar-foreground">
            Query History
          </span>
          {entries.length > 0 && (
            <span className="ml-auto inline-flex h-4.5 min-w-4.5 items-center justify-center rounded-full bg-sidebar-foreground/[0.07] px-1 text-[0.5625rem] font-semibold tabular-nums text-sidebar-foreground/50">
              {entries.length}
            </span>
          )}
        </div>
      </SidebarHeader>

      <SidebarSeparator />

      <SidebarContent>
        <SidebarGroup className="px-1.5">
          <SidebarGroupContent>
            {entries.length === 0 ? (
              <EmptyState />
            ) : (
              <SidebarMenu className="gap-0.5">
                {entries.map((entry) => (
                  <HistoryItem
                    key={entry.id}
                    entry={entry}
                    isActive={entry.id === activeId}
                    onSelect={onSelect}
                    onRemove={onRemove}
                  />
                ))}
              </SidebarMenu>
            )}
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarSeparator />

      <SidebarFooter>
        <div className="flex items-center justify-between px-1.5 py-0.5">
          <span className="text-[0.625rem] text-sidebar-foreground/30">
            {entries.length === 0
              ? "Session history"
              : `${entries.length} ${entries.length === 1 ? "query" : "queries"} this session`}
          </span>
          {entries.length > 0 && (
            <button
              type="button"
              onClick={onClearAll}
              className="flex items-center gap-1 rounded px-1.5 py-0.5 text-[0.625rem] text-sidebar-foreground/30 transition-colors hover:bg-red-50 hover:text-red-500"
              title="Clear all history"
            >
              <Trash2 className="h-2.5 w-2.5" />
              Clear
            </button>
          )}
        </div>
      </SidebarFooter>

      <SidebarRail />
    </Sidebar>
  )
}
