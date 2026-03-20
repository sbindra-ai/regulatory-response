import "server-only"

type LogLevel = "error" | "info" | "warn"
type LogValue = boolean | number | string | null | undefined

export type LogMetadata = Record<string, LogValue>

function emit(level: LogLevel, payload: LogMetadata & { event: string; timestamp: string }): void {
  try {
    switch (level) {
      case "error":
        console.error(payload)
        return
      case "warn":
        console.warn(payload)
        return
      case "info":
        console.info(payload)
        return
      default:
        return
    }
  } catch {
    return
  }
}

export function logServerEvent(level: LogLevel, event: string, metadata: LogMetadata = {}): void {
  emit(level, {
    ...metadata,
    event,
    timestamp: new Date().toISOString(),
  })
}
