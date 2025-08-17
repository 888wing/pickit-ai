"use client"

import { useState } from "react"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Menu, X, Camera } from "lucide-react"

export default function Navigation() {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <nav className="fixed top-0 w-full z-50 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2">
            <Camera className="h-8 w-8 text-primary" />
            <span className="text-xl font-bold">Pickit</span>
            <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full font-semibold">
              MVP Beta
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8">
            <Link href="#features" className="text-gray-600 hover:text-primary transition">
              Features
            </Link>
            <Link href="#demo" className="text-gray-600 hover:text-primary transition">
              Demo Video
            </Link>
            <Link href="#installation" className="text-gray-600 hover:text-primary transition">
              Installation
            </Link>
            <Link href="#roadmap" className="text-gray-600 hover:text-primary transition">
              Roadmap
            </Link>
            <Button>
              Download Now
            </Button>
          </div>

          {/* Mobile menu button */}
          <button
            className="md:hidden"
            onClick={() => setIsOpen(!isOpen)}
          >
            {isOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
        </div>

        {/* Mobile Navigation */}
        {isOpen && (
          <div className="md:hidden py-4 space-y-4">
            <Link href="#features" className="block text-gray-600 hover:text-primary transition">
              Features
            </Link>
            <Link href="#demo" className="block text-gray-600 hover:text-primary transition">
              Demo Video
            </Link>
            <Link href="#installation" className="block text-gray-600 hover:text-primary transition">
              Installation
            </Link>
            <Link href="#roadmap" className="block text-gray-600 hover:text-primary transition">
              Roadmap
            </Link>
            <Button className="w-full">
              Download Now
            </Button>
          </div>
        )}
      </div>
    </nav>
  )
}