import { describe, expect, it } from "vitest"

import { demoPrompts } from "@/lib/copilot/demo-prompts"

describe("demoPrompts", () => {
  it("covers the supported MVP request families", () => {
    expect(demoPrompts.map((prompt) => prompt.id)).toEqual([
      "ae-overall-week12",
      "soc-pt-week12",
      "aesi-fatigue-week12",
      "eair-week26",
      "liver-clo-followup",
      "bmd-race-figure",
    ])
  })

  it("keeps every prompt display-ready", () => {
    for (const prompt of demoPrompts) {
      expect(prompt.label.length).toBeGreaterThan(10)
      expect(prompt.question.length).toBeGreaterThan(20)
    }
  })
})
