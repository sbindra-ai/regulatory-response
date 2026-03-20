"use client"

import { useCallback, useRef } from "react"

import { CopilotWorkbench, type CopilotWorkbenchHandle } from "@/components/copilot/copilot-workbench"
import { KnowledgeBaseStats } from "@/components/copilot/knowledge-base-stats"
import { QueryHistorySidebar } from "@/components/copilot/query-history-sidebar"
import { PipelineExplainer } from "@/components/pipeline-explainer"
import { ShaderHero } from "@/components/shader-hero"
import { SidebarInset, SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar"
import { useQueryHistory } from "@/lib/copilot/query-history"
import type { HistoryEntry } from "@/lib/copilot/query-history"

export default function Home() {
  const history = useQueryHistory()
  const workbenchRef = useRef<CopilotWorkbenchHandle>(null)

  const handleSelectEntry = useCallback(
    (entry: HistoryEntry) => {
      history.setActiveId(entry.id)
      workbenchRef.current?.restoreFromHistory(entry)
    },
    [history],
  )

  const handleClearActiveId = useCallback(() => {
    history.setActiveId(null)
  }, [history])

  return (
    <main className="min-h-screen">
      <ShaderHero />

      {/* Sidebar + content layout */}
      <SidebarProvider defaultOpen className="workbench-layout">
        <QueryHistorySidebar
          entries={history.entries}
          activeId={history.activeId}
          onSelect={handleSelectEntry}
          onRemove={history.removeEntry}
          onClearAll={history.clearAll}
        />
        <SidebarInset>
          <div className="flex h-10 shrink-0 items-center px-3">
            <SidebarTrigger />
          </div>
          <PipelineExplainer />
          <KnowledgeBaseStats />
          <section className="mx-auto w-full max-w-[86rem] px-5 py-8 sm:px-8 lg:px-10">
            <CopilotWorkbench
              ref={workbenchRef}
              onSaveEntry={history.addEntry}
              onClearActiveId={handleClearActiveId}
            />
          </section>
        </SidebarInset>
      </SidebarProvider>
    </main>
  )
}
