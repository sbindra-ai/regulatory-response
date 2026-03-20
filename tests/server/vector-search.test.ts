import { describe, expect, it } from "vitest"

import { cosineSimilarity, vectorSearch } from "@/lib/server/copilot/vector-search"
import type { EvidenceDocument } from "@/lib/server/copilot/schemas"

describe("cosineSimilarity", () => {
  it("returns 1 for identical vectors", () => {
    expect(cosineSimilarity([1, 0, 0], [1, 0, 0])).toBeCloseTo(1)
  })

  it("returns 0 for orthogonal vectors", () => {
    expect(cosineSimilarity([1, 0, 0], [0, 1, 0])).toBeCloseTo(0)
  })

  it("returns -1 for opposite vectors", () => {
    expect(cosineSimilarity([1, 0], [-1, 0])).toBeCloseTo(-1)
  })

  it("returns 0 for empty vectors", () => {
    expect(cosineSimilarity([], [])).toBe(0)
  })

  it("returns 0 for zero vectors", () => {
    expect(cosineSimilarity([0, 0, 0], [0, 0, 0])).toBe(0)
  })

  it("returns 0 for mismatched lengths", () => {
    expect(cosineSimilarity([1, 0], [1, 0, 0])).toBe(0)
  })

  it("computes correct similarity for arbitrary vectors", () => {
    const a = [1, 2, 3]
    const b = [4, 5, 6]
    // dot = 32, |a| = sqrt(14), |b| = sqrt(77)
    const expected = 32 / (Math.sqrt(14) * Math.sqrt(77))
    expect(cosineSimilarity(a, b)).toBeCloseTo(expected)
  })
})

describe("vectorSearch", () => {
  const baseDoc: Omit<EvidenceDocument, "id" | "embedding"> = {
    title: "Test",
    sourceType: "program",
    path: "test.sas",
    summary: "Test document",
    keywords: ["test"],
    datasetNames: ["ADAE"],
    outputFamilies: ["ae-overall"],
    sourceText: "test",
  }

  it("returns documents sorted by similarity descending", () => {
    const documents: EvidenceDocument[] = [
      { ...baseDoc, id: "a", embedding: [1, 0, 0] },
      { ...baseDoc, id: "b", embedding: [0.9, 0.1, 0] },
      { ...baseDoc, id: "c", embedding: [0, 1, 0] },
    ]

    const results = vectorSearch([1, 0, 0], documents)

    expect(results).toHaveLength(3)
    expect(results[0].documentId).toBe("a")
    expect(results[0].similarity).toBeCloseTo(1)
    expect(results[1].documentId).toBe("b")
    expect(results[2].documentId).toBe("c")
    expect(results[2].similarity).toBeCloseTo(0)
  })

  it("skips documents with null embeddings", () => {
    const documents: EvidenceDocument[] = [
      { ...baseDoc, id: "a", embedding: [1, 0, 0] },
      { ...baseDoc, id: "b", embedding: null },
      { ...baseDoc, id: "c", embedding: [0, 1, 0] },
    ]

    const results = vectorSearch([1, 0, 0], documents)

    expect(results).toHaveLength(2)
    expect(results.map((r) => r.documentId)).toEqual(["a", "c"])
  })

  it("returns empty array when all embeddings are null", () => {
    const documents: EvidenceDocument[] = [
      { ...baseDoc, id: "a", embedding: null },
      { ...baseDoc, id: "b", embedding: null },
    ]

    const results = vectorSearch([1, 0, 0], documents)
    expect(results).toHaveLength(0)
  })
})
