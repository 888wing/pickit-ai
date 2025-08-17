--[[
    Module: MainDialog
    Description: Main user interface for AI Photo Selector
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrApplication = import 'LrApplication'
local LrSelection = import 'LrSelection'

local Logger = require 'src/utils/Logger'
local Config = require 'src/utils/Config'
local BatchProcessor = require 'src/core/BatchProcessor'
local PluginInit = require 'PluginInit'

local logger = Logger:new('MainDialog')

-- Module definition
local MainDialog = {}
MainDialog.VERSION = "1.0.0"

-- Show main dialog
function MainDialog.showDialog()
    -- Ensure plugin is initialized
    PluginInit.ensureInitialized()
    
    LrTasks.startAsyncTask(function()
        local catalog = LrApplication.activeCatalog()
        local targetPhotos = catalog:getTargetPhotos()
        
        if not targetPhotos or #targetPhotos == 0 then
            LrDialogs.message(
                "未選擇照片",
                "請先在圖庫中選擇要處理的照片。",
                "warning"
            )
            return
        end
        
        logger:info("Opening main dialog", {photoCount = #targetPhotos})
        
        -- Create property table for data binding
        local props = LrBinding.makePropertyTable()
        
        -- Load configuration and set default values
        local config = Config.load()
        
        -- Processing options
        props.enableAI = config.useLocalModels
        props.enableFaceDetection = config.enableFaceDetection
        props.enableGrouping = true
        props.autoRate = true
        props.autoLabel = true
        props.passedLabel = "green"
        
        -- Thresholds
        props.qualityThreshold = config.qualityThreshold or 0.75
        props.similarityThreshold = config.similarityThreshold or 0.85
        props.blurThreshold = config.blurThreshold or 100
        
        -- Weights
        props.technicalWeight = config.technicalWeight or 0.4
        props.aestheticWeight = config.aestheticWeight or 0.6
        
        -- UI state
        props.isProcessing = false
        props.progressMessage = ""
        props.photoCount = #targetPhotos
        
        -- Create view factory
        local f = LrView.osFactory()
        
        -- Build dialog contents
        local contents = f:column {
            spacing = f:control_spacing(),
            
            -- Header
            f:row {
                f:static_text {
                    title = "AI智能選片",
                    font = "<system/bold>",
                    size = "large"
                },
                f:spacer { fill_horizontal = 1 },
                f:static_text {
                    title = string.format("已選擇 %d 張照片", #targetPhotos),
                    font = "<system/small>"
                }
            },
            
            f:separator { fill_horizontal = 1 },
            
            -- Processing Options
            f:group_box {
                title = "處理選項",
                fill_horizontal = 1,
                
                f:column {
                    spacing = f:label_spacing(),
                    
                    f:checkbox {
                        title = "啟用AI品質評分",
                        value = LrView.bind("enableAI"),
                        tooltip = "使用NIMA模型進行美學和技術評分"
                    },
                    
                    f:checkbox {
                        title = "啟用人臉檢測",
                        value = LrView.bind("enableFaceDetection"),
                        tooltip = "檢測人臉品質，確保人像清晰"
                    },
                    
                    f:checkbox {
                        title = "自動分組相似照片",
                        value = LrView.bind("enableGrouping"),
                        tooltip = "將相似或連拍照片分組，推薦最佳"
                    },
                    
                    f:row {
                        f:checkbox {
                            title = "自動評分",
                            value = LrView.bind("autoRate"),
                            tooltip = "為通過的照片設置星級評分"
                        },
                        f:spacer { width = 20 },
                        f:checkbox {
                            title = "自動標籤",
                            value = LrView.bind("autoLabel"),
                            tooltip = "為通過的照片添加顏色標籤"
                        },
                        f:spacer { width = 10 },
                        f:popup_menu {
                            value = LrView.bind("passedLabel"),
                            enabled = LrView.bind("autoLabel"),
                            items = {
                                { title = "紅色", value = "red" },
                                { title = "黃色", value = "yellow" },
                                { title = "綠色", value = "green" },
                                { title = "藍色", value = "blue" },
                                { title = "紫色", value = "purple" }
                            }
                        }
                    }
                }
            },
            
            -- Thresholds
            f:group_box {
                title = "閾值設置",
                fill_horizontal = 1,
                
                f:column {
                    spacing = f:label_spacing(),
                    
                    -- Quality threshold
                    f:row {
                        f:static_text {
                            title = "品質閾值:",
                            width = LrView.share("label_width"),
                            alignment = "right"
                        },
                        f:slider {
                            value = LrView.bind("qualityThreshold"),
                            min = 0.5,
                            max = 0.95,
                            width = LrView.share("slider_width")
                        },
                        f:edit_field {
                            value = LrView.bind("qualityThreshold"),
                            precision = 2,
                            width = 50
                        },
                        f:static_text {
                            title = "(0.5-0.95)",
                            font = "<system/small>"
                        }
                    },
                    
                    -- Similarity threshold
                    f:row {
                        f:static_text {
                            title = "相似度閾值:",
                            width = LrView.share("label_width"),
                            alignment = "right"
                        },
                        f:slider {
                            value = LrView.bind("similarityThreshold"),
                            min = 0.7,
                            max = 0.95,
                            width = LrView.share("slider_width"),
                            enabled = LrView.bind("enableGrouping")
                        },
                        f:edit_field {
                            value = LrView.bind("similarityThreshold"),
                            precision = 2,
                            width = 50,
                            enabled = LrView.bind("enableGrouping")
                        },
                        f:static_text {
                            title = "(0.7-0.95)",
                            font = "<system/small>"
                        }
                    },
                    
                    -- Blur threshold
                    f:row {
                        f:static_text {
                            title = "模糊閾值:",
                            width = LrView.share("label_width"),
                            alignment = "right"
                        },
                        f:slider {
                            value = LrView.bind("blurThreshold"),
                            min = 50,
                            max = 200,
                            width = LrView.share("slider_width")
                        },
                        f:edit_field {
                            value = LrView.bind("blurThreshold"),
                            precision = 0,
                            width = 50
                        },
                        f:static_text {
                            title = "(50-200)",
                            font = "<system/small>"
                        }
                    }
                }
            },
            
            -- Scoring Weights
            f:group_box {
                title = "評分權重",
                fill_horizontal = 1,
                
                f:column {
                    spacing = f:label_spacing(),
                    
                    f:row {
                        f:static_text {
                            title = "技術權重:",
                            width = LrView.share("label_width"),
                            alignment = "right"
                        },
                        f:slider {
                            value = LrView.bind("technicalWeight"),
                            min = 0,
                            max = 1,
                            width = LrView.share("slider_width")
                        },
                        f:edit_field {
                            value = LrView.bind("technicalWeight"),
                            precision = 2,
                            width = 50
                        }
                    },
                    
                    f:row {
                        f:static_text {
                            title = "美學權重:",
                            width = LrView.share("label_width"),
                            alignment = "right"
                        },
                        f:slider {
                            value = LrView.bind("aestheticWeight"),
                            min = 0,
                            max = 1,
                            width = LrView.share("slider_width")
                        },
                        f:edit_field {
                            value = LrView.bind("aestheticWeight"),
                            precision = 2,
                            width = 50
                        }
                    },
                    
                    f:static_text {
                        title = "註：權重會自動標準化，確保總和為1",
                        font = "<system/small>",
                        text_color = LrColor(0.5, 0.5, 0.5)
                    }
                }
            },
            
            -- Progress area (shown during processing)
            f:view {
                visible = LrView.bind("isProcessing"),
                f:group_box {
                    title = "處理進度",
                    fill_horizontal = 1,
                    
                    f:column {
                        f:static_text {
                            title = LrView.bind("progressMessage"),
                            font = "<system>",
                            height_in_lines = 2,
                            fill_horizontal = 1
                        }
                    }
                }
            }
        }
        
        -- Action buttons
        local actionButtons = {
            {
                title = "開始處理",
                action = function(button)
                    MainDialog.startProcessing(props, targetPhotos, button)
                end,
                enabled = LrView.bind {
                    keys = { "isProcessing" },
                    operation = function(binder, values)
                        return not values.isProcessing
                    end
                }
            },
            {
                title = "取消",
                action = function()
                    if props.currentTask then
                        props.currentTask:cancel()
                    end
                end,
                enabled = LrView.bind("isProcessing")
            }
        }
        
        -- Show dialog
        local result = LrDialogs.presentModalDialog({
            title = "AI智能選片",
            contents = contents,
            actionVerb = "處理",
            cancelVerb = "關閉",
            otherVerb = "設置",
            onOtherButton = function()
                MainDialog.showSettings()
            end,
            actionButtons = actionButtons
        })
        
        -- Save preferences if OK was clicked
        if result == "ok" then
            Config.savePreference("qualityThreshold", props.qualityThreshold)
            Config.savePreference("similarityThreshold", props.similarityThreshold)
            Config.savePreference("blurThreshold", props.blurThreshold)
            Config.savePreference("technicalWeight", props.technicalWeight)
            Config.savePreference("aestheticWeight", props.aestheticWeight)
            Config.savePreference("enableFaceDetection", props.enableFaceDetection)
        end
        
        logger:info("Main dialog closed", {result = result})
    end)
end

-- Start processing
function MainDialog.startProcessing(props, photos, button)
    props.isProcessing = true
    props.progressMessage = "初始化處理..."
    
    -- Prepare options
    local options = {
        threshold = props.qualityThreshold,
        enableFaceDetection = props.enableFaceDetection,
        enableGrouping = props.enableGrouping,
        autoRate = props.autoRate,
        autoLabel = props.autoLabel,
        passedLabel = props.passedLabel,
        technicalWeight = props.technicalWeight,
        aestheticWeight = props.aestheticWeight,
        similarityThreshold = props.similarityThreshold,
        blurThreshold = props.blurThreshold,
        showSummary = true
    }
    
    -- Initialize batch processor
    local batchProcessor = BatchProcessor:initialize()
    
    -- Start processing
    LrTasks.startAsyncTask(function()
        local task = batchProcessor:processBatch(photos, options, function(progress)
            props.progressMessage = progress.message or "處理中..."
        end)
        
        props.currentTask = task
        
        -- Wait for completion
        if task then
            while task:getStatus() == "running" do
                LrTasks.sleep(0.1)
            end
        end
        
        props.isProcessing = false
        props.currentTask = nil
        
        -- Get results
        local results = batchProcessor:getResults()
        
        if results and results.summary then
            -- Show results dialog
            MainDialog.showResults(results)
            
            -- Export results if configured
            if Config.get("autoExportResults") then
                local exportPath = LrPathUtils.child(
                    LrPathUtils.getStandardFilePath("desktop"),
                    "ai_selection_results.csv"
                )
                batchProcessor:exportResults("csv", exportPath)
            end
        end
        
        -- Clean up
        batchProcessor:cleanup()
    end)
end

-- Show results dialog
function MainDialog.showResults(results)
    if not results or not results.summary then
        return
    end
    
    local summary = results.summary
    
    local message = string.format(
        "處理完成！\n\n" ..
        "📊 處理統計\n" ..
        "• 總計: %d 張照片\n" ..
        "• 處理: %d 張\n" ..
        "• 通過: %d 張 (%.1f%%)\n" ..
        "• 失敗: %d 張\n" ..
        "• 分組: %d 張\n\n" ..
        "通過的照片已標記完成。",
        summary.total,
        summary.processed,
        summary.passed,
        (summary.passed / summary.total) * 100,
        summary.failed,
        summary.grouped or 0
    )
    
    LrDialogs.message("AI選片完成", message, "info")
end

-- Show settings dialog
function MainDialog.showSettings()
    local SettingsDialog = require 'src/ui/Settings'
    SettingsDialog.showDialog()
end

-- Export public interface
return {
    showDialog = MainDialog.showDialog
}