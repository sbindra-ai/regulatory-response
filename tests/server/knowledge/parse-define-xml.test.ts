import { readFileSync } from "node:fs"
import { resolve } from "node:path"

import { describe, expect, it } from "vitest"

import { parseDefineXml } from "@/lib/server/knowledge/parse-define-xml"

const defineXml = readFileSync(resolve(process.cwd(), "docs/examples/define.xml"), "utf8")

describe("parseDefineXml", () => {
  it("extracts the targeted ADaM datasets used by the MVP", () => {
    const datasets = parseDefineXml(defineXml)
    const datasetNames = datasets.map((dataset) => dataset.name)

    expect(datasetNames).toEqual(
      expect.arrayContaining(["ADSL", "ADAE", "ADCM", "ADLB", "ADTTE", "ADVS"]),
    )
  })

  it("captures dataset descriptions, leaf references, and representative variables", () => {
    const datasets = parseDefineXml(defineXml)
    const adae = datasets.find((dataset) => dataset.name === "ADAE")
    const adlb = datasets.find((dataset) => dataset.name === "ADLB")

    expect(adae).toMatchObject({
      name: "ADAE",
      label: "Adverse Events Analysis Dataset",
      structure: "One record per subject per each AE recorded in SDTM AE domain",
      leaf: "adae.xpt",
    })
    expect(adae?.variables.map((variable) => variable.name)).toEqual(
      expect.arrayContaining(["AEDECOD", "AEBODSYS", "TRTEMFL", "TRT01AN", "USUBJID"]),
    )

    expect(adlb).toMatchObject({
      name: "ADLB",
      label: "Laboratory Analysis Dataset",
      leaf: "adlb.xpt",
    })
    expect(adlb?.variables.map((variable) => variable.name)).toEqual(
      expect.arrayContaining(["PARAMCD", "AVAL", "ADT", "TRTEMFL", "USUBJID"]),
    )
  })
})
