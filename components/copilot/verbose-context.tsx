"use client"

import { createContext, useContext, useState, type ReactNode } from "react"

type VerboseContextValue = {
  verbose: boolean
  setVerbose: (value: boolean) => void
}

const VerboseContext = createContext<VerboseContextValue>({
  verbose: false,
  setVerbose: () => {},
})

export function VerboseProvider({ children }: { children: ReactNode }) {
  const [verbose, setVerbose] = useState(false)
  return (
    <VerboseContext.Provider value={{ verbose, setVerbose }}>
      {children}
    </VerboseContext.Provider>
  )
}

export function useVerbose() {
  return useContext(VerboseContext)
}

export function VerboseToggle() {
  const { verbose, setVerbose } = useVerbose()
  return (
    <label className="flex cursor-pointer items-center gap-2 select-none">
      <span className="text-xs font-semibold text-muted-foreground">Explain outputs</span>
      <button
        type="button"
        role="switch"
        aria-checked={verbose}
        onClick={() => setVerbose(!verbose)}
        className={`relative inline-flex h-5 w-9 shrink-0 items-center rounded-full border transition-colors duration-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary ${
          verbose
            ? "border-[#00BCFF]/40 bg-[#00BCFF]"
            : "border-border bg-muted"
        }`}
      >
        <span
          className={`inline-block h-3.5 w-3.5 rounded-full bg-white shadow-sm transition-transform duration-200 ${
            verbose ? "translate-x-[18px]" : "translate-x-[3px]"
          }`}
        />
      </button>
    </label>
  )
}

export function HelpIcon({ tooltip }: { tooltip: string }) {
  const { verbose } = useVerbose()
  if (!verbose) return null
  return (
    <span className="group/help relative ml-1.5 inline-flex">
      <span className="inline-flex h-4 w-4 items-center justify-center rounded-full bg-[#00BCFF]/10 text-[0.5625rem] font-bold text-[#00BCFF] transition-colors group-hover/help:bg-[#00BCFF]/20">
        ?
      </span>
      <span className="pointer-events-none absolute bottom-full left-1/2 z-50 mb-2 w-64 -translate-x-1/2 rounded-lg border border-border bg-white px-3 py-2 text-xs leading-relaxed text-foreground/80 opacity-0 shadow-lg transition-opacity group-hover/help:opacity-100">
        {tooltip}
        <span className="absolute left-1/2 top-full -translate-x-1/2 border-4 border-transparent border-t-white" />
      </span>
    </span>
  )
}
