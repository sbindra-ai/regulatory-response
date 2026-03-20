import { readFileSync, readdirSync } from "node:fs"
import { resolve } from "node:path"

import { describe, expect, it } from "vitest"

import { buildCorpus } from "@/lib/server/knowledge/build-corpus"

const readmeContent = readFileSync(resolve(process.cwd(), "README.md"), "utf8")
const defineXml = readFileSync(resolve(process.cwd(), "docs/examples/define.xml"), "utf8")
const programsDirectory = resolve(process.cwd(), "docs/examples/programs")
const programSources = readdirSync(programsDirectory)
  .filter((fileName) => fileName.endsWith(".sas"))
  .map((fileName) => ({
    path: `docs/examples/programs/${fileName}`,
    content: readFileSync(resolve(programsDirectory, fileName), "utf8"),
  }))

describe("buildCorpus", () => {
  it("combines the README, define.xml, and SAS examples into a deterministic corpus", () => {
    const corpus = buildCorpus({
      defineXml,
      generatedAt: "2026-03-17T00:00:00.000Z",
      programSources,
      readmeContent,
    })

    expect(corpus.generatedAt).toBe("2026-03-17T00:00:00.000Z")
    expect(corpus.brief.title).toBe("AI-Powered Regulatory Response Accelerator for SPA")
    expect(corpus.datasets.map((dataset) => dataset.name)).toEqual(
      expect.arrayContaining(["ADAE", "ADLB", "ADSL", "ADVS"]),
    )
    expect(corpus.programs).toHaveLength(67)
    expect(corpus.documents.map((document) => document.id)).toEqual(
      expect.arrayContaining([
        "brief:product",
        "dataset:ADAE",
        "dataset:ADLB",
        "program:t_adae_iss_overall_week12",
        "program:f_10_2_8_2_adlb_over",
      ]),
    )
  })

  it("uses a stable generatedAt value when the inputs do not change", () => {
    const firstCorpus = buildCorpus({
      defineXml,
      programSources,
      readmeContent,
    })
    const secondCorpus = buildCorpus({
      defineXml,
      programSources,
      readmeContent,
    })

    expect(secondCorpus.generatedAt).toBe(firstCorpus.generatedAt)
  })
})
