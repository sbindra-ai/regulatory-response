import { describe, expect, it } from "vitest"

import {
  normalizeNetworkScanRoot,
  uncScanPathCandidates,
} from "@/lib/server/knowledge/normalize-network-scan-root"

describe("normalizeNetworkScanRoot", () => {
  it("converts URL-style UNC slashes to Windows form", () => {
    expect(normalizeNetworkScanRoot("//by-swanPRD/swan/root/bhc/3427080")).toBe(
      "\\\\by-swanPRD\\swan\\root\\bhc\\3427080",
    )
  })

  it("strips wrapping quotes", () => {
    expect(normalizeNetworkScanRoot('"\\\\server\\share\\study"')).toBe("\\\\server\\share\\study")
  })
})

describe("uncScanPathCandidates", () => {
  it("adds extended UNC prefix on win32 only", () => {
    const input = "\\\\by-swanPRD\\swan\\root"
    const c = uncScanPathCandidates(input)
    if (process.platform === "win32") {
      expect(c[0]).toBe(input)
      expect(c.some((p) => p.startsWith("\\\\?\\UNC\\"))).toBe(true)
    } else {
      expect(c).toEqual([input])
    }
  })
})
