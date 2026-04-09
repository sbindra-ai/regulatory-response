"use client"

import { useCallback, useEffect, useState, type ReactNode } from "react"
import {
  ChevronDown,
  Database,
  FileCode,
  FileText,
  FlaskConical,
  Layers,
  ScrollText,
  Server,
} from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { getCorpusStats, type CorpusStats } from "@/app/actions/get-corpus-stats"
import { NETWORK_CORPUS_REBUILT_EVENT } from "@/lib/copilot/network-corpus-events"
import type { EvidencePool } from "@/lib/server/copilot/schemas"

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
  "network-file": { label: "Network files", icon: Server },
}

type BucketKey = "total" | "analysis" | "sas"

function KnowledgeBucket({
  label,
  value,
  open,
  onToggle,
  children,
}: {
  label: string
  value: number
  open: boolean
  onToggle: () => void
  children: ReactNode
}) {
  return (
    <div className="flex min-h-0 flex-col rounded-lg border border-border/60 bg-card shadow-sm">
      <button
        type="button"
        onClick={onToggle}
        className="flex w-full items-start justify-between gap-2 px-4 py-3 text-left transition-colors hover:bg-muted/35"
      >
        <div className="min-w-0 flex-1">
          <p className="text-[0.75rem] font-medium leading-snug text-muted-foreground">{label}</p>
          {!open ? (
            <p className="mt-1 text-[0.6875rem] text-muted-foreground/90">Click to list all matching items</p>
          ) : null}
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <p className="text-2xl font-bold tabular-nums text-[#10384F]">{value.toLocaleString()}</p>
          <ChevronDown
            className={`h-4 w-4 shrink-0 text-muted-foreground transition-transform ${open ? "rotate-180" : ""}`}
            aria-hidden
          />
        </div>
      </button>
      {open ? (
        <div className="min-h-0 flex-1 border-t border-border/50">
          <div className="max-h-72 overflow-auto p-3">{children}</div>
        </div>
      ) : null}
    </div>
  )
}

export function KnowledgeBaseStats() {
  const [pool, setPool] = useState<EvidencePool>("repository")
  const [stats, setStats] = useState<CorpusStats | null>(null)
  const [openBucket, setOpenBucket] = useState<BucketKey | null>(null)

  const load = useCallback((p: EvidencePool) => {
    setStats(null)
    getCorpusStats(p).then(setStats)
  }, [])

  useEffect(() => {
    load(pool)
  }, [pool, load])

  useEffect(() => {
    function onNetworkRebuilt() {
      load(pool)
    }
    window.addEventListener(NETWORK_CORPUS_REBUILT_EVENT, onNetworkRebuilt)
    return () => window.removeEventListener(NETWORK_CORPUS_REBUILT_EVENT, onNetworkRebuilt)
  }, [pool, load])

  function toggleBucket(key: BucketKey) {
    setOpenBucket((cur) => (cur === key ? null : key))
  }

  if (!stats) {
    return (
      <section className="border-b border-border bg-muted/30">
        <div className="mx-auto w-full max-w-[86rem] px-5 py-6 sm:px-8 lg:px-10">
          <div className="h-20 animate-pulse rounded-lg bg-muted" />
        </div>
      </section>
    )
  }

  const sortedTypes = Object.entries(stats.documentsByType).sort(([, a], [, b]) => b - a)
  const networkFileCount = stats.documentsByType["network-file"] ?? 0
  const isPlaceholderNetwork =
    pool === "network" && networkFileCount === 0 && stats.totalDocuments <= 1

  const analysisLabel =
    pool === "repository" ? "Analysis data set (define.xml)" : "Analysis data set (.sas7bdat / .xpt)"

  return (
    <section className="border-b border-border bg-muted/30">
      <div className="mx-auto w-full max-w-[86rem] px-5 py-6 sm:px-8 lg:px-10">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <Database className="h-4 w-4 text-primary/70" />
            <p className="font-heading text-[0.6875rem] font-semibold uppercase tracking-[0.12em] text-muted-foreground">
              Knowledge base
            </p>
          </div>
          <div className="flex rounded-lg border border-border/70 bg-card p-0.5 text-[0.75rem] font-semibold">
            <button
              type="button"
              onClick={() => setPool("repository")}
              className={`rounded-md px-3 py-1.5 transition-colors ${
                pool === "repository" ? "bg-[#10384F] text-white shadow-sm" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              Repository
            </button>
            <button
              type="button"
              onClick={() => setPool("network")}
              className={`rounded-md px-3 py-1.5 transition-colors ${
                pool === "network" ? "bg-[#10384F] text-white shadow-sm" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              Network share
            </button>
          </div>
        </div>

        {isPlaceholderNetwork ? (
          <div className="mt-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-[0.8125rem] leading-relaxed text-amber-950">
            <p className="font-semibold text-amber-900">Network index not built yet</p>
            <p className="mt-1 text-amber-900/90">
              This is the repo placeholder: one brief, no share files. Retrieval only reads{" "}
              <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">evidence-corpus.network.json</code>
              —nothing is queried live on the share.
            </p>
            <ol className="mt-2 list-decimal space-y-1 pl-5 text-amber-900/90">
              <li>
                Under <span className="font-semibold">Knowledge retrieval</span>, choose{" "}
                <span className="font-semibold">Network share</span>.
              </li>
              <li>
                Set <span className="font-semibold">Network scan root</span> to a folder the{" "}
                <span className="font-semibold">same Windows account that runs</span>{" "}
                <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">next dev</code> /{" "}
                <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">next start</code> can read (e.g.{" "}
                <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">X:\study\...</code>). Mapped
                drives are per-user; a path that works in Explorer may not work for the Node process if it runs as a
                service.
              </li>
              <li>
                Click <span className="font-semibold">Rebuild network index</span>. If it fails, read the red error
                above the button (wrong path, VPN, or no{" "}
                <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">.sas</code> /{" "}
                <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">.txt</code> /{" "}
                <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">.pdf</code> / transport files
                under that root).
              </li>
              <li>
                After success, counts here update automatically. <span className="font-semibold">Keyword-only</span>{" "}
                means rebuild without{" "}
                <code className="rounded bg-amber-100/80 px-1 font-mono text-[0.7rem]">MGA_TOKEN</code> in the server
                environment; set it and rebuild again for vector ranking.
              </li>
            </ol>
          </div>
        ) : null}

        <div className="mt-4 grid min-h-0 items-stretch gap-4 lg:grid-cols-3">
          <KnowledgeBucket
            label="Total documents"
            value={stats.totalDocuments}
            open={openBucket === "total"}
            onToggle={() => toggleBucket("total")}
          >
            <ul className="space-y-2.5 text-[0.65rem] leading-snug">
              {stats.documentRows.map((d) => (
                <li key={d.id} className="border-b border-border/20 pb-2 last:border-0">
                  <span className="font-medium text-foreground/90">{d.title}</span>
                  <Badge variant="outline" className="ml-2 align-middle text-[0.6rem] font-normal">
                    {d.sourceType}
                  </Badge>
                  <p className="mt-1 text-[0.65rem] leading-snug">
                    <span className="font-semibold text-muted-foreground">Full path: </span>
                    <span className="font-mono break-all text-muted-foreground">{d.path}</span>
                  </p>
                </li>
              ))}
            </ul>
          </KnowledgeBucket>

          <KnowledgeBucket
            label={analysisLabel}
            value={stats.datasetsCount}
            open={openBucket === "analysis"}
            onToggle={() => toggleBucket("analysis")}
          >
            {stats.analysisDataSetRows.length === 0 ? (
              <p className="text-[0.75rem] text-muted-foreground">
                {pool === "network"
                  ? "No .sas7bdat or .xpt in this index. Re-run network ingest on a folder that contains transport files."
                  : "No datasets in define.xml for this corpus."}
              </p>
            ) : (
              <ul className="space-y-2.5 text-[0.65rem] leading-snug">
                {stats.analysisDataSetRows.map((row) => (
                  <li key={`${row.path}::${row.datasetName}`} className="border-b border-border/20 pb-2 last:border-0">
                    <span className="font-semibold text-foreground">{row.datasetName}</span>
                    <p className="mt-1 text-[0.65rem] leading-snug">
                      <span className="font-semibold text-muted-foreground">Full path: </span>
                      <span className="font-mono break-all text-muted-foreground">{row.path}</span>
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </KnowledgeBucket>

          <KnowledgeBucket
            label="SAS programs"
            value={stats.programsCount}
            open={openBucket === "sas"}
            onToggle={() => toggleBucket("sas")}
          >
            {stats.sasProgramRows.length === 0 ? (
              <p className="text-[0.75rem] text-muted-foreground">
                No indexed .sas programs in this corpus for the active pool.
              </p>
            ) : (
              <ul className="space-y-2.5 text-[0.65rem] leading-snug">
                {stats.sasProgramRows.map((row) => (
                  <li key={row.path} className="border-b border-border/20 pb-2 last:border-0">
                    <span className="font-medium text-foreground">{row.fileName}</span>
                    <p className="mt-1 text-[0.65rem] leading-snug">
                      <span className="font-semibold text-muted-foreground">Full path: </span>
                      <span className="font-mono break-all text-muted-foreground">{row.path}</span>
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </KnowledgeBucket>
        </div>

        <div className="mt-4 grid grid-cols-2 gap-4 sm:grid-cols-4">
          <MiniStat label="With embeddings" value={stats.documentsWithEmbeddings} />
          <MiniStat label="Generated" valueLabel={new Date(stats.generatedAt).toLocaleString()} />
        </div>

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
                <span className="ml-0.5 font-bold tabular-nums text-foreground">{count}</span>
              </Badge>
            )
          })}
        </div>

        <div className="mt-3 flex flex-wrap items-center gap-1.5">
          <span className="mr-1 text-[0.6875rem] font-medium text-muted-foreground">Referenced datasets:</span>
          {stats.uniqueDatasetNames.length === 0 ? (
            <span className="text-[0.6875rem] text-muted-foreground">—</span>
          ) : (
            stats.uniqueDatasetNames.slice(0, 40).map((name) => (
              <Badge key={name} variant="secondary" className="px-2 py-0 text-[0.6875rem] font-mono">
                {name}
              </Badge>
            ))
          )}
          {stats.uniqueDatasetNames.length > 40 && (
            <span className="text-[0.6875rem] text-muted-foreground">
              +{stats.uniqueDatasetNames.length - 40} more
            </span>
          )}
        </div>
      </div>
    </section>
  )
}

function MiniStat({ label, value, valueLabel }: { label: string; value?: number; valueLabel?: string }) {
  return (
    <div className="rounded-lg border border-border/60 bg-card px-4 py-3">
      <p className="text-[0.6875rem] text-muted-foreground">{label}</p>
      <p className="mt-0.5 text-sm font-semibold tabular-nums text-foreground">
        {value !== undefined ? value.toLocaleString() : valueLabel ?? "—"}
      </p>
    </div>
  )
}
