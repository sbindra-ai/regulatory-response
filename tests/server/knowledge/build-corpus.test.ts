import { existsSync, readFileSync, readdirSync } from "node:fs"
import { join, relative, resolve } from "node:path"

import { describe, expect, it } from "vitest"

import { buildCorpus } from "@/lib/server/knowledge/build-corpus"

const readmeContent = readFileSync(resolve(process.cwd(), "README.md"), "utf8")

const defineXmlPath = existsSync(resolve(process.cwd(), "docs/examples/documents/define.xml"))
  ? resolve(process.cwd(), "docs/examples/documents/define.xml")
  : resolve(process.cwd(), "docs/examples/define.xml")
const defineXml = readFileSync(defineXmlPath, "utf8")
const defineDatasetDocumentPath = relative(process.cwd(), defineXmlPath).replace(/\\/g, "/")

function collectProgramSources(): { path: string; content: string }[] {
  const out: { path: string; content: string }[] = []
  for (const absDir of [
    resolve(process.cwd(), "docs/examples/programs"),
    resolve(process.cwd(), "docs/examples/macros"),
  ]) {
    if (!existsSync(absDir)) continue
    for (const fileName of readdirSync(absDir).filter((n) => n.toLowerCase().endsWith(".sas"))) {
      const abs = join(absDir, fileName)
      out.push({
        path: relative(process.cwd(), abs).replace(/\\/g, "/"),
        content: readFileSync(abs, "utf8"),
      })
    }
  }
  return out.sort((a, b) => a.path.localeCompare(b.path))
}

const programSources = collectProgramSources()

describe("buildCorpus", () => {
  it("combines the README, define.xml, and SAS examples into a deterministic corpus", () => {
    const corpus = buildCorpus({
      defineXml,
      defineDatasetDocumentPath,
      generatedAt: "2026-03-17T00:00:00.000Z",
      programSources,
      readmeContent,
    })

    expect(corpus.generatedAt).toBe("2026-03-17T00:00:00.000Z")
    expect(corpus.brief.title).toBe("Regulatory AI for Structured Execution (RAISE)")
    expect(corpus.datasets.map((dataset) => dataset.name)).toEqual(
      expect.arrayContaining(["ADAE", "ADLB", "ADSL", "ADVS"]),
    )
    expect(corpus.programs.length).toBeGreaterThanOrEqual(67)
    expect(corpus.documents.map((document) => document.id)).toEqual(
      expect.arrayContaining([
        "brief:product",
        "dataset:ADAE",
        "dataset:ADLB",
        "program:t_adae_iss_overall_week12",
        "program:f_10_2_8_2_adlb_over",
      ]),
    )
    const adslDoc = corpus.documents.find((d) => d.id === "dataset:ADSL")
    expect(adslDoc?.path).toBe(defineDatasetDocumentPath)
  })

  it("uses a stable generatedAt value when the inputs do not change", () => {
    const firstCorpus = buildCorpus({
      defineXml,
      defineDatasetDocumentPath,
      programSources,
      readmeContent,
    })
    const secondCorpus = buildCorpus({
      defineXml,
      defineDatasetDocumentPath,
      programSources,
      readmeContent,
    })

    expect(secondCorpus.generatedAt).toBe(firstCorpus.generatedAt)
  })
})
