import { mkdtemp, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join, normalize } from "node:path"

import { describe, expect, it } from "vitest"

import {
  buildNetworkEvidenceCorpus,
  buildPlaceholderNetworkCorpus,
  extractDatasetHintsFromText,
  scanRootToDocuments,
} from "@/lib/server/knowledge/build-network-corpus"
import { evidenceCorpusSchema } from "@/lib/server/copilot/schemas"

function pathsEqual(a: string, b: string): boolean {
  return normalize(a).replace(/\\/g, "/").toLowerCase() === normalize(b).replace(/\\/g, "/").toLowerCase()
}

describe("build-network-corpus", () => {
  it("indexes a text file from a directory tree", async () => {
    const dir = await mkdtemp(join(tmpdir(), "net-corpus-"))
    await writeFile(join(dir, "note.txt"), "ADAE subgroup analysis for week 12 safety summary.", "utf8")

    const docs = await scanRootToDocuments(dir)
    const net = docs.filter((d) => d.sourceType === "network-file")

    expect(net.length).toBe(1)
    expect(net[0].title).toBe("note.txt")
    expect(pathsEqual(net[0].path, join(dir, "note.txt"))).toBe(true)
    expect(net[0].relativePath).toBe("note.txt")
    expect(net[0].sourceText).toContain("ADAE subgroup")
  })

  it("builds a schema-valid placeholder when no share ingest has run", () => {
    const corpus = buildPlaceholderNetworkCorpus()
    const parsed = evidenceCorpusSchema.parse(corpus)
    expect(parsed.documents).toHaveLength(1)
    expect(parsed.documents[0].sourceType).toBe("brief")
    expect(parsed.documents[0].id).toBe("brief:product")
  })

  it("extracts AD-style dataset tokens from SAS-like text", () => {
    expect(extractDatasetHintsFromText("merge adsl adae (in=a);")).toEqual(
      expect.arrayContaining(["ADSL", "ADAE"]),
    )
  })

  it("prepends a synthetic brief document in the corpus", async () => {
    const dir = await mkdtemp(join(tmpdir(), "net-corpus-"))
    await writeFile(join(dir, "a.txt"), "# Title\n\nBody content for testing. ADSL ADAE.", "utf8")

    const corpus = await buildNetworkEvidenceCorpus(dir)

    expect(pathsEqual(corpus.networkScanRoot ?? "", dir)).toBe(true)
    expect(corpus.documents[0].sourceType).toBe("brief")
    expect(corpus.documents[0].id).toBe("brief:product")
    expect(corpus.datasets).toEqual([])
    expect(corpus.programs).toEqual([])
    expect(corpus.documents.some((d) => d.sourceType === "network-file")).toBe(true)
    const netDoc = corpus.documents.find((d) => d.title === "a.txt")
    expect(netDoc).toBeDefined()
    expect(pathsEqual(netDoc!.path, join(dir, "a.txt"))).toBe(true)
    expect(netDoc?.relativePath).toBe("a.txt")
    expect(netDoc?.datasetNames).toEqual(expect.arrayContaining(["ADSL", "ADAE"]))
  })
})
