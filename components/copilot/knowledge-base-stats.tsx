"use client"

import { useEffect, useState } from "react"
import {
  Database,
  FileCode,
  FileText,
  FlaskConical,
  Layers,
  ScrollText,
} from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { getCorpusStats, type CorpusStats } from "@/app/actions/get-corpus-stats"

const sourceTypeLabels: Record<string, { label: string; icon: typeof Database }> = {
  program: { label: "SAS Programs", icon: FileCode },
  "tlf-spec": { label: "TLF Specs", icon: ScrollText },
  "ads-spec": { label: "ADS Specs", icon: FileText },
  "sap-section": { label: "SAP Sections", icon: FlaskConical },
  dataset: { label: "ADaM Datasets", icon: Database },
  "adrg-section": { label: "ADRG Sections", icon: FileText },
  "fda-request": { label: "FDA Requests", icon: ScrollText },
  brief: { label: "Study Brief", icon: Layers },
  "case-data": { label: "Case Data", icon: FileText },
}

export function KnowledgeBaseStats() {
  const [stats, setStats] = useState<CorpusStats | null>(null)

  useEffect(() => {
    getCorpusStats().then(setStats)
  }, [])

  if (!stats) {
    return (
      <section className="border-b border-border bg-muted/30">
        <div className="mx-auto w-full max-w-[86rem] px-5 py-6 sm:px-8 lg:px-10">
          <div className="h-20 animate-pulse rounded-lg bg-muted" />
        </div>
      </section>
    )
  }

  // Sort types by count descending for display
  const sortedTypes = Object.entries(stats.documentsByType).sort(
    ([, a], [, b]) => b - a,
  )

  return (
    <section className="border-b border-border bg-muted/30">
      <div className="mx-auto w-full max-w-[86rem] px-5 py-6 sm:px-8 lg:px-10">
        <div className="flex items-center gap-2">
          <Database className="h-4 w-4 text-primary/70" />
          <p className="font-heading text-[0.6875rem] font-semibold uppercase tracking-[0.12em] text-muted-foreground">
            Knowledge base
          </p>
        </div>

        {/* Top-level stats */}
        <div className="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-4">
          <StatCard
            label="Total documents"
            value={stats.totalDocuments}
          />
          <StatCard
            label="ADaM datasets"
            value={stats.datasetsCount}
          />
          <StatCard
            label="SAS programs"
            value={stats.programsCount}
          />
          <StatCard
            label="With embeddings"
            value={stats.documentsWithEmbeddings}
          />
        </div>

        {/* Document breakdown by type */}
        <div className="mt-4 flex flex-wrap items-center gap-2">
          {sortedTypes.map(([type, count]) => {
            const meta = sourceTypeLabels[type]
            const Icon = meta?.icon ?? FileText
            return (
              <Badge
                key={type}
                variant="outline"
                className="gap-1.5 py-1 text-[0.75rem] font-medium text-muted-foreground"
              >
                <Icon className="h-3 w-3" />
                {meta?.label ?? type}
                <span className="ml-0.5 font-bold tabular-nums text-foreground">
                  {count}
                </span>
              </Badge>
            )
          })}
        </div>

        {/* Referenced datasets */}
        <div className="mt-3 flex flex-wrap items-center gap-1.5">
          <span className="mr-1 text-[0.6875rem] font-medium text-muted-foreground">
            Referenced datasets:
          </span>
          {stats.uniqueDatasetNames.map((name) => (
            <Badge
              key={name}
              variant="secondary"
              className="px-2 py-0 text-[0.6875rem] font-mono"
            >
              {name}
            </Badge>
          ))}
        </div>
      </div>
    </section>
  )
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-lg border border-border/60 bg-card px-4 py-3">
      <p className="text-2xl font-bold tabular-nums text-foreground">
        {value.toLocaleString()}
      </p>
      <p className="mt-0.5 text-[0.75rem] text-muted-foreground">{label}</p>
    </div>
  )
}
