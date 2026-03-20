"use client"

import { useEffect, useRef, useState } from "react"

import { runFollowUpAction } from "@/app/actions/run-follow-up"
import { getMgaToken } from "@/lib/copilot/mga-token"
import type { CopilotResult, FollowUpMessage } from "@/lib/server/copilot/schemas"

/** Lightweight markdown renderer for chat messages — handles bold, italic, code, bullets, and paragraphs. */
function ChatMarkdown({ text }: { text: string }) {
  const paragraphs = text.split(/\n\n+/)

  function renderInline(line: string) {
    // Split on **bold**, *italic*, and `code` patterns
    const parts = line.split(/(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)/)
    return parts.map((part, i) => {
      if (part.startsWith("**") && part.endsWith("**")) {
        return <strong key={i} className="font-semibold">{part.slice(2, -2)}</strong>
      }
      if (part.startsWith("*") && part.endsWith("*")) {
        return <em key={i}>{part.slice(1, -1)}</em>
      }
      if (part.startsWith("`") && part.endsWith("`")) {
        return <code key={i} className="rounded bg-muted px-1 py-0.5 text-[0.8125rem]">{part.slice(1, -1)}</code>
      }
      return <span key={i}>{part}</span>
    })
  }

  return (
    <div className="space-y-2 text-[0.875rem] leading-relaxed">
      {paragraphs.map((para, pi) => {
        const lines = para.split("\n")
        const isList = lines.every((l) => /^[-•]\s/.test(l.trim()))

        if (isList) {
          return (
            <ul key={pi} className="space-y-0.5 pl-4">
              {lines.map((line, li) => (
                <li key={li} className="list-disc text-foreground/85">
                  {renderInline(line.replace(/^[-•]\s*/, ""))}
                </li>
              ))}
            </ul>
          )
        }

        return <p key={pi}>{lines.map((line, li) => (
          <span key={li}>{li > 0 && <br />}{renderInline(line)}</span>
        ))}</p>
      })}
    </div>
  )
}

type FollowUpChatProps = {
  copilotResult: CopilotResult
  originalQuestion: string
}

export function FollowUpChat({ copilotResult, originalQuestion }: FollowUpChatProps) {
  const [messages, setMessages] = useState<FollowUpMessage[]>([])
  const [input, setInput] = useState("")
  const [pending, setPending] = useState(false)
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" })
  }, [messages])

  async function handleSend() {
    const text = input.trim()
    if (!text || pending) return

    const userMessage: FollowUpMessage = { role: "user", content: text }
    const updatedHistory = [...messages, userMessage]
    setMessages(updatedHistory)
    setInput("")
    setPending(true)

    try {
      const result = await runFollowUpAction(originalQuestion, copilotResult, messages, text, getMgaToken() || undefined)
      if (result.answer) {
        setMessages((prev) => [...prev, { role: "assistant", content: result.answer! }])
      } else if (result.error) {
        setMessages((prev) => [...prev, { role: "assistant", content: `Error: ${result.error}` }])
      }
    } catch {
      setMessages((prev) => [...prev, { role: "assistant", content: "Failed to generate a response. Please try again." }])
    } finally {
      setPending(false)
    }
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  return (
    <div className="mt-6 rounded-xl border border-border/60 bg-white shadow-[0_1px_3px_rgba(16,56,79,0.04)]">
      <div className="border-b border-border/40 px-5 py-3">
        <h3 className="text-[0.8125rem] font-semibold text-foreground/70">
          Follow-up Discussion
        </h3>
        <p className="text-[0.75rem] text-muted-foreground">
          Ask questions about this plan, explore alternatives, or refine the approach.
        </p>
      </div>

      {messages.length > 0 && (
        <div ref={scrollRef} className="max-h-96 space-y-3 overflow-y-auto px-5 py-4">
          {messages.map((msg, i) => (
            <div key={i} className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}>
              <div
                className={`max-w-[85%] rounded-lg px-4 py-2.5 text-[0.9375rem] leading-relaxed ${
                  msg.role === "user"
                    ? "bg-[#10384F] text-white"
                    : "border border-border/40 bg-muted/50 text-foreground"
                }`}
              >
                {msg.role === "assistant" ? (
                  <ChatMarkdown text={msg.content} />
                ) : (
                  msg.content
                )}
              </div>
            </div>
          ))}
          {pending && (
            <div className="flex justify-start">
              <div className="rounded-lg border border-border/40 bg-muted/50 px-4 py-2.5">
                <span className="inline-flex items-center gap-1 text-sm text-muted-foreground">
                  <span className="inline-block h-1.5 w-1.5 animate-bounce rounded-full bg-muted-foreground [animation-delay:0ms]" />
                  <span className="inline-block h-1.5 w-1.5 animate-bounce rounded-full bg-muted-foreground [animation-delay:150ms]" />
                  <span className="inline-block h-1.5 w-1.5 animate-bounce rounded-full bg-muted-foreground [animation-delay:300ms]" />
                </span>
              </div>
            </div>
          )}
        </div>
      )}

      <div className="flex items-center gap-2 border-t border-border/40 px-4 py-3">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Ask a follow-up question about this plan..."
          disabled={pending}
          className="focus-ring flex-1 rounded-lg border border-border/70 bg-muted/30 px-3 py-2 text-[0.9375rem] text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-[#00BCFF]/50 disabled:opacity-60"
        />
        <button
          type="button"
          onClick={handleSend}
          disabled={pending || !input.trim()}
          className="focus-ring h-9 cursor-pointer rounded-lg bg-[#10384F] px-4 text-[0.8125rem] font-semibold text-white transition-all hover:bg-[#10384F]/90 active:scale-[0.98] disabled:pointer-events-none disabled:opacity-50"
        >
          Send
        </button>
      </div>
    </div>
  )
}
