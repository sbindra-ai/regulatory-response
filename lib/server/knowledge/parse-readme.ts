export type ReadmeBrief = {
  id: "brief:product"
  title: string
  path: "README.md"
  summary: string
  keywords: string[]
  sourceText: string
}

function normalizeWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim()
}

export function parseReadme(readmeContent: string): ReadmeBrief {
  const lines = readmeContent.split("\n")
  const title = lines.find((line) => line.startsWith("# "))?.replace(/^#\s*/, "").trim() ?? "Regulatory Response Copilot"
  const summaryLine =
    lines
      .slice(lines.findIndex((line) => line.startsWith("# ")) + 1)
      .find((line) => line.trim().length > 0 && !line.startsWith("##")) ?? ""

  return {
    id: "brief:product",
    title,
    path: "README.md",
    summary: normalizeWhitespace(summaryLine),
    keywords: [
      "regulatory",
      "response",
      "spa",
      "knowledge-search",
      "response-plan",
      "copilot",
    ],
    sourceText: readmeContent,
  }
}
