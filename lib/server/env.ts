import "server-only"

import { z } from "zod"

const serverEnvSchema = z.object({
  MGA_EMBEDDING_MODEL: z
    .string()
    .trim()
    .min(1)
    .optional(),
  MGA_MODEL: z
    .string()
    .trim()
    .min(1)
    .optional(),
  MGA_TOKEN: z
    .string()
    .trim()
    .min(1)
    .optional(),
})

export type ServerEnv = z.infer<typeof serverEnvSchema>

let cachedEnv: ServerEnv | null = null

export function getServerEnv(): ServerEnv {
  if (cachedEnv) {
    return cachedEnv
  }

  cachedEnv = serverEnvSchema.parse({
    MGA_EMBEDDING_MODEL: process.env.MGA_EMBEDDING_MODEL,
    MGA_MODEL: process.env.MGA_MODEL,
    MGA_TOKEN: process.env.MGA_TOKEN,
  })

  return cachedEnv
}

