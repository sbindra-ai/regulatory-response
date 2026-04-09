import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"

import { describe, expect, it } from "vitest"

import { runNetworkIngest } from "@/lib/server/knowledge/run-network-ingest"
import { evidenceCorpusSchema } from "@/lib/server/copilot/schemas"

describe("runNetworkIngest", () => {
  it("writes a corpus when files exist and skips write when tree is empty", async () => {
    const dir = await mkdtemp(join(tmpdir(), "net-ingest-"))
    const out = join(dir, "out.json")

    const empty = await runNetworkIngest({
      scanRootOverride: dir,
      outputPathOverride: out,
    })
    expect(empty.success).toBe(false)
    expect(empty.fileDocCount).toBe(0)

    await writeFile(join(dir, "code.sas"), "%macro x;\n%mend;\n", "utf8")
    const ok = await runNetworkIngest({
      scanRootOverride: dir,
      outputPathOverride: out,
    })
    expect(ok.success).toBe(true)
    expect(ok.fileDocCount).toBeGreaterThanOrEqual(1)

    const raw = await readFile(out, "utf8")
    const parsed = evidenceCorpusSchema.parse(JSON.parse(raw))
    expect(parsed.documents.some((d) => d.sourceType === "network-file")).toBe(true)

    await rm(dir, { recursive: true, force: true })
  })
})
