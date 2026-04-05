// @vitest-environment jsdom

import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import { QuestionForm } from "@/components/copilot/question-form"
import { demoPrompts } from "@/lib/copilot/demo-prompts"

// Mock next/image to render a plain <img>
vi.mock("next/image", () => ({
  __esModule: true,
  default: (props: React.ImgHTMLAttributes<HTMLImageElement>) => <img {...props} />,
}))

describe("header", () => {
  function renderHeader() {
    // Reproduces the header markup from app/page.tsx
    return render(
      <header className="app-header">
        <div className="flex items-center gap-3">
          <img src="/logos/Logo_Bayer.svg" alt="Bayer" width={36} height={36} />
          <div>
            <p>Regulatory-Response Copilot</p>
            <p>Grounded planning aid for SPA and biostatistics teams</p>
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-4">
          <span className="trust-item">Grounded in repo evidence</span>
          <span className="trust-item">Server-side reasoning</span>
          <span className="trust-item">Corpus: README + Define-XML + 10 SAS examples</span>
        </div>
      </header>,
    )
  }

  it("renders the Bayer logo", () => {
    renderHeader()
    expect(screen.getByAltText("Bayer")).toBeInTheDocument()
  })

  it("renders the product title", () => {
    renderHeader()
    expect(screen.getByText("Regulatory-Response Copilot")).toBeInTheDocument()
  })

  it("renders all trust strip items", () => {
    renderHeader()
    expect(screen.getByText("Grounded in repo evidence")).toBeInTheDocument()
    expect(screen.getByText("Server-side reasoning")).toBeInTheDocument()
    expect(screen.getByText("Corpus: README + Define-XML + 10 SAS examples")).toBeInTheDocument()
  })
})

describe("question form", () => {
  const defaultProps = {
    error: null,
    formAction: vi.fn(),
    onInterrupt: vi.fn(),
    onRebuild: vi.fn(),
    pending: false,
    question: "",
    rebuildResult: null,
    rebuilding: false,
    samplePrompts: demoPrompts,
    setQuestion: vi.fn(),
    detectedQuestions: [],
    setDetectedQuestions: vi.fn(),
    onBatchSubmit: vi.fn(),
    uploadPending: false,
    setUploadPending: vi.fn(),
  }

  it("renders the scope-boundary copy", () => {
    render(<QuestionForm {...defaultProps} />)
    expect(
      screen.getByText(/produces a traceable starter plan - not final authority-facing text/),
    ).toBeInTheDocument()
  })

  it("renders the textarea and submit button", () => {
    render(<QuestionForm {...defaultProps} />)
    expect(screen.getByRole("textbox")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Run Copilot" })).toBeInTheDocument()
  })

  it("renders all 6 demo prompt chips", () => {
    render(<QuestionForm {...defaultProps} />)
    for (const prompt of demoPrompts) {
      expect(screen.getByText(prompt.label)).toBeInTheDocument()
    }
    // Verify exactly 6
    expect(demoPrompts).toHaveLength(6)
  })
})
