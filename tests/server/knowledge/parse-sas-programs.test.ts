import { readFileSync, readdirSync } from "node:fs"
import { resolve } from "node:path"

import { describe, expect, it } from "vitest"

import { parseSasPrograms } from "@/lib/server/knowledge/parse-sas-programs"

const programsDirectory = resolve(process.cwd(), "docs/examples/programs")
const programSources = readdirSync(programsDirectory)
  .filter((fileName) => fileName.endsWith(".sas"))
  .map((fileName) => ({
    path: `docs/examples/programs/${fileName}`,
    content: readFileSync(resolve(programsDirectory, fileName), "utf8"),
  }))

describe("parseSasPrograms", () => {
  it("extracts all example programs into typed records", () => {
    const programs = parseSasPrograms(programSources)

    expect(programs).toHaveLength(67)
  })

  it("tags the major evidence families used in the MVP", () => {
    const programs = parseSasPrograms(programSources)
    const byName = new Map(programs.map((program) => [program.name, program]))

    expect(byName.get("t_adae_iss_overall_week12")).toMatchObject({
      outputFamilies: ["ae-overall"],
      datasetsUsed: ["ADAE", "ADSL"],
    })

    expect(byName.get("t_adae_iss_soc_pt_aesi2_week12")).toMatchObject({
      outputFamilies: ["aesi", "soc-pt"],
      datasetsUsed: ["ADAE", "ADSL"],
    })

    expect(byName.get("t_adae_iss_soc_pt_eair_week26")).toMatchObject({
      outputFamilies: ["eair", "soc-pt"],
      datasetsUsed: ["ADAE", "ADSL"],
    })

    expect(byName.get("f_10_2_8_2_adlb_over")).toMatchObject({
      outputFamilies: ["adlb-figure", "liver-clo"],
      datasetsUsed: ["ADAE", "ADCM", "ADLB", "ADSL"],
    })

    expect(byName.get("f_8_3_8_bmd_box")).toMatchObject({
      outputFamilies: ["bmd-figure"],
      datasetsUsed: ["ADMK", "ADSL"],
    })

    expect(byName.get("d_adlb_dili_tab")).toMatchObject({
      outputFamilies: ["derived-dataset", "liver-clo"],
      datasetsUsed: ["ADLB"],
    })
  })
})
