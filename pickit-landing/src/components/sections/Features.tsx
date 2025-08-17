"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Brain, Zap, Users, Shield, Layers, RefreshCw } from "lucide-react"

const features = [
  {
    icon: Brain,
    title: "NIMA AI Dual Assessment",
    description: "Uses Google's NIMA model for both technical and aesthetic scoring to ensure the best photo selection"
  },
  {
    icon: Users,
    title: "Smart Face Detection",
    description: "Automatically detects face quality, identifies closed eyes and blur issues for perfect portraits"
  },
  {
    icon: Layers,
    title: "Similar Photo Grouping",
    description: "Intelligently identifies burst sequences and similar photos, automatically recommends the best from each group"
  },
  {
    icon: Zap,
    title: "Lightning-Fast Batch Processing",
    description: "Process over 100 photos per minute, dramatically improving workflow efficiency"
  },
  {
    icon: Shield,
    title: "100% Privacy Protection",
    description: "All processing happens locally, no photo uploads required, protecting client privacy"
  },
  {
    icon: RefreshCw,
    title: "Seamless Integration",
    description: "Perfectly integrates with Lightroom Classic workflow, maintaining your existing habits"
  }
]

export default function Features() {
  return (
    <section id="features" className="py-20 px-4 bg-gray-50 dark:bg-gray-900">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Core Features
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-300">
            Intelligent tools designed for professional photographers
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <Card key={index} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="h-12 w-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4">
                  <feature.icon className="h-6 w-6 text-primary" />
                </div>
                <CardTitle className="text-xl">{feature.title}</CardTitle>
              </CardHeader>
              <CardContent>
                <CardDescription className="text-base">
                  {feature.description}
                </CardDescription>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}