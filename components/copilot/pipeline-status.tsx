"use client"

import { useEffect, useState } from "react"

import { ShinyText } from "@/components/ui/shiny-text"

const PIPELINE_STAGES = [
  "✨ Interpreting regulatory question\u2026",
  "✨ Searching evidence corpus for matching documents\u2026",
  "✨ Building grounded response plan\u2026",
] as const

const STAGE_INTERVAL_MS = 4000

export function PipelineStatus() {
  const [stageIndex, setStageIndex] = useState(0)

  useEffect(() => {
    const interval = setInterval(() => {
      setStageIndex((current) =>
        current < PIPELINE_STAGES.length - 1 ? current + 1 : current,
      )
    }, STAGE_INTERVAL_MS)

    return () => clearInterval(interval)
  }, [])

  return (
    <ShinyText speed={2} className="meta-label text-sm">
      {PIPELINE_STAGES[stageIndex]}
    </ShinyText>
  )
}
