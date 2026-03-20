import "server-only"

import { AsyncLocalStorage } from "node:async_hooks"

const mgaTokenStore = new AsyncLocalStorage<string | undefined>()

export function runWithMgaToken<T>(token: string | undefined, fn: () => T | Promise<T>): T | Promise<T> {
  return mgaTokenStore.run(token || undefined, fn)
}

export function getMgaTokenOverride(): string | undefined {
  return mgaTokenStore.getStore()
}
