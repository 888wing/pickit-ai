"use client"

import Hero from "@/components/sections/Hero"
import Features from "@/components/sections/Features"
import VideoDemo from "@/components/sections/VideoDemo"
import Installation from "@/components/sections/Installation"
import Roadmap from "@/components/sections/Roadmap"
import Footer from "@/components/sections/Footer"
import Navigation from "@/components/sections/Navigation"

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-gray-50 to-white dark:from-gray-900 dark:to-gray-800">
      <Navigation />
      <Hero />
      <Features />
      <VideoDemo />
      <Installation />
      <Roadmap />
      <Footer />
    </main>
  )
}