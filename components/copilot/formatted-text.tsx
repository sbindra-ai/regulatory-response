/**
 * Parses LLM output that uses "- Section: content" patterns into
 * a structured list with bold headings and bullet points.
 */
export function FormattedText({ text }: { text: string }) {
  const parts = text.split(/\s-\s(?=[A-Z])/)
  if (parts.length <= 1) {
    return <span>{text}</span>
  }

  const intro = parts[0]
  const items = parts.slice(1)

  return (
    <div className="space-y-1.5">
      <p>{intro}</p>
      <ul className="space-y-0.5 text-[0.875rem] leading-snug">
        {items.map((item, i) => {
          const colonIdx = item.indexOf(":")
          if (colonIdx > 0 && colonIdx < 40) {
            const heading = item.slice(0, colonIdx)
            const body = item.slice(colonIdx + 1).trim()
            if (!body) {
              return (
                <li key={i} className="list-none pt-2 first:pt-0">
                  <strong className="font-semibold text-foreground">{heading}</strong>
                </li>
              )
            }
            return (
              <li key={i} className="flex gap-2 pl-1">
                <span className="mt-0.5 shrink-0 text-muted-foreground/50">&bull;</span>
                <span><strong className="font-semibold text-foreground">{heading}:</strong> {body}</span>
              </li>
            )
          }
          return (
            <li key={i} className="flex gap-2 pl-1">
              <span className="mt-0.5 shrink-0 text-muted-foreground/50">&bull;</span>
              <span>{item}</span>
            </li>
          )
        })}
      </ul>
    </div>
  )
}
