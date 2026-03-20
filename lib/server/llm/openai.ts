import "server-only"

import OpenAI from "openai"
import type { ZodType } from "zod"

import { getServerEnv } from "@/lib/server/env"
import { logServerEvent } from "@/lib/server/logger"
import { getMgaTokenOverride } from "@/lib/server/mga-token-context"

const MGA_BASE_URL = "https://chat.int.bayer.com/api/v2"
const DEFAULT_MGA_MODEL = "gpt-5"
const DEFAULT_MGA_EMBEDDING_MODEL = "text-embedding-3-small"

export type LlmTokenUsage = {
  promptTokens: number
  completionTokens: number
  totalTokens: number
}

type GenerateStructuredObjectInput<TSchema> = {
  maxTokens?: number
  runId?: string
  schema: ZodType<TSchema>
  stage?: string
  systemPrompt: string
  temperature?: number
  userPrompt: string
}

type GenerateStructuredObjectResult<TSchema> = {
  data: TSchema
  usage: LlmTokenUsage
}

type MessageContent =
  | string
  | Array<
      | { type: "text"; text: string }
      | { type: "image_url"; image_url: { url: string } }
    >

type OpenAIClient = {
  chat: {
    completions: {
      create: (input: {
        max_tokens: number
        messages: Array<{ content: MessageContent; role: "system" | "user" }>
        model: string
        response_format?: { type: "json_object" }
        temperature?: number
      }) => Promise<{
        choices: Array<{
          message: {
            content: string | null
          }
        }>
        usage?: {
          prompt_tokens: number
          completion_tokens: number
          total_tokens: number
        } | null
      }>
    }
  }
  embeddings: {
    create: (input: {
      input: string | string[]
      model: string
    }) => Promise<{
      data: Array<{
        embedding: number[]
      }>
      usage?: {
        prompt_tokens: number
        total_tokens: number
      } | null
    }>
  }
}

type OpenAIConstructor = {
  new (config: { apiKey: string; baseURL: string }): OpenAIClient
  (config: { apiKey: string; baseURL: string }): OpenAIClient
}

function extractJsonBlock(content: string): string {
  const match = content.match(/\{[\s\S]*\}/)

  if (!match) {
    throw new Error("OpenAI response did not contain a JSON object.")
  }

  return match[0]
}

function createOpenAiClient(config: { apiKey: string; baseURL: string }): OpenAIClient {
  const OpenAIClient = OpenAI as unknown as OpenAIConstructor

  try {
    return new OpenAIClient(config)
  } catch (error) {
    if (error instanceof TypeError && error.message.includes("not a constructor")) {
      return OpenAIClient(config)
    }

    throw error
  }
}

function buildBaseLogMetadata({
  hasToken,
  maxTokens,
  model,
  runId,
  stage,
  systemPrompt,
  userPrompt,
}: {
  hasToken: boolean
  maxTokens: number
  model: string
  runId?: string
  stage?: string
  systemPrompt: string
  userPrompt: string
}) {
  return {
    baseUrlHost: new URL(MGA_BASE_URL).host,
    hasToken,
    maxTokens,
    model,
    runId,
    stage,
    systemPromptLength: systemPrompt.length,
    userPromptLength: userPrompt.length,
  }
}

function getFailureKind(error: unknown): string {
  if (error instanceof SyntaxError) {
    return "invalid-json"
  }

  if (error instanceof Error && error.message === "OpenAI response did not contain a JSON object.") {
    return "missing-json-object"
  }

  if (error instanceof Error && error.name === "ZodError") {
    return "schema-parse"
  }

  if (error instanceof Error && /connection|timeout|network|socket|api/i.test(error.name + error.message)) {
    return "transport"
  }

  return "unknown"
}

function getStatusCode(error: unknown): number | undefined {
  if (typeof error === "object" && error !== null && "status" in error && typeof error.status === "number") {
    return error.status
  }

  return undefined
}

export async function generateEmbeddings(input: string | string[]): Promise<number[][] | null> {
  const env = getServerEnv()
  const MGA_EMBEDDING_MODEL = env.MGA_EMBEDDING_MODEL
  const MGA_TOKEN = getMgaTokenOverride() || env.MGA_TOKEN
  const model = MGA_EMBEDDING_MODEL ?? DEFAULT_MGA_EMBEDDING_MODEL

  if (!MGA_TOKEN) {
    logServerEvent("info", "mga.embeddings.skipped", { reason: "no-token" })
    return null
  }

  const client = createOpenAiClient({ apiKey: MGA_TOKEN, baseURL: MGA_BASE_URL })
  const startedAt = Date.now()

  logServerEvent("info", "mga.embeddings.started", {
    inputCount: Array.isArray(input) ? input.length : 1,
    model,
  })

  try {
    const response = await client.embeddings.create({ input, model })
    const embeddings = response.data.map((item) => item.embedding)

    logServerEvent("info", "mga.embeddings.succeeded", {
      dimensions: embeddings[0]?.length ?? 0,
      latencyMs: Date.now() - startedAt,
      resultCount: embeddings.length,
    })

    return embeddings
  } catch (error) {
    logServerEvent("error", "mga.embeddings.failed", {
      errorName: error instanceof Error ? error.name : "UnknownError",
      latencyMs: Date.now() - startedAt,
      statusCode: getStatusCode(error),
    })
    throw error
  }
}

export async function generateTextFromVision(input: {
  systemPrompt: string
  userPrompt: string
  imageBase64: string
  mimeType: string
  maxTokens?: number
}): Promise<{ text: string; usage: LlmTokenUsage } | null> {
  const env = getServerEnv()
  const MGA_MODEL = env.MGA_MODEL
  const MGA_TOKEN = getMgaTokenOverride() || env.MGA_TOKEN
  const model = MGA_MODEL ?? DEFAULT_MGA_MODEL

  if (!MGA_TOKEN) {
    logServerEvent("info", "mga.vision.skipped", { reason: "no-token" })
    return null
  }

  const client = createOpenAiClient({ apiKey: MGA_TOKEN, baseURL: MGA_BASE_URL })
  const startedAt = Date.now()

  logServerEvent("info", "mga.vision.started", { model, mimeType: input.mimeType })

  try {
    const response = await client.chat.completions.create({
      max_tokens: input.maxTokens ?? 4000,
      messages: [
        { role: "system", content: input.systemPrompt },
        {
          role: "user",
          content: [
            { type: "text", text: input.userPrompt },
            {
              type: "image_url",
              image_url: { url: `data:${input.mimeType};base64,${input.imageBase64}` },
            },
          ],
        },
      ],
      model,
    })

    const text = response.choices
      .map((c) => c.message.content)
      .filter((c): c is string => typeof c === "string")
      .join("\n")

    const usage: LlmTokenUsage = {
      promptTokens: response.usage?.prompt_tokens ?? 0,
      completionTokens: response.usage?.completion_tokens ?? 0,
      totalTokens: response.usage?.total_tokens ?? 0,
    }

    logServerEvent("info", "mga.vision.succeeded", {
      latencyMs: Date.now() - startedAt,
      responseLength: text.length,
    })

    return { text, usage }
  } catch (error) {
    logServerEvent("error", "mga.vision.failed", {
      errorName: error instanceof Error ? error.name : "UnknownError",
      latencyMs: Date.now() - startedAt,
      statusCode: getStatusCode(error),
    })
    throw error
  }
}

export async function generateStructuredObject<TSchema>({
  maxTokens = 64_000,
  runId,
  schema,
  stage,
  systemPrompt,
  temperature,
  userPrompt,
}: GenerateStructuredObjectInput<TSchema>): Promise<GenerateStructuredObjectResult<TSchema> | null> {
  const env = getServerEnv()
  const MGA_MODEL = env.MGA_MODEL
  const MGA_TOKEN = getMgaTokenOverride() || env.MGA_TOKEN
  const model = MGA_MODEL ?? DEFAULT_MGA_MODEL
  const baseLogMetadata = buildBaseLogMetadata({
    hasToken: Boolean(MGA_TOKEN),
    maxTokens,
    model,
    runId,
    stage,
    systemPrompt,
    userPrompt,
  })

  if (!MGA_TOKEN) {
    logServerEvent("info", "mga.request.skipped", baseLogMetadata)
    return null
  }

  const client = createOpenAiClient({
    apiKey: MGA_TOKEN,
    baseURL: MGA_BASE_URL,
  })
  const startedAt = Date.now()

  logServerEvent("info", "mga.request.started", baseLogMetadata)

  try {
    const response = await client.chat.completions.create({
      max_tokens: maxTokens,
      messages: [
        {
          role: "system",
          content: systemPrompt,
        },
        {
          role: "user",
          content: `${userPrompt}\n\nReturn JSON only.`,
        },
      ],
      model,
      response_format: {
        type: "json_object",
      },
      ...(temperature !== undefined ? { temperature } : {}),
    })

    const responseText = response.choices
      .map((choice) => choice.message.content)
      .filter((content): content is string => typeof content === "string")
      .join("\n")

    const parsed = schema.parse(JSON.parse(extractJsonBlock(responseText)))

    const usage: LlmTokenUsage = {
      promptTokens: response.usage?.prompt_tokens ?? 0,
      completionTokens: response.usage?.completion_tokens ?? 0,
      totalTokens: response.usage?.total_tokens ?? 0,
    }

    logServerEvent("info", "mga.request.succeeded", {
      ...baseLogMetadata,
      latencyMs: Date.now() - startedAt,
      responseTextLength: responseText.length,
      ...usage,
    })

    return { data: parsed, usage }
  } catch (error) {
    logServerEvent("error", "mga.request.failed", {
      ...baseLogMetadata,
      errorName: error instanceof Error ? error.name : "UnknownError",
      failureKind: getFailureKind(error),
      hasErrorDetails: error instanceof Error,
      latencyMs: Date.now() - startedAt,
      statusCode: getStatusCode(error),
    })
    throw error
  }
}
