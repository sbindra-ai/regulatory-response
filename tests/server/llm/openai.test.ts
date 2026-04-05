import { afterEach, describe, expect, it, vi } from "vitest"
import { z } from "zod"

const responseSchema = z.object({
  ok: z.boolean(),
})

describe("generateStructuredObject", () => {
  afterEach(() => {
    vi.clearAllMocks()
    vi.restoreAllMocks()
    vi.resetModules()
    vi.unstubAllEnvs()
  })

  it("returns null and logs metadata when MGA_TOKEN is not configured", async () => {
    const info = vi.spyOn(console, "info").mockImplementation(() => {})

    vi.doMock("openai", () => ({
      default: vi.fn(),
    }))

    const { generateStructuredObject } = await import("@/lib/server/llm/openai")

    await expect(
      generateStructuredObject({
        schema: responseSchema,
        systemPrompt: "Return JSON only.",
        userPrompt: 'Return {"ok": true}.',
      }),
    ).resolves.toBeNull()

    expect(info).toHaveBeenCalledWith(
      expect.objectContaining({
        baseUrlHost: "chat.int.bayer.com",
        event: "mga.request.skipped",
        hasToken: false,
        maxTokens: 100000,
        model: "gpt-5",
        systemPromptLength: 17,
        userPromptLength: 20,
      }),
    )
  })

  it("uses the Bayer v2 base URL and GPT-5 by default and logs start plus success metadata", async () => {
    vi.stubEnv("MGA_TOKEN", "test-token")

    const info = vi.spyOn(console, "info").mockImplementation(() => {})

    const create = vi.fn().mockResolvedValue({
      choices: [
        {
          message: {
            content: '{"ok": true}',
          },
        },
      ],
      usage: {
        prompt_tokens: 42,
        completion_tokens: 10,
        total_tokens: 52,
      },
    })
    const OpenAI = vi.fn().mockImplementation(() => ({
      chat: {
        completions: {
          create,
        },
      },
    }))

    vi.doMock("openai", () => ({
      default: OpenAI,
    }))

    const { generateStructuredObject } = await import("@/lib/server/llm/openai")

    await expect(
      generateStructuredObject({
        runId: "run-123",
        schema: responseSchema,
        stage: "interpret-request",
        systemPrompt: "Return JSON only.",
        userPrompt: 'Return {"ok": true}.',
      }),
    ).resolves.toEqual({
      data: { ok: true },
      usage: { promptTokens: 42, completionTokens: 10, totalTokens: 52 },
    })

    expect(OpenAI).toHaveBeenCalledWith({
      apiKey: "test-token",
      baseURL: "https://chat.int.bayer.com/api/v2",
    })
    expect(create).toHaveBeenCalledWith(
      expect.objectContaining({
        max_tokens: 100000,
        model: "gpt-5",
        response_format: {
          type: "json_object",
        },
      }),
    )

    expect(info).toHaveBeenCalledWith(
      expect.objectContaining({
        event: "mga.request.started",
        maxTokens: 100000,
        model: "gpt-5",
        runId: "run-123",
        stage: "interpret-request",
      }),
    )
    expect(info).toHaveBeenCalledWith(
      expect.objectContaining({
        event: "mga.request.succeeded",
        latencyMs: expect.any(Number),
        responseTextLength: 12,
        runId: "run-123",
        stage: "interpret-request",
      }),
    )
  })

  it("logs safe failure metadata when the MGA request fails", async () => {
    vi.stubEnv("MGA_TOKEN", "test-token")

    const error = Object.assign(new Error("socket hang up"), {
      name: "APIConnectionError",
      status: 503,
    })
    const create = vi.fn().mockRejectedValue(error)
    const errorLog = vi.spyOn(console, "error").mockImplementation(() => {})
    const OpenAI = vi.fn().mockImplementation(() => ({
      chat: {
        completions: {
          create,
        },
      },
    }))

    vi.doMock("openai", () => ({
      default: OpenAI,
    }))

    const { generateStructuredObject } = await import("@/lib/server/llm/openai")

    await expect(
      generateStructuredObject({
        runId: "run-err",
        schema: responseSchema,
        stage: "generate-plan",
        systemPrompt: "Return JSON only.",
        userPrompt: 'Return {"ok": true}.',
      }),
    ).rejects.toThrow("socket hang up")

    expect(errorLog).toHaveBeenCalledWith(
      expect.objectContaining({
        errorName: "APIConnectionError",
        event: "mga.request.failed",
        failureKind: "transport",
        hasErrorDetails: true,
        runId: "run-err",
        stage: "generate-plan",
        statusCode: 503,
      }),
    )
  })
})
