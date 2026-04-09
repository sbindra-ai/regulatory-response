import { existsSync, readFileSync } from "node:fs"
import { resolve } from "node:path"

import { runNetworkIngest } from "@/lib/server/knowledge/run-network-ingest"

const envPath = resolve(process.cwd(), ".env")
if (existsSync(envPath)) {
  for (const line of readFileSync(envPath, "utf8").split("\n")) {
    const match = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*"?([^"]*)"?\s*$/)
    if (match && !process.env[match[1]]) {
      process.env[match[1]] = match[2]
    }
  }
}

async function main() {
  const argRoot = process.argv[2]?.trim()
  const result = await runNetworkIngest({ scanRootOverride: argRoot || undefined })

  console.log(`Scan root used:\n  ${result.scanRootUsed || "(none)"}\n`)
  console.log(`Output:\n  ${result.outputPath}\n`)

  if (!result.success) {
    console.error(result.error ?? "Network ingest failed.")
    for (const w of result.warnings) console.warn(w)
    process.exitCode = 1
    return
  }

  console.log(`Found ${result.fileDocCount} indexed chunks/documents (+ product brief).`)
  for (const w of result.warnings) console.warn(w)
  console.log(`With embeddings: ${result.embeddedCount}`)
  console.log(`\nWrote network evidence corpus to ${result.outputPath}`)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
