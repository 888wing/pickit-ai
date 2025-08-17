"use client"

import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Github, Mail, MessageSquare, FileText, ExternalLink } from "lucide-react"

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="container mx-auto max-w-6xl px-4 py-12">
        <div className="grid md:grid-cols-4 gap-8">
          {/* Brand Section */}
          <div className="col-span-2 md:col-span-1">
            <h3 className="text-2xl font-bold text-white mb-4">Pickit</h3>
            <p className="text-sm mb-4">
              AI-powered intelligent photo selection tool, saving professional photographers 80% of post-processing time
            </p>
            <div className="flex gap-3">
              <Button
                size="sm"
                variant="ghost"
                className="hover:text-white"
                asChild
              >
                <a href="https://github.com/pickit/pickit-lightroom" target="_blank" rel="noopener noreferrer">
                  <Github className="h-4 w-4" />
                </a>
              </Button>
              <Button
                size="sm"
                variant="ghost"
                className="hover:text-white"
                asChild
              >
                <a href="mailto:support@pickit.ai">
                  <Mail className="h-4 w-4" />
                </a>
              </Button>
            </div>
          </div>

          {/* Product Links */}
          <div>
            <h4 className="font-semibold text-white mb-4">Product</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="#features" className="hover:text-white transition-colors">
                  Features
                </Link>
              </li>
              <li>
                <Link href="#demo" className="hover:text-white transition-colors">
                  Demo Video
                </Link>
              </li>
              <li>
                <Link href="#installation" className="hover:text-white transition-colors">
                  Download & Install
                </Link>
              </li>
              <li>
                <Link href="#roadmap" className="hover:text-white transition-colors">
                  Roadmap
                </Link>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h4 className="font-semibold text-white mb-4">Resources</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <a 
                  href="/docs/user-manual" 
                  className="hover:text-white transition-colors flex items-center gap-1"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  User Manual
                  <ExternalLink className="h-3 w-3" />
                </a>
              </li>
              <li>
                <a 
                  href="/docs/api" 
                  className="hover:text-white transition-colors flex items-center gap-1"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  API Documentation
                  <ExternalLink className="h-3 w-3" />
                </a>
              </li>
              <li>
                <a 
                  href="https://github.com/pickit/pickit-lightroom/wiki" 
                  className="hover:text-white transition-colors flex items-center gap-1"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Developer Guide
                  <ExternalLink className="h-3 w-3" />
                </a>
              </li>
              <li>
                <a 
                  href="https://github.com/pickit/pickit-lightroom/releases" 
                  className="hover:text-white transition-colors flex items-center gap-1"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Release Notes
                  <ExternalLink className="h-3 w-3" />
                </a>
              </li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h4 className="font-semibold text-white mb-4">Support</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <button
                  onClick={() => {
                    // This would trigger the feedback dialog in the actual plugin
                    alert("Please use the feedback feature in the Lightroom plugin")
                  }}
                  className="hover:text-white transition-colors flex items-center gap-1"
                >
                  <MessageSquare className="h-3 w-3" />
                  Feedback
                </button>
              </li>
              <li>
                <a 
                  href="https://github.com/pickit/pickit-lightroom/issues" 
                  className="hover:text-white transition-colors flex items-center gap-1"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <FileText className="h-3 w-3" />
                  Report Issues
                </a>
              </li>
              <li>
                <a 
                  href="mailto:support@pickit.ai" 
                  className="hover:text-white transition-colors"
                >
                  support@pickit.ai
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-gray-800 mt-8 pt-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="text-sm">
              © 2025 Pickit. All rights reserved.
            </div>
            <div className="flex gap-6 text-sm">
              <Link href="/privacy" className="hover:text-white transition-colors">
                Privacy Policy
              </Link>
              <Link href="/terms" className="hover:text-white transition-colors">
                Terms of Service
              </Link>
              <Link href="/license" className="hover:text-white transition-colors">
                License Agreement
              </Link>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}