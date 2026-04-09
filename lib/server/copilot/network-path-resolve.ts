import "server-only"

import type { EvidenceHit } from "@/lib/server/copilot/schemas"
import { normalizeNetworkScanRoot } from "@/lib/server/knowledge/normalize-network-scan-root"

/** True for Windows UNC, drive-letter paths, and rooted POSIX paths. */
export function isAbsoluteStoragePath(p: string): boolean {
  const t = p.trim()
  if (t.startsWith("\\\\")) return true
  if (/^[a-zA-Z]:[\\/]/.test(t)) return true
  if (t.startsWith("/")) return true
  return false
}

/** Join a normalized UNC/drive root with a relative path (forward or back slashes). */
export function joinScanRootToRelativePath(scanRoot: string, rel: string): string {
  const root = scanRoot.replace(/[\\/]+$/, "")
  const relPart = rel.replace(/\\/g, "/").replace(/^\/+/, "")
  if (!relPart) return root
  if (process.platform === "win32") {
    return `${root}\\${relPart.replace(/\//g, "\\")}`
  }
  return `${root}/${relPart}`
}

/**
 * Legacy network corpora sometimes store only a relative `path`. Join `EVIDENCE_SCAN_ROOT` (or default)
 * so hits and the response-plan table show full UNC / absolute paths without mutating the cached corpus.
 */
export function normalizeEvidenceHitsForNetworkShare(
  evidence: EvidenceHit[],
  scanRootRaw: string,
): EvidenceHit[] {
  const scanRoot = normalizeNetworkScanRoot(scanRootRaw)
  if (!scanRoot) return evidence

  return evidence.map((hit) => {
    const { document } = hit
    if (document.sourceType === "brief") return hit
    if (isAbsoluteStoragePath(document.path)) return hit

    const rel = (document.relativePath ?? document.path).replace(/\\/g, "/").replace(/^\/+/, "")
    if (!rel) return hit

    const fullPath = joinScanRootToRelativePath(scanRoot, rel)
    return {
      ...hit,
      document: {
        ...document,
        path: fullPath,
      },
    }
  })
}
