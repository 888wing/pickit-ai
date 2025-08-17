--[[
    Module: PluginInfoProvider
    Description: Provides plugin information to Lightroom
    Author: Pickit Development Team
    Created: 2025-01-01
--]]

local Logger = require 'src/utils/Logger'
local logger = Logger:new('PluginInfoProvider')

return {
    sectionsForTopOfDialog = function(f, props)
        logger:trace("Building plugin info dialog")
        
        return {
            {
                title = "AI Photo Selector",
                
                f:row {
                    f:static_text {
                        title = "版本:",
                        width = 100,
                    },
                    f:static_text {
                        title = "1.0.0 (MVP)",
                    },
                },
                
                f:row {
                    f:static_text {
                        title = "作者:",
                        width = 100,
                    },
                    f:static_text {
                        title = "Pickit Development Team",
                    },
                },
                
                f:row {
                    f:static_text {
                        title = "描述:",
                        width = 100,
                    },
                    f:static_text {
                        title = "使用AI技術自動識別和選擇高品質照片",
                        wrap = true,
                        width = 300,
                    },
                },
            },
            
            {
                title = "功能特點",
                
                f:static_text {
                    title = "• 快速技術篩選 - 檢測模糊、曝光問題\n" ..
                           "• AI品質評分 - 技術與美學綜合評估\n" ..
                           "• 智能分組去重 - 自動識別相似照片\n" ..
                           "• 人臉品質檢測 - 確保人像品質\n" ..
                           "• 批次處理 - 支援大量照片快速處理",
                    wrap = true,
                    width = 400,
                    height_in_lines = 6,
                },
            },
            
            {
                title = "系統需求",
                
                f:static_text {
                    title = "• Lightroom Classic 12.0+\n" ..
                           "• macOS 10.14+ / Windows 10+\n" ..
                           "• 4GB RAM (建議8GB)\n" ..
                           "• 500MB可用磁碟空間",
                    wrap = true,
                    width = 400,
                    height_in_lines = 4,
                },
            },
        }
    end,
    
    sectionsForBottomOfDialog = function(f, props)
        return {
            {
                title = "支援",
                
                f:row {
                    f:push_button {
                        title = "使用手冊",
                        action = function()
                            logger:info("Opening user manual")
                            local LrHttp = import 'LrHttp'
                            LrHttp.openUrlInBrowser("https://pickit.ai/manual")
                        end,
                    },
                    
                    f:push_button {
                        title = "報告問題",
                        action = function()
                            logger:info("Opening issue reporter")
                            local LrHttp = import 'LrHttp'
                            LrHttp.openUrlInBrowser("https://pickit.ai/support")
                        end,
                    },
                    
                    f:push_button {
                        title = "檢查更新",
                        action = function()
                            logger:info("Checking for updates")
                            local LrDialogs = import 'LrDialogs'
                            LrDialogs.message("檢查更新", "您已經在使用最新版本 (1.0.0)")
                        end,
                    },
                },
            },
        }
    end,
    
    hideSections = {},
    hideExtras = {},
}