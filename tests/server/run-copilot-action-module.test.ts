import { readFileSync } from "node:fs"
import { resolve } from "node:path"

import { describe, expect, it } from "vitest"

describe("run-copilot server action module", () => {
  it("does not export non-async runtime values from the use server file", () => {
    const source = readFileSync(resolve(process.cwd(), "app/actions/run-copilot.ts"), "utf8")

    expect(source).toContain('"use server"')
    expect(source).toContain("export async function runCopilotAction")
    expect(source).not.toMatch(/export const\s+initialRunCopilotActionState/)
  })
})
