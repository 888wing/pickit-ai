"use client"

import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ArrowRight, Download, Sparkles, Clock, Brain, Shield } from "lucide-react"
import Link from "next/link"

export default function Hero() {
  return (
    <section className="pt-32 pb-20 px-4">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center space-y-6">
          {/* Beta Badge */}
          <Badge variant="secondary" className="text-sm px-4 py-1">
            🚀 MVP Beta Now Available - Free Trial Limited Time
          </Badge>

          {/* Main Heading */}
          <h1 className="text-5xl md:text-7xl font-bold bg-gradient-to-r from-gray-900 to-gray-600 dark:from-gray-100 dark:to-gray-400 bg-clip-text text-transparent">
            AI-Powered Photo Selection
            <br />
            <span className="text-primary">Save 80% of Your Time</span>
          </h1>

          {/* Subtitle */}
          <p className="text-xl md:text-2xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto">
            Pickit uses advanced AI technology to automatically identify and select high-quality photos.
            A Lightroom Classic plugin designed for professional photographers.
          </p>

          {/* Key Features */}
          <div className="flex flex-wrap justify-center gap-4 py-6">
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Brain className="h-4 w-4 text-primary" />
              <span>NIMA AI Scoring</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Sparkles className="h-4 w-4 text-primary" />
              <span>Smart Grouping & Deduplication</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Clock className="h-4 w-4 text-primary" />
              <span>100+ photos/minute</span>
            </div>
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Shield className="h-4 w-4 text-primary" />
              <span>100% Local Processing</span>
            </div>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center pt-6">
            <Button size="lg" className="text-lg px-8">
              <Download className="mr-2 h-5 w-5" />
              One-Click Install (macOS)
            </Button>
            <Button size="lg" variant="outline" className="text-lg px-8">
              View Installation Guide
              <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-8 max-w-2xl mx-auto pt-12">
            <div className="text-center">
              <div className="text-3xl font-bold text-primary">85%+</div>
              <div className="text-sm text-gray-600">Accuracy</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-primary">500+</div>
              <div className="text-sm text-gray-600">Beta Users</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-primary">50K+</div>
              <div className="text-sm text-gray-600">Photos Processed</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}