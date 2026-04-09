"use client"

import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"

const steps = [
  {
    title: "Interpret",
    description:
      "Your question is parsed by an LLM to extract the analysis type, target population, endpoints, timepoints, and relevant datasets.",
  },
  {
    title: "Retrieve evidence",
    description:
      "The active index (repository demo assets or an optional Samba-share corpus) is searched with hybrid or vector-first ranking: MiniSearch keywords plus cosine similarity when embeddings are present.",
  },
  {
    title: "Generate plan",
    description:
      "A second LLM call produces a traceable response plan grounded in the retrieved evidence, with deliverables, team responsibilities, and citations back to source.",
  },
]

const techDetails = [
  {
    label: "LLM",
    value: "GPT-5 via Bayer myGenAssist (MGA) internal API",
  },
  {
    label: "Embedding model",
    value: "text-embedding-3-small (1 536 dimensions)",
  },
  {
    label: "Retrieval",
    value:
      "Hybrid (default) fuses MiniSearch keyword hits with vector cosine similarity via RRF (K=60). Vector-first mode weights semantic similarity higher for large network shares.",
  },
  {
    label: "Heuristic boosting",
    value:
      "Post-fusion scores are adjusted by dataset overlap, output-family matches, timepoint alignment, and document source type to promote the most relevant evidence.",
  },
  {
    label: "Fallback",
    value:
      "When vector embeddings are unavailable, the pipeline degrades gracefully to keyword-only retrieval so results are always returned.",
  },
  {
    label: "Knowledge base",
    value:
      "Repository JSON ships with the app; optional network corpus is produced by scanning a mapped UNC path into evidence-corpus.network.json with the same embedding pipeline.",
  },
]

export function PipelineExplainer() {
  return (
    <section className="border-b border-border bg-white">
      <div className="mx-auto w-full max-w-[86rem] px-5 py-8 sm:px-8 sm:py-10 lg:px-10">
        <p className="font-heading text-[0.6875rem] font-semibold uppercase tracking-[0.12em] text-muted-foreground">
          How the copilot works
        </p>

        <div className="relative mt-6 grid gap-0 sm:grid-cols-3">
          {/* Connecting line - visible on sm+ */}
          <div
            aria-hidden
            className="absolute left-0 right-0 top-[0.8125rem] hidden h-px bg-border sm:block"
          />

          {steps.map((step, i) => (
            <div key={step.title} className="relative flex gap-4 sm:flex-col sm:gap-0">
              {/* Step indicator */}
              <div className="relative z-10 flex shrink-0 items-start sm:items-center">
                <span className="flex h-[1.625rem] w-[1.625rem] items-center justify-center rounded-full border-2 border-primary/25 bg-card text-[0.6875rem] font-bold tabular-nums text-primary shadow-[0_0_0_4px_var(--muted)]">
                  {i + 1}
                </span>
                {/* Mobile connecting line segment */}
                {i < steps.length - 1 && (
                  <div
                    aria-hidden
                    className="absolute left-[0.75rem] top-[1.625rem] h-[calc(100%+0.5rem)] w-px bg-border sm:hidden"
                  />
                )}
              </div>

              {/* Text */}
              <div className="pb-6 sm:pb-0 sm:pr-8 sm:pt-4">
                <p className="font-heading text-[0.875rem] font-bold leading-snug text-foreground">
                  {step.title}
                </p>
                <p className="mt-1 text-[0.8125rem] leading-relaxed text-muted-foreground">
                  {step.description}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Collapsible technical details */}
        <Accordion type="single" collapsible className="mt-6">
          <AccordionItem value="tech" className="border-b-0 border-t border-border/60">
            <AccordionTrigger className="py-3 hover:no-underline">
              <span className="font-heading text-[0.6875rem] font-semibold uppercase tracking-[0.12em] text-muted-foreground">
                Technical details
              </span>
            </AccordionTrigger>
            <AccordionContent className="pb-0">
              <dl className="grid gap-x-10 gap-y-4 sm:grid-cols-2 lg:grid-cols-3">
                {techDetails.map((item) => (
                  <div key={item.label}>
                    <dt className="text-[0.75rem] font-semibold text-foreground/70">
                      {item.label}
                    </dt>
                    <dd className="mt-0.5 text-[0.8125rem] leading-relaxed text-muted-foreground">
                      {item.value}
                    </dd>
                  </div>
                ))}
              </dl>
            </AccordionContent>
          </AccordionItem>
        </Accordion>
      </div>
    </section>
  )
}
