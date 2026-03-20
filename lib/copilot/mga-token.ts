const MGA_TOKEN_KEY = "mga-token"

export function getMgaToken(): string {
  try {
    return localStorage.getItem(MGA_TOKEN_KEY) ?? ""
  } catch {
    return ""
  }
}

export function setMgaToken(token: string) {
  try {
    if (token) {
      localStorage.setItem(MGA_TOKEN_KEY, token)
    } else {
      localStorage.removeItem(MGA_TOKEN_KEY)
    }
  } catch {
    // localStorage unavailable (SSR or restricted context)
  }
}
