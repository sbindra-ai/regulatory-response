import type { EvidenceHit, RankedCodeAsset } from "@/lib/server/copilot/schemas"

/** Browser-safe path helpers (no node:path). */

export function fileNameFromPath(p: string): string {
  const n = p.replace(/\\/g, "/")
  const i = n.lastIndexOf("/")
  return i >= 0 ? n.slice(i + 1) : n
}

/** UNC, drive-letter, or POSIX absolute. */
export function isAbsolutePathDisplay(p: string): boolean {
  const t = p.trim()
  if (t.startsWith("\\\\")) return true
  if (/^[a-zA-Z]:[\\/]/.test(t)) return true
  if (t.startsWith("/")) return true
  return false
}

/** Match server-side paste normalization for scan roots shown in metadata. */
export function normalizeScanRootForUi(input: string | undefined): string | undefined {
  if (!input?.trim()) return undefined
  let s = input.trim().replace(/^["']|["']$/g, "")
  if (s.startsWith("//") && !s.startsWith("//./")) {
    s = `\\\\${s.slice(2)}`.replace(/\//g, "\\")
  } else if (s.startsWith("\\\\") || /^[a-zA-Z]:/i.test(s)) {
    s = s.replace(/\//g, "\\")
  }
  return s || undefined
}

export function joinScanRootForUi(scanRoot: string, rel: string): string {
  const root = scanRoot.replace(/[\\/]+$/, "")
  const relPart = rel.replace(/\\/g, "/").replace(/^\/+/, "")
  if (!relPart) return root
  const looksWin = root.startsWith("\\\\") || /^[a-zA-Z]:/i.test(root)
  if (looksWin) {
    return `${root}\\${relPart.replace(/\//g, "\\")}`
  }
  return `${root}/${relPart}`
}

/**
 * Prefer absolute/UNC. If `path` is still relative (legacy index), join `networkScanRootUsed`
 * (from retrieval metadata) with `relativePath` or `path`.
 */
export function displayFullPathForNetworkAsset(
  path: string,
  relativePath: string | undefined,
  networkScanRootUsed: string | undefined,
): string {
  if (isAbsolutePathDisplay(path)) return path
  const root = normalizeScanRootForUi(networkScanRootUsed)
  if (!root) return path
  const rel = (relativePath ?? path).replace(/\\/g, "/").replace(/^\/+/, "")
  if (!rel) return path
  return joinScanRootForUi(root, rel)
}

function baseDocumentIdForRankedAsset(documentId: string): string {
  return documentId.split("::macro:")[0] ?? documentId
}

/** Full path for the programs/macros table: evidence hit wins, then row; resolve relative via scan root. */
export function fullPathForRankedCodeRow(
  row: RankedCodeAsset,
  evidence: EvidenceHit[],
  networkScanRootUsed: string | undefined,
): string {
  const baseId = baseDocumentIdForRankedAsset(row.documentId)
  const hit = evidence.find((h) => h.document.id === baseId)
  const path = hit?.document.path ?? row.path
  const relativePath = row.relativePath ?? hit?.document.relativePath
  return displayFullPathForNetworkAsset(path, relativePath, networkScanRootUsed)
}
