export type DetectedQuestion = {
  id: string
  text: string
  source: "text" | "pdf" | "image"
  selected: boolean
}

const NUMBERED_PATTERN = /^\s*(\d+[\.\)]\s|Q\d+[:\.\)]\s|[a-z][\.\)]\s)/gm

const MAX_QUESTIONS = 20
const MAX_QUESTION_LENGTH = 3000

export function splitQuestions(
  rawText: string,
  source: "text" | "pdf" | "image" = "text",
): DetectedQuestion[] {
  const trimmed = rawText.trim()
  if (!trimmed) return []

  let blocks: string[]

  // Try numbered patterns first
  const matches = [...trimmed.matchAll(NUMBERED_PATTERN)]
  if (matches.length > 1) {
    blocks = []
    for (let i = 0; i < matches.length; i++) {
      const start = matches[i].index!
      const end = i + 1 < matches.length ? matches[i + 1].index! : trimmed.length
      blocks.push(trimmed.slice(start, end).trim())
    }
  } else {
    // Double-newline fallback
    const parts = trimmed.split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean)
    blocks = parts.length > 1 ? parts : [trimmed]
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
