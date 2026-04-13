export type DetectedQuestion = {
  id: string
  text: string
  source: "text" | "pdf" | "image"
  selected: boolean
}

/** Line-start markers for enumerated questions (multiline). Digit+dot must not match "12. Ground" after "Week" wraps. */
const NUMBERED_PATTERN =
  /(?:^|\n)\s*(?:Q\d+[:\.\)]\s|(?:\d{1,3}[\.\)]\s+(?!Ground\b|of\s+\d+\b))|(?:[a-z][\.\)]\s))/gim

const MAX_QUESTIONS = 20
const MAX_QUESTION_LENGTH = 3000

/** Page / print footers that are not questions (e.g. "-- 1 of 1 --"). */
const PAGE_FOOTER_LINE =
  /^\s*(?:(?:--\s*)?\d+\s+of\s+\d+(?:\s*--)?|--+\s*\d+\s+of\s+\d+\s*--+|Page\s+\d+\s+of\s+\d+)\s*$/i

/** Hyphen / dash characters common in Word → PDF exports (inside compound words and separators). */
const PDF_HY_CC = "\\u2010\\u2011\\u2012\\u2013\\u2014\\u2212\\-"

/**
 * Start of a known multi-prompt PDF block (line or doc start).
 * Unicode-tolerant "follow-up" / "exposure-adjusted" (PDFs often use U+2010 etc. instead of ASCII -).
 * TEAE title must not match "Week 12 TEAE overall summary" inside another prompt's body.
 */
const PDF_QUESTION_HEADER_START = new RegExp(
  `(?:^|[\\r\\n])\\s*(Week\\s+\\d+\\s+TEAE\\s+overall(?!\\s+summary\\b)|Week\\s+\\d+\\s+SOC\\/PT\\s+table|Liver\\s*\\/\\s*laboratory\\s+follow[${PDF_HY_CC}]up|Starter\\s+Response\\s+Plan|EAIR\\s*\\/\\s*exposure[${PDF_HY_CC}]adjusted)`,
  "gi",
)

/** Title then body separator (Unicode/ASCII hyphen) — fallback split when present. */
const PDF_PROMPT_HEADER_SPLIT_STRICT = new RegExp(
  `[\\r\\n]+(?=\\s*(?:Week\\s+\\d+\\s+TEAE\\s+overall(?!\\s+summary\\b)|Week\\s+\\d+\\s+SOC\\/PT\\s+table|Liver\\s*\\/\\s*laboratory\\s+follow[${PDF_HY_CC}]up|Starter\\s+Response\\s+Plan|EAIR\\s*\\/\\s*exposure[${PDF_HY_CC}]adjusted)\\s*[${PDF_HY_CC}]\\s*)`,
  "i",
)

/** Title then body with only whitespace (hyphen dropped in extract). */
const PDF_PROMPT_HEADER_SPLIT_LOOSE = new RegExp(
  `[\\r\\n]+(?=\\s*(?:Week\\s+\\d+\\s+TEAE\\s+overall(?!\\s+summary\\b)|Week\\s+\\d+\\s+SOC\\/PT\\s+table|Liver\\s*\\/\\s*laboratory\\s+follow[${PDF_HY_CC}]up|Starter\\s+Response\\s+Plan|EAIR\\s*\\/\\s*exposure[${PDF_HY_CC}]adjusted)\\b\\s+)`,
  "i",
)

function stripPdfNoiseLines(text: string): string {
  const lines = text.replace(/\r\n/g, "\n").split("\n")
  const kept: string[] = []
  for (const line of lines) {
    const t = line.trim()
    if (t === "") {
      if (kept.length === 0 || kept[kept.length - 1] !== "") kept.push("")
      continue
    }
    if (PAGE_FOOTER_LINE.test(t)) continue
    kept.push(line)
  }
  return kept.join("\n").replace(/\n{3,}/g, "\n\n").trim()
}

function isNoiseQuestionBlock(text: string): boolean {
  const t = text.trim()
  if (t.length < 12) return true
  if (PAGE_FOOTER_LINE.test(t)) return true
  if (/^[\s\-–—_]+$/.test(t)) return true
  return false
}

function splitPdfQuestionBlocks(raw: string): string[] {
  const cleaned = stripPdfNoiseLines(raw)
  if (!cleaned) return []

  const matches = [...cleaned.matchAll(PDF_QUESTION_HEADER_START)]
  if (matches.length > 0) {
    const segments: string[] = []
    for (let i = 0; i < matches.length; i++) {
      const start = matches[i].index!
      const end = i + 1 < matches.length ? matches[i + 1].index! : cleaned.length
      const slice = cleaned.slice(start, end).replace(/^\n+/, "").trim()
      if (slice) segments.push(slice)
    }
    const filtered = segments.filter((p) => !isNoiseQuestionBlock(p))
    if (filtered.length > 0) return filtered
  }

  let parts = cleaned.split(PDF_PROMPT_HEADER_SPLIT_STRICT).map((p) => p.trim()).filter(Boolean)
  if (parts.length <= 1) {
    parts = cleaned.split(PDF_PROMPT_HEADER_SPLIT_LOOSE).map((p) => p.trim()).filter(Boolean)
  }
  return parts.filter((p) => !isNoiseQuestionBlock(p))
}

function splitGenericTextBlocks(trimmed: string): string[] {
  const matches = [...trimmed.matchAll(NUMBERED_PATTERN)]
  if (matches.length > 1) {
    const blocks: string[] = []
    for (let i = 0; i < matches.length; i++) {
      const start = matches[i].index!
      const end = i + 1 < matches.length ? matches[i + 1].index! : trimmed.length
      blocks.push(trimmed.slice(start, end).trim())
    }
    return blocks.filter((b) => !isNoiseQuestionBlock(b))
  }

  const parts = trimmed.split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean)
  return parts.length > 1 ? parts : [trimmed]
}

export function splitQuestions(
  rawText: string,
  source: "text" | "pdf" | "image" = "text",
): DetectedQuestion[] {
  const trimmed = rawText.trim()
  if (!trimmed) return []

  let blocks: string[]
  if (source === "pdf") {
    const pdfBlocks = splitPdfQuestionBlocks(trimmed)
    blocks = pdfBlocks.length > 0 ? pdfBlocks : splitGenericTextBlocks(stripPdfNoiseLines(trimmed))
    if (blocks.length === 1 && blocks[0] && isNoiseQuestionBlock(blocks[0])) blocks = []
    if (blocks.length === 0) blocks = splitGenericTextBlocks(trimmed)
  } else {
    blocks = splitGenericTextBlocks(trimmed)
  }

  blocks = blocks.filter((b) => b.length > 0 && !isNoiseQuestionBlock(b))

  if (blocks.length === 0 && trimmed.length > 0) {
    const fallback = source === "pdf" ? stripPdfNoiseLines(trimmed) : trimmed
    const fb = fallback.trim()
    if (fb && !isNoiseQuestionBlock(fb)) blocks = [fb]
  }

  return blocks
    .slice(0, MAX_QUESTIONS)
    .map((text) => ({
      id: crypto.randomUUID(),
      text: text.slice(0, MAX_QUESTION_LENGTH),
      source,
      selected: true,
    }))
}
