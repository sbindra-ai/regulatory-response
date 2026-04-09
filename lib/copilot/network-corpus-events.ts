/** Fired on `window` after a successful network corpus rebuild so UI (e.g. Knowledge base stats) can refetch. */
export const NETWORK_CORPUS_REBUILT_EVENT = "regulatory-response:network-corpus-rebuilt"

export function dispatchNetworkCorpusRebuilt(): void {
  if (typeof window === "undefined") return
  window.dispatchEvent(new Event(NETWORK_CORPUS_REBUILT_EVENT))
}
