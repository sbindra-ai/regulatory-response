"use client"

import Image from "next/image"
import { MeshGradient } from "@paper-design/shaders-react"

export function ShaderHero() {
  return (
    <section className="relative isolate overflow-hidden">
      {/* Shader background */}
      <div className="absolute inset-0 -z-10">
        <MeshGradient
          colors={["#10384F", "#00BCFF", "#89D329", "#10384F", "#00BCFF"]}
          speed={0.15}
          distortion={0.4}
          swirl={0.3}
          grainMixer={0.0}
          grainOverlay={0.05}
          style={{ width: "100%", height: "100%" }}
        />
        {/* Subtle vignette overlay for text readability */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#10384F]/30 via-transparent to-[#10384F]/40" />
      </div>

      {/* Header bar */}
      <div className="flex flex-wrap items-center justify-between gap-4 px-[clamp(1.25rem,3vw,2.5rem)] py-3.5">
        <div className="flex items-center gap-3">
          <div className="rounded-md bg-white/95 p-1.5 shadow-sm backdrop-blur-sm">
            <Image
              src="/logos/Logo_Bayer.svg"
              alt="Bayer"
              width={32}
              height={32}
              className="shrink-0"
            />
          </div>
          <p className="font-heading text-[0.9375rem] font-bold leading-tight text-white">
            Regulatory-Response Copilot
          </p>
        </div>

      </div>

      {/* Hero content */}
      <div className="px-[clamp(1.25rem,3vw,2.5rem)] pb-14 pt-10 sm:pb-16 sm:pt-14">
        <div className="mx-auto max-w-[86rem]">
          <h1 className="font-heading text-balance text-[clamp(2rem,4vw,3.25rem)] font-bold leading-[1.08] tracking-tight text-white">
            AI-Powered Regulatory
            <br />
            Response Accelerator for SPA
          </h1>
          <p className="mt-4 max-w-2xl text-[clamp(0.9375rem,1.2vw,1.125rem)] leading-relaxed text-white/80">
            Paste a regulatory question below. The tool interprets the ask, retrieves matching
            repository evidence, and produces a traceable starter plan.
          </p>
        </div>
      </div>
    </section>
  )
}
