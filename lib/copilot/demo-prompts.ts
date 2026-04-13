export type DemoPromptFamily =
  | "ae-summary"
  | "soc-pt"
  | "liver-clo"
  | "starter-plan"
  | "eair"

export type DemoPrompt = {
  id: string
  family: DemoPromptFamily
  label: string
  question: string
}

export const demoPrompts: DemoPrompt[] = [
  {
    id: "week12-teae-overall",
    family: "ae-summary",
    label: "Week 12 TEAE overall",
    question:
      "For the safety analysis set, provide a treatment-emergent adverse event overall summary at Week 12. Ground the plan in ADAE and ADSL. Include SOC and preferred term detail suitable for a regulatory response.",
  },
  {
    id: "week12-soc-pt-table",
    family: "soc-pt",
    label: "Week 12 SOC/PT table",
    question:
      "Prepare a Week 12 safety table for the safety analysis set: treatment-emergent adverse events by system organ class and preferred term, using ADAE (and ADSL for population flags). Reference prior TLF or SAS evidence where available.",
  },
  {
    id: "liver-laboratory-followup",
    family: "liver-clo",
    label: "Liver / laboratory follow-up",
    question:
      "For the safety analysis set, outline a subject-level close liver observation follow-up: use ADLB and ADAE, focus on laboratory trends during treatment through Week 12, and cite the closest prior repo programs for figures or listings.",
  },
  {
    id: "starter-response-plan-week12",
    family: "starter-plan",
    label: "Starter Response Plan",
    question:
      "Week 12 TEAE overall summary, safety analysis set, datasets ADAE and ADSL — starter response plan with traceable repo evidence.",
  },
  {
    id: "eair-week26-exposure-adjusted",
    family: "eair",
    label: "EAIR / exposure-adjusted",
    question:
      "Week 26 exposure-adjusted incidence rate (EAIR) for treatment-emergent adverse events by SOC and PT, safety analysis set, using ADAE with exposure from ADSL — identify matching SAS and dataset evidence first.",
  },
]
