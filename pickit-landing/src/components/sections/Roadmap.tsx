"use client"

import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { CheckCircle, Circle, Clock, Rocket, Target, TrendingUp } from "lucide-react"

const roadmapData = [
  {
    version: "v1.0.0",
    title: "MVP Beta",
    status: "current",
    date: "2025 Q1",
    icon: Rocket,
    features: [
      { text: "Core AI scoring functionality", completed: true },
      { text: "Face detection", completed: true },
      { text: "Batch processing", completed: true },
      { text: "Similar photo grouping", completed: true },
      { text: "Auto-tagging and rating", completed: true },
      { text: "Feedback system", completed: true }
    ]
  },
  {
    version: "v1.5.0",
    title: "Performance Optimization",
    status: "upcoming",
    date: "2025 Q2",
    icon: TrendingUp,
    features: [
      { text: "GPU acceleration support", completed: false },
      { text: "Faster batch processing", completed: false },
      { text: "Improved UI/UX", completed: false },
      { text: "Custom AI models", completed: false },
      { text: "Cloud sync settings", completed: false },
      { text: "Multi-language support", completed: false }
    ]
  },
  {
    version: "v2.0.0",
    title: "Professional Edition",
    status: "planned",
    date: "2025 Q3",
    icon: Target,
    features: [
      { text: "Personalized AI learning", completed: false },
      { text: "Scene recognition", completed: false },
      { text: "Style matching", completed: false },
      { text: "Team collaboration", completed: false },
      { text: "Advanced analytics", completed: false },
      { text: "API access", completed: false }
    ]
  }
]

export default function Roadmap() {
  return (
    <section id="roadmap" className="py-20 px-4">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Development Roadmap
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-300">
            Continuous innovation and improvement
          </p>
        </div>

        {/* Current Status */}
        <div className="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-2xl p-6 mb-12">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div>
              <h3 className="text-xl font-semibold mb-2">Current Stage</h3>
              <p className="text-gray-600 dark:text-gray-300">
                We are in MVP Beta testing phase with core features completed and available for free trial
              </p>
            </div>
            <Badge className="text-lg px-4 py-2">
              MVP Beta - v1.0.0
            </Badge>
          </div>
        </div>

        {/* Timeline */}
        <div className="relative">
          {/* Vertical Line */}
          <div className="absolute left-8 top-0 bottom-0 w-0.5 bg-gray-300 dark:bg-gray-700 hidden md:block" />

          <div className="space-y-12">
            {roadmapData.map((phase, index) => (
              <div key={index} className="relative flex gap-8">
                {/* Timeline Dot */}
                <div className="hidden md:flex flex-shrink-0 w-16 items-center justify-center">
                  <div className={cn(
                    "w-4 h-4 rounded-full",
                    phase.status === "current" ? "bg-primary ring-4 ring-primary/20" :
                    phase.status === "upcoming" ? "bg-yellow-500" :
                    "bg-gray-300 dark:bg-gray-700"
                  )} />
                </div>

                {/* Content Card */}
                <Card className={cn(
                  "flex-1",
                  phase.status === "current" && "border-primary shadow-lg"
                )}>
                  <CardHeader>
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-3">
                        <div className={cn(
                          "h-10 w-10 rounded-lg flex items-center justify-center",
                          phase.status === "current" ? "bg-primary/10" :
                          phase.status === "upcoming" ? "bg-yellow-500/10" :
                          "bg-gray-100 dark:bg-gray-800"
                        )}>
                          <phase.icon className={cn(
                            "h-5 w-5",
                            phase.status === "current" ? "text-primary" :
                            phase.status === "upcoming" ? "text-yellow-500" :
                            "text-gray-500"
                          )} />
                        </div>
                        <div>
                          <CardTitle className="text-xl">
                            {phase.title}
                            <span className="ml-2 text-sm text-gray-500">{phase.version}</span>
                          </CardTitle>
                          <CardDescription>{phase.date}</CardDescription>
                        </div>
                      </div>
                      {phase.status === "current" && (
                        <Badge variant="default">Current Version</Badge>
                      )}
                      {phase.status === "upcoming" && (
                        <Badge variant="secondary">In Development</Badge>
                      )}
                      {phase.status === "planned" && (
                        <Badge variant="outline">Planned</Badge>
                      )}
                    </div>
                  </CardHeader>
                  <CardContent>
                    <ul className="space-y-2">
                      {phase.features.map((feature, featureIndex) => (
                        <li key={featureIndex} className="flex items-center gap-2">
                          {feature.completed ? (
                            <CheckCircle className="h-4 w-4 text-green-500 flex-shrink-0" />
                          ) : (
                            <Circle className="h-4 w-4 text-gray-400 flex-shrink-0" />
                          )}
                          <span className={cn(
                            "text-sm",
                            feature.completed && "text-gray-600 dark:text-gray-400"
                          )}>
                            {feature.text}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </CardContent>
                </Card>
              </div>
            ))}
          </div>
        </div>

        {/* Future Vision */}
        <div className="mt-16 text-center">
          <div className="inline-flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-4">
            <Clock className="h-4 w-4" />
            <span>Long-term Vision</span>
          </div>
          <h3 className="text-2xl font-bold mb-4">
            Becoming the Most Trusted AI Assistant for Photographers
          </h3>
          <p className="text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            Our goal is to create an intelligent tool that truly understands photographers' needs through continuous innovation and user feedback,
            allowing every photographer to focus on creativity rather than tedious post-processing work.
          </p>
        </div>
      </div>
    </section>
  )
}

function cn(...classes: string[]) {
  return classes.filter(Boolean).join(' ')
}