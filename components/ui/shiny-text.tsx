import type { ReactNode } from "react"

type ShinyTextProps = {
  children: ReactNode
  className?: string
  speed?: number
}

export function ShinyText({ children, className = "", speed = 3 }: ShinyTextProps) {
  return (
    <span
      className={`shiny-text ${className}`}
      style={{ animationDuration: `${speed}s` }}
    >
      {children}
    </span>
  )
}
