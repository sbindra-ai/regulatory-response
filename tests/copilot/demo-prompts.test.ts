import { describe, expect, it } from "vitest"

import { demoPrompts } from "@/lib/copilot/demo-prompts"

describe("demoPrompts", () => {
  it("covers the supported MVP request families", () => {
    expect(demoPrompts.map((prompt) => prompt.id)).toEqual([
      "week12-teae-overall",
      "week12-soc-pt-table",
      "liver-laboratory-followup",
      "starter-response-plan-week12",
      "eair-week26-exposure-adjusted",
    ])
  })

  it("keeps every prompt display-ready", () => {
    for (const prompt of demoPrompts) {
      expect(prompt.label.length).toBeGreaterThan(10)
      expect(prompt.question.length).toBeGreaterThan(20)
    }
  })
})
