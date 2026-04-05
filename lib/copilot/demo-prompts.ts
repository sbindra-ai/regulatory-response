export type DemoPromptFamily =
  | "ae-syncope"
  | "ae-summary"
  | "soc-pt"
  | "aesi"
  | "eair"
  | "liver-clo"
  | "bmd-figure"

export type DemoPrompt = {
  id: string
  family: DemoPromptFamily
  label: string
  question: string
}

export const demoPrompts: DemoPrompt[] = [
  {
    id: "ae-syncope-ia",
    family: "ae-syncope",
    label: "AE incidence with syncope",
    question:
      "Provide the number of subjects who experienced syncope in the four phase 2/3 clinical trials (SWITCH-1, and OASIS 1, 2 and 3) and provide the case narrative for each.",
  },
  {
    id: "ae-overall-week12",
    family: "ae-summary",
    label: "Week 12 overall AE summary",
    question:
      "Provide an evidence-backed starter plan for a week 12 treatment-emergent adverse event overall summary for the safety analysis set.",
  },
  {
    id: "soc-pt-week12",
    family: "soc-pt",
    label: "Week 12 SOC/PT safety table",
    question:
      "Interpret this as a regulatory response request and identify the best evidence for a week 12 safety table by primary system organ class and preferred term.",
  },
  {
    id: "aesi-fatigue-week12",
    family: "aesi",
    label: "AESI somnolence or fatigue follow-up",
    question:
      "Find the most relevant prior evidence and build a starter response plan for treatment-emergent adverse events of special interest focused on somnolence or fatigue up to week 12.",
  },
  {
    id: "eair-week26",
    family: "eair",
    label: "Week 26 EAIR request",
    question:
      "Create a grounded response plan for a week 26 exposure-adjusted incidence rate request covering treatment-emergent adverse events by SOC and preferred term.",
  },
  {
    id: "liver-clo-followup",
    family: "liver-clo",
    label: "Liver close observation follow-up",
    question:
      "What repo evidence should SPA review first for a subject-level close liver observation follow-up request involving laboratory trends and supporting datasets?",
  },
  {
    id: "bmd-race-figure",
    family: "bmd-figure",
    label: "BMD by race figure",
    question:
      "Draft a traceable starter plan for a box plot showing percent change in bone mineral density from baseline by race at weeks 24 and 52.",
  },
]
