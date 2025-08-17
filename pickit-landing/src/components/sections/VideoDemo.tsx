"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Play, Monitor, Smartphone, Camera } from "lucide-react"

export default function VideoDemo() {
  const [isPlaying, setIsPlaying] = useState(false)

  return (
    <section id="demo" className="py-20 px-4">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Live Demo
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-300">
            Learn how Pickit transforms your workflow in 3 minutes
          </p>
        </div>

        <div className="relative rounded-2xl overflow-hidden bg-gray-900 shadow-2xl">
          {/* Video Placeholder */}
          <div className="aspect-video relative">
            {!isPlaying ? (
              <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-gray-800 to-gray-900">
                <div className="text-center">
                  <Button
                    size="lg"
                    className="rounded-full h-20 w-20 mb-4"
                    onClick={() => setIsPlaying(true)}
                  >
                    <Play className="h-8 w-8 ml-1" />
                  </Button>
                  <p className="text-white text-lg">Click to play demo video</p>
                </div>
                
                {/* Decorative Elements */}
                <div className="absolute top-8 left-8 text-white/20">
                  <Monitor className="h-12 w-12" />
                </div>
                <div className="absolute bottom-8 right-8 text-white/20">
                  <Camera className="h-12 w-12" />
                </div>
                <div className="absolute top-8 right-8 text-white/20">
                  <Smartphone className="h-12 w-12" />
                </div>
              </div>
            ) : (
              <iframe
                width="100%"
                height="100%"
                src="https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1"
                title="Pickit Demo"
                frameBorder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className="absolute inset-0"
              />
            )}
          </div>
        </div>

        {/* Video Features */}
        <div className="grid md:grid-cols-3 gap-8 mt-12">
          <div className="text-center">
            <div className="text-2xl font-bold text-primary mb-2">01:30</div>
            <div className="text-gray-600">AI Scoring Demo</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-primary mb-2">02:15</div>
            <div className="text-gray-600">Batch Processing</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-primary mb-2">03:00</div>
            <div className="text-gray-600">Export Results</div>
          </div>
        </div>
      </div>
    </section>
  )
}