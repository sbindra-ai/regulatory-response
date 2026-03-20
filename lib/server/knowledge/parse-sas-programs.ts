export type SasProgramSource = {
  path: string
  content: string
}

export type SasProgramRecord = {
  name: string
  path: string
  title: string
  purpose: string
  datasetsUsed: string[]
  outputFamilies: string[]
  keywords: string[]
  sourceText: string
  studyNumber: string | null
  compound: string | null
  statisticalMethods: string[]
  titlesAndFootnotes: string[]
  filterConditions: string[]
  parameters: string[]
  analysisVariables: string[]
  visitTimepoints: string[]
}

const familyMatchers = [
  { family: "aesi", test: (source: SasProgramSource, purpose: string) => /aesi/i.test(source.path) || /special interest/i.test(purpose) },
  {
    family: "eair",
    test: (source: SasProgramSource, purpose: string) =>
      /eair/i.test(source.path) || /exposure-adjusted incidence rate/i.test(purpose),
  },
  {
    family: "derived-dataset",
    test: (source: SasProgramSource, purpose: string) =>
      /^docs\/examples\/programs\/d_/i.test(source.path) || /^create dataset/i.test(purpose),
  },
  {
    family: "adlb-figure",
    test: (source: SasProgramSource, purpose: string) => /adlb/i.test(source.path) && /(figure|plot)/i.test(purpose),
  },
  { family: "bmd-figure", test: (source: SasProgramSource) => /bmd/i.test(source.path) },
  {
    family: "liver-clo",
    test: (source: SasProgramSource, purpose: string) =>
      /(dili|close liver observation|\bclo\b)/i.test(`${source.path} ${purpose} ${source.content}`),
  },
  {
    family: "ae-overall",
    test: (source: SasProgramSource, purpose: string) => /overall/i.test(source.path) && /adverse events/i.test(purpose),
  },
  { family: "soc-pt", test: (source: SasProgramSource) => /soc_pt/i.test(source.path) },
]

const statisticalMethodMap: Array<{ pattern: RegExp; label: string }> = [
  { pattern: /PROC\s+LIFETEST/i, label: "Kaplan-Meier survival analysis" },
  { pattern: /PROC\s+FREQ/i, label: "Frequency analysis" },
  { pattern: /PROC\s+MEANS/i, label: "Descriptive statistics (PROC MEANS)" },
  { pattern: /PROC\s+UNIVARIATE/i, label: "Univariate statistics" },
  { pattern: /PROC\s+LOGISTIC/i, label: "Logistic regression" },
  { pattern: /PROC\s+MIXED/i, label: "Mixed model analysis" },
  { pattern: /PROC\s+GLM/i, label: "General linear model" },
  { pattern: /PROC\s+PHREG/i, label: "Cox proportional hazards model" },
  { pattern: /PROC\s+SORT/i, label: "Data sorting" },
  { pattern: /PROC\s+TRANSPOSE/i, label: "Data transposition" },
  { pattern: /PROC\s+SQL/i, label: "SQL-based data manipulation" },
  { pattern: /PROC\s+REPORT/i, label: "Report generation" },
  { pattern: /%m_wrap_risk_difference/i, label: "Mantel-Haenszel risk difference" },
  { pattern: /%desc_tab/i, label: "Descriptive statistics table" },
  { pattern: /%incidence_print/i, label: "Incidence counting" },
  { pattern: /%desc_freq_tab/i, label: "Frequency/descriptive summary" },
  { pattern: /%overview_tab/i, label: "Overview/disposition table" },
  { pattern: /%km_plot/i, label: "Kaplan-Meier plot" },
  { pattern: /%forest_plot/i, label: "Forest plot" },
  { pattern: /%waterfall/i, label: "Waterfall plot" },
  { pattern: /%spaghetti/i, label: "Spaghetti plot" },
  { pattern: /%shift_tab/i, label: "Shift table analysis" },
]

function normalizeWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim()
}

function extractProgramName(content: string): string {
  const match = content.match(/%iniprog\s*\(\s*name\s*=\s*([a-z0-9_]+)/i)

  return match?.[1] ?? ""
}

function extractPurpose(content: string): string {
  const match = content.match(/\*\s*Purpose\s*:\s*([\s\S]*?)\n\s*\*\s*Programming Spec\s*:/i)

  if (!match) {
    return ""
  }

  return normalizeWhitespace(
    match[1]
      .split("\n")
      .map((line) => line.replace(/^\s*\*\s?/, "").trim())
      .filter(Boolean)
      .join(" "),
  )
}

function extractDatasetsUsed(content: string): string[] {
  const datasetMatches = [
    ...content.matchAll(/adsDomain\s*=\s*([a-z0-9_]+)/gi),
    ...content.matchAll(/create_ads_view\s*\([\s\S]*?adsDomain\s*=\s*([a-z0-9_]+)/gi),
  ]

  return [...new Set(datasetMatches.map((match) => match[1].toUpperCase()))].sort()
}

function extractOutputFamilies(source: SasProgramSource, purpose: string): string[] {
  return familyMatchers
    .filter(({ test }) => test(source, purpose))
    .map(({ family }) => family)
}

function extractStudyMetadata(content: string): { studyNumber: string | null; compound: string | null } {
  const studyMatch = content.match(/Study\s*:\s*(\d+)/i)
  const compoundMatch = content.match(/Proj\/Subst\/GIAD\s*:\s*(.*?)(?:\n|\*)/i)

  return {
    studyNumber: studyMatch?.[1] ?? null,
    compound: compoundMatch ? normalizeWhitespace(compoundMatch[1]) : null,
  }
}

function extractStatisticalMethods(content: string): string[] {
  const methods: string[] = []

  for (const { pattern, label } of statisticalMethodMap) {
    if (pattern.test(content)) {
      methods.push(label)
    }
  }

  return [...new Set(methods)]
}

function extractTitlesAndFootnotes(content: string): string[] {
  const results: string[] = []

  // %set_titles_footnotes(tit1 = "...", ftn1 = "...", ...)
  for (const match of content.matchAll(/(?:tit|ftn)\d+\s*=\s*"([^"]+)"/gi)) {
    results.push(normalizeWhitespace(match[1]))
  }

  // title1 "..." and footnote1 "..." statements
  for (const match of content.matchAll(/(?:title|footnote)\d*\s+"([^"]+)"/gi)) {
    results.push(normalizeWhitespace(match[1]))
  }

  return [...new Set(results)]
}

function extractFilterConditions(content: string): string[] {
  const conditions: string[] = []

  // where = (...) clauses
  for (const match of content.matchAll(/where\s*=\s*\(?\s*(.+?)\s*\)?[\),;]/gi)) {
    conditions.push(normalizeWhitespace(match[1]))
  }

  // Population macro references
  for (const match of content.matchAll(/&(saf_cond|fas_cond|enr_cond|itt_cond|pp_cond)\b\.?/gi)) {
    conditions.push(`&${match[1]}`)
  }

  // Flag filters
  for (const match of content.matchAll(/(trtemfl|anl\d+fl|aeser|aesdth|aeacn|saffl|fasfl|enrfl)\s*(?:=|eq|in)\s*['"]?([^'";\s]+)['"]?/gi)) {
    conditions.push(`${match[1]}=${match[2]}`)
  }

  return [...new Set(conditions)]
}

function extractParameters(content: string): string[] {
  const params: string[] = []

  // paramcd values in quotes or comparisons
  for (const match of content.matchAll(/paramcd\s*(?:=|eq|in\s*\()\s*["']([^"']+)["']/gi)) {
    params.push(match[1])
  }
  for (const match of content.matchAll(/paramcd\s+IN\s*\(\s*["']([^)]+)\)/gi)) {
    for (const p of match[1].split(/["']\s+["']/)) {
      params.push(p.replace(/["']/g, "").trim())
    }
  }

  // parcat1 values
  for (const match of content.matchAll(/parcat1\s*(?:=|eq)\s*["']([^"']+)["']/gi)) {
    params.push(`parcat1:${match[1]}`)
  }

  // %let parameters = ... patterns
  for (const match of content.matchAll(/%let\s+parameters?\s*=\s*([^;]+)/gi)) {
    for (const p of match[1].split(/\s+/)) {
      const cleaned = p.trim()
      if (cleaned.length > 0) params.push(cleaned)
    }
  }

  return [...new Set(params)]
}

function extractAnalysisVariables(content: string): string[] {
  const vars: string[] = []
  const knownVars = ["aval", "chg", "pchg", "base", "ablfl", "aedecod", "aesev", "aebodsys", "aesoc", "aeptcd", "cnsr", "avalc"]

  for (const v of knownVars) {
    if (new RegExp(`\\b${v}\\b`, "i").test(content)) {
      vars.push(v)
    }
  }

  return vars
}

function extractVisitTimepoints(content: string): string[] {
  const timepoints: string[] = []

  // avisitn in (...) lists
  for (const match of content.matchAll(/avisitn\s+in\s*\(([^)]+)\)/gi)) {
    timepoints.push(`avisitn: ${normalizeWhitespace(match[1])}`)
  }

  // aphase = 'Week 1-12' patterns
  for (const match of content.matchAll(/aphase\s*=\s*['"]([^'"]+)['"]/gi)) {
    timepoints.push(match[1])
  }

  // timelist = 28 56 84 ... patterns
  for (const match of content.matchAll(/timelist\s*=\s*([^;]+)/gi)) {
    const days = normalizeWhitespace(match[1]).split(/\s+/).map(Number).filter(Boolean)
    if (days.length > 0) {
      timepoints.push(`timelist (days): ${days.join(", ")}`)
    }
  }

  return [...new Set(timepoints)]
}

function buildKeywords(
  purpose: string,
  datasetsUsed: string[],
  outputFamilies: string[],
  statisticalMethods: string[],
  parameters: string[],
  analysisVariables: string[],
): string[] {
  const purposeKeywords = purpose
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((token) => token.length >= 4)
    .slice(0, 8)

  return [...new Set([
    ...purposeKeywords,
    ...datasetsUsed.map((dataset) => dataset.toLowerCase()),
    ...outputFamilies,
    ...statisticalMethods.map((m) => m.toLowerCase()),
    ...parameters.map((p) => p.toLowerCase()),
    ...analysisVariables,
  ])]
}

export function parseSasPrograms(sources: SasProgramSource[]): SasProgramRecord[] {
  return sources
    .map((source) => {
      const name = extractProgramName(source.content)
      const purpose = extractPurpose(source.content)
      const datasetsUsed = extractDatasetsUsed(source.content)
      const outputFamilies = extractOutputFamilies(source, purpose)
      const { studyNumber, compound } = extractStudyMetadata(source.content)
      const statisticalMethods = extractStatisticalMethods(source.content)
      const titlesAndFootnotes = extractTitlesAndFootnotes(source.content)
      const filterConditions = extractFilterConditions(source.content)
      const parameters = extractParameters(source.content)
      const analysisVariables = extractAnalysisVariables(source.content)
      const visitTimepoints = extractVisitTimepoints(source.content)

      return {
        name,
        path: source.path,
        title: purpose || name,
        purpose: purpose || name,
        datasetsUsed,
        outputFamilies,
        keywords: buildKeywords(purpose, datasetsUsed, outputFamilies, statisticalMethods, parameters, analysisVariables),
        sourceText: source.content,
        studyNumber,
        compound,
        statisticalMethods,
        titlesAndFootnotes,
        filterConditions,
        parameters,
        analysisVariables,
        visitTimepoints,
      }
    })
    .filter((program) => program.name.length > 0)
}
