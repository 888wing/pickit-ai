import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "@/app/globals.css"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Pickit - AI 驅動的智能選片工具 | Lightroom 插件",
  description: "為專業攝影師打造的 AI 選片助手，節省 80% 後期時間。使用 Google NIMA 模型進行美學和技術雙重評分，完美整合 Lightroom Classic 工作流程。",
  keywords: "Pickit, Lightroom, 選片, AI, 攝影, 後期處理, NIMA, 智能選片, 人臉檢測, 批次處理",
  authors: [{ name: "Pickit Team" }],
  openGraph: {
    title: "Pickit - AI 驅動的智能選片工具",
    description: "節省 80% 後期時間，讓 AI 幫您挑選最佳照片",
    url: "https://pickit.ai",
    siteName: "Pickit",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "Pickit - AI Photo Selection"
      }
    ],
    locale: "zh_TW",
    type: "website"
  },
  twitter: {
    card: "summary_large_image",
    title: "Pickit - AI 驅動的智能選片工具",
    description: "節省 80% 後期時間，讓 AI 幫您挑選最佳照片",
    images: ["/og-image.png"]
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1
    }
  }
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-TW">
      <body className={inter.className}>{children}</body>
    </html>
  )
}