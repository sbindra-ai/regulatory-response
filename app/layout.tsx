import type { Metadata } from "next"
import { Manrope, Source_Sans_3 } from "next/font/google"
import type { ReactNode } from "react"

import "./globals.css"

const displayFont = Manrope({
  subsets: ["latin"],
  variable: "--font-app-display",
  weight: ["400", "600", "700"],
  display: "swap",
})

const bodyFont = Source_Sans_3({
  subsets: ["latin"],
  variable: "--font-app-body",
  weight: ["400", "600", "700"],
  display: "swap",
})

export const metadata: Metadata = {
  title: "Regulatory-Response Copilot",
  description: "AI-powered regulatory response accelerator prototype.",
}

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="en" className={`${displayFont.variable} ${bodyFont.variable}`}>
      <body>{children}</body>
    </html>
  )
}
