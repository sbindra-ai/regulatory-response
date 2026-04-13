import { describe, expect, it } from "vitest"

import { splitQuestions } from "@/lib/copilot/question-detection"

const UC_HYPHEN = "\u2010" // hyphen used in Word/PDF exports

describe("splitQuestions (pdf)", () => {
  it("splits five demo-style prompts on Unicode hyphen and drops page footer", () => {
    const raw = [
      `Week 12 TEAE overall ${UC_HYPHEN} For the safety analysis set, provide a treatment-emergent adverse event overall summary at Week 12.`,
      `Week 12 SOC/PT table ${UC_HYPHEN} Prepare a Week 12 safety table for the safety analysis set.`,
      `Liver / laboratory follow${UC_HYPHEN}up ${UC_HYPHEN} For the safety analysis set, outline a subject-level close liver observation follow-up using ADLB and ADAE.`,
      `Starter Response Plan ${UC_HYPHEN} Week 12 TEAE overall summary, safety analysis set, datasets ADAE and ADSL.`,
      `EAIR / exposure${UC_HYPHEN}adjusted ${UC_HYPHEN} Week 26 exposure-adjusted incidence rate (EAIR) for treatment-emergent adverse events.`,
      "",
      "-- 1 of 1 --",
    ].join("\n")

    const qs = splitQuestions(raw, "pdf")
    expect(qs).toHaveLength(5)
    expect(qs[0].text).toContain("Week 12 TEAE overall")
    expect(qs[0].text).toContain("For the safety analysis set")
    expect(qs[1].text).toContain("SOC/PT table")
    expect(qs[2].text).toContain("ADLB")
    expect(qs[3].text).toContain("Starter Response Plan")
    expect(qs[4].text).toContain("EAIR")
    for (const q of qs) {
      expect(q.text).not.toMatch(/1 of 1/)
    }
  })

  it("splits the same prompts when hyphen is missing but title is followed by body", () => {
    const raw = [
      "Week 12 TEAE overall For the safety analysis set, provide a summary.",
      "Week 12 SOC/PT table Prepare a Week 12 safety table.",
      "Liver / laboratory follow-up For the safety analysis set, outline follow-up.",
      "Starter Response Plan Week 12 TEAE overall summary.",
      "EAIR / exposure-adjusted Week 26 exposure-adjusted incidence rate.",
    ].join("\n")

    const qs = splitQuestions(raw, "pdf")
    expect(qs.length).toBeGreaterThanOrEqual(4)
    expect(qs[0].text).toMatch(/Week 12 TEAE overall/)
  })

  it("does not split on Week 12 TEAE overall summary inside Starter Response body", () => {
    const raw = [
      `Week 12 TEAE overall ${UC_HYPHEN} Short first.`,
      `Starter Response Plan ${UC_HYPHEN} Week 12 TEAE overall summary, safety analysis set — starter plan text is long enough.`,
    ].join("\n")
    const qs = splitQuestions(raw, "pdf")
    expect(qs).toHaveLength(2)
    expect(qs[1].text).toContain("Week 12 TEAE overall summary")
    expect(qs[1].text).toContain("Starter Response Plan")
  })

  it("removes standalone page footer between questions", () => {
    const raw = `Week 12 TEAE overall ${UC_HYPHEN} First body.\n\n-- 2 of 5 --\n\nWeek 12 SOC/PT table ${UC_HYPHEN} Second body.`
    const qs = splitQuestions(raw, "pdf")
    expect(qs).toHaveLength(2)
    expect(qs.every((q) => !/of\s+5/.test(q.text))).toBe(true)
  })
})

describe("splitQuestions (text)", () => {
  it("does not treat Week line-wrap '12. Ground' as a new numbered question", () => {
    const raw = `Intro paragraph about Week\n12. Ground the plan in ADAE.`
    const qs = splitQuestions(raw, "text")
    expect(qs).toHaveLength(1)
    expect(qs[0].text).toContain("12. Ground")
  })

  it("still splits real numbered questions", () => {
    const raw = "1. First regulatory question here with enough text.\n\n2. Second question also long enough to pass."
    const qs = splitQuestions(raw, "text")
    expect(qs.length).toBeGreaterThanOrEqual(2)
    expect(qs[0].text).toMatch(/1\.\s*First/)
    expect(qs[1].text).toMatch(/2\.\s*Second/)
  })
})
