"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Download, Terminal, FileCode, CheckCircle, Copy, ExternalLink } from "lucide-react"

export default function Installation() {
  const [copiedStep, setCopiedStep] = useState<string | null>(null)

  const copyToClipboard = (text: string, step: string) => {
    navigator.clipboard.writeText(text)
    setCopiedStep(step)
    setTimeout(() => setCopiedStep(null), 2000)
  }

  return (
    <section id="installation" className="py-20 px-4 bg-gray-50 dark:bg-gray-900">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Installation Guide
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-300">
            Choose the installation method that suits you
          </p>
        </div>

        <Tabs defaultValue="oneclick" className="w-full">
          <TabsList className="grid w-full max-w-md mx-auto grid-cols-2">
            <TabsTrigger value="oneclick">One-Click Install</TabsTrigger>
            <TabsTrigger value="manual">Manual Install</TabsTrigger>
          </TabsList>

          <TabsContent value="oneclick" className="mt-8">
            <Card className="max-w-3xl mx-auto">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Download className="h-5 w-5" />
                  One-Click Installer (Recommended)
                </CardTitle>
                <CardDescription>
                  For macOS and Windows, automatically completes all configuration
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="flex flex-col sm:flex-row gap-4">
                  <Button size="lg" className="flex-1">
                    <Download className="mr-2 h-5 w-5" />
                    Download for macOS
                    <span className="ml-2 text-xs opacity-75">(.dmg, 120MB)</span>
                  </Button>
                  <Button size="lg" variant="outline" className="flex-1">
                    <Download className="mr-2 h-5 w-5" />
                    Download for Windows
                    <span className="ml-2 text-xs opacity-75">(.exe, 115MB)</span>
                  </Button>
                </div>

                <div className="space-y-4">
                  <h4 className="font-semibold">Installation Steps:</h4>
                  <ol className="space-y-3">
                    <li className="flex items-start gap-3">
                      <span className="flex-shrink-0 w-6 h-6 bg-primary text-white rounded-full flex items-center justify-center text-sm">1</span>
                      <span>Download and run the installer</span>
                    </li>
                    <li className="flex items-start gap-3">
                      <span className="flex-shrink-0 w-6 h-6 bg-primary text-white rounded-full flex items-center justify-center text-sm">2</span>
                      <span>Follow the installation wizard</span>
                    </li>
                    <li className="flex items-start gap-3">
                      <span className="flex-shrink-0 w-6 h-6 bg-primary text-white rounded-full flex items-center justify-center text-sm">3</span>
                      <span>Restart Lightroom Classic</span>
                    </li>
                    <li className="flex items-start gap-3">
                      <CheckCircle className="flex-shrink-0 h-6 w-6 text-green-500" />
                      <span>Done! Find Pickit in the Library menu</span>
                    </li>
                  </ol>
                </div>

                <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg">
                  <p className="text-sm text-blue-800 dark:text-blue-200">
                    💡 <strong>Tip:</strong> The installer includes all necessary AI models and dependencies, no additional configuration needed.
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="manual" className="mt-8">
            <Card className="max-w-3xl mx-auto">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Terminal className="h-5 w-5" />
                  Manual Installation
                </CardTitle>
                <CardDescription>
                  For developers or users who need custom configuration
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-4">
                  <h4 className="font-semibold">System Requirements:</h4>
                  <ul className="space-y-2 text-sm">
                    <li>• Lightroom Classic 12.0+</li>
                    <li>• Node.js 16.0+</li>
                    <li>• 4GB RAM (8GB recommended)</li>
                    <li>• 500MB available space</li>
                  </ul>
                </div>

                <div className="space-y-4">
                  <h4 className="font-semibold">Installation Steps:</h4>
                  
                  <div className="space-y-3">
                    <div className="bg-gray-900 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs text-gray-400">Step 1: Clone the project</span>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => copyToClipboard("git clone https://github.com/pickit/pickit-lightroom.git", "step1")}
                        >
                          {copiedStep === "step1" ? <CheckCircle className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                        </Button>
                      </div>
                      <code className="text-green-400 text-sm">
                        git clone https://github.com/pickit/pickit-lightroom.git
                      </code>
                    </div>

                    <div className="bg-gray-900 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs text-gray-400">Step 2: Install dependencies</span>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => copyToClipboard("cd pickit-lightroom/node-bridge && npm install", "step2")}
                        >
                          {copiedStep === "step2" ? <CheckCircle className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                        </Button>
                      </div>
                      <code className="text-green-400 text-sm">
                        cd pickit-lightroom/node-bridge && npm install
                      </code>
                    </div>

                    <div className="bg-gray-900 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs text-gray-400">Step 3: Download AI models</span>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => copyToClipboard("npm run install-models", "step3")}
                        >
                          {copiedStep === "step3" ? <CheckCircle className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                        </Button>
                      </div>
                      <code className="text-green-400 text-sm">
                        npm run install-models
                      </code>
                    </div>

                    <div className="bg-gray-900 rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs text-gray-400">Step 4: Start the service</span>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => copyToClipboard("npm start", "step4")}
                        >
                          {copiedStep === "step4" ? <CheckCircle className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                        </Button>
                      </div>
                      <code className="text-green-400 text-sm">
                        npm start
                      </code>
                    </div>
                  </div>
                </div>

                <Button variant="outline" className="w-full">
                  <FileCode className="mr-2 h-4 w-4" />
                  View Detailed Documentation
                  <ExternalLink className="ml-2 h-4 w-4" />
                </Button>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </section>
  )
}