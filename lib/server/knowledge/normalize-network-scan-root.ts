import "server-only"

import { readdir, stat } from "node:fs/promises"

/**
 * Normalize user-pasted paths for Windows shares (UNC).
 * - Trims and strips wrapping quotes
 * - Turns URL-style `//server/share/...` into `\\server\share\...`
 * - Normalizes forward slashes to backslashes for drive letters and UNC on win32
 */
export function normalizeNetworkScanRoot(input: string): string {
  let s = input.trim().replace(/^["']|["']$/g, "")
  if (!s) return s

  // Common paste from browsers / docs: //by-swanPRD/swan/...
  if (s.startsWith("//") && !s.startsWith("//./")) {
    s = `\\\\${s.slice(2)}`.replace(/\//g, "\\")
  } else if (process.platform === "win32") {
    if (s.startsWith("\\\\") || /^[a-zA-Z]:/i.test(s)) {
      s = s.replace(/\//g, "\\")
    }
  }

  return s
}

/**
 * On Windows, Node sometimes needs the extended UNC prefix for Samba paths.
 * @see https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation
 */
export function uncScanPathCandidates(normalized: string): string[] {
  if (process.platform !== "win32" || !normalized.startsWith("\\\\")) {
    return [normalized]
  }

  const without = normalized.slice(2)
  const firstSep = without.indexOf("\\")
  if (firstSep <= 0) return [normalized]

  const host = without.slice(0, firstSep)
  const rest = without.slice(firstSep + 1)
  if (!rest) return [normalized]

  const extended = `\\\\?\\UNC\\${host}\\${rest}`
  if (extended === normalized) return [normalized]
  return [normalized, extended]
}

export type ScanRootResolution =
  | { ok: true; path: string; tried: string[] }
  | { ok: false; error: string; tried: string[] }

/**
 * Pick the first variant that exists as a directory and is listable.
 */
export async function resolveReadableScanRoot(normalized: string): Promise<ScanRootResolution> {
  const tried = uncScanPathCandidates(normalized)
  const errors: string[] = []

  for (const p of tried) {
    try {
      const st = await stat(p)
      if (!st.isDirectory()) {
        errors.push(`${p} — not a directory`)
        continue
      }
      await readdir(p)
      return { ok: true, path: p, tried }
    } catch (e) {
      const err = e as NodeJS.ErrnoException
      errors.push(`${p} — ${err.code ?? "ERR"}: ${err.message}`)
    }
  }

  return {
    ok: false,
    tried,
    error: [
      "The server process could not open any of these paths:",
      ...errors.map((line) => `  • ${line}`),
      "",
      "Typical causes: VPN off, no rights to the share for the Windows user running Node, or the path must use the extended form (the app tries both automatically).",
    ].join("\n"),
  }
}
