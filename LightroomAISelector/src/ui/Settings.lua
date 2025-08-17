--[[
    Module: Settings
    Description: Settings dialog for plugin configuration
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrHttp = import 'LrHttp'

local Logger = require 'src/utils/Logger'
local Config = require 'src/utils/Config'
local ONNXBridge = require 'src/models/ONNXBridge'

local logger = Logger:new('Settings')

-- Module definition
local Settings = {}

-- Show settings dialog
function Settings.showDialog()
    LrTasks.startAsyncTask(function()
        logger:info("Opening settings dialog")
        
        -- Create property table
        local props = LrBinding.makePropertyTable()
        
        -- Load current configuration
        local config = Config.getPreferences()
        
        -- General settings
        props.batchSize = config.preferredBatchSize or Config.get("batchSize")
        props.maxMemoryUsage = config.maxMemoryUsage or 500
        props.logLevel = Config.get("logLevel")
        props.enableDebugUI = Config.get("enableDebugUI")
        
        -- AI settings
        props.useLocalModels = Config.get("useLocalModels")
        props.modelTimeout = Config.get("modelTimeout")
        props.bridgeServerUrl = Config.get("bridgeServerUrl") or "http://localhost:3000"
        
        -- Performance settings
        props.cacheEnabled = Config.get("cacheEnabled")
        props.cacheSize = Config.get("cacheSize")
        props.maxConcurrentTasks = Config.get("maxConcurrentTasks")
        
        -- Features
        props.enableCloudFeatures = Config.get("enableCloudFeatures")
        props.enableAnalytics = Config.get("enableAnalytics")
        props.enableAutoUpdate = Config.get("enableAutoUpdate")
        
        -- Server status
        props.serverStatus = "檢查中..."
        props.modelsLoaded = ""
        
        -- Create view factory
        local f = LrView.osFactory()
        
        -- Build dialog contents
        local contents = f:column {
            spacing = f:control_spacing(),
            
            -- Header
            f:row {
                f:static_text {
                    title = "插件設置",
                    font = "<system/bold>",
                    size = "large"
                },
                f:spacer { fill_horizontal = 1 },
                f:push_button {
                    title = "重置為默認",
                    action = function()
                        Settings.resetToDefaults(props)
                    end
                }
            },
            
            f:separator { fill_horizontal = 1 },
            
            -- Tab view
            f:tab_view {
                -- General tab
                {
                    title = "一般",
                    identifier = "general",
                    
                    f:column {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        
                        f:group_box {
                            title = "處理設置",
                            fill_horizontal = 1,
                            
                            f:column {
                                f:row {
                                    f:static_text {
                                        title = "批次大小:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:edit_field {
                                        value = LrView.bind("batchSize"),
                                        width = 60,
                                        precision = 0,
                                        min = 1,
                                        max = 100
                                    },
                                    f:static_text {
                                        title = "張 (1-100)",
                                        font = "<system/small>"
                                    }
                                },
                                
                                f:row {
                                    f:static_text {
                                        title = "最大記憶體:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:edit_field {
                                        value = LrView.bind("maxMemoryUsage"),
                                        width = 60,
                                        precision = 0,
                                        min = 100,
                                        max = 2000
                                    },
                                    f:static_text {
                                        title = "MB",
                                        font = "<system/small>"
                                    }
                                }
                            }
                        },
                        
                        f:group_box {
                            title = "日誌設置",
                            fill_horizontal = 1,
                            
                            f:column {
                                f:row {
                                    f:static_text {
                                        title = "日誌級別:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:popup_menu {
                                        value = LrView.bind("logLevel"),
                                        items = {
                                            { title = "Trace", value = "trace" },
                                            { title = "Debug", value = "debug" },
                                            { title = "Info", value = "info" },
                                            { title = "Warning", value = "warn" },
                                            { title = "Error", value = "error" }
                                        }
                                    }
                                },
                                
                                f:checkbox {
                                    title = "啟用調試UI",
                                    value = LrView.bind("enableDebugUI"),
                                    tooltip = "顯示額外的調試信息"
                                }
                            }
                        }
                    }
                },
                
                -- AI Models tab
                {
                    title = "AI模型",
                    identifier = "ai",
                    
                    f:column {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        
                        f:group_box {
                            title = "模型設置",
                            fill_horizontal = 1,
                            
                            f:column {
                                f:checkbox {
                                    title = "使用本地模型",
                                    value = LrView.bind("useLocalModels"),
                                    tooltip = "優先使用本地ONNX模型"
                                },
                                
                                f:row {
                                    f:static_text {
                                        title = "模型超時:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:edit_field {
                                        value = LrView.bind("modelTimeout"),
                                        width = 60,
                                        precision = 0,
                                        min = 5,
                                        max = 120
                                    },
                                    f:static_text {
                                        title = "秒",
                                        font = "<system/small>"
                                    }
                                }
                            }
                        },
                        
                        f:group_box {
                            title = "Bridge服務器",
                            fill_horizontal = 1,
                            
                            f:column {
                                f:row {
                                    f:static_text {
                                        title = "服務器地址:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:edit_field {
                                        value = LrView.bind("bridgeServerUrl"),
                                        width = 200
                                    }
                                },
                                
                                f:row {
                                    f:static_text {
                                        title = "狀態:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:static_text {
                                        title = LrView.bind("serverStatus"),
                                        font = "<system>",
                                        text_color = LrView.bind {
                                            keys = { "serverStatus" },
                                            operation = function(binder, values)
                                                if values.serverStatus == "已連接" then
                                                    return LrColor(0, 0.7, 0)
                                                else
                                                    return LrColor(0.7, 0, 0)
                                                end
                                            end
                                        }
                                    },
                                    f:push_button {
                                        title = "測試連接",
                                        action = function()
                                            Settings.testBridgeConnection(props)
                                        end
                                    }
                                },
                                
                                f:row {
                                    f:static_text {
                                        title = "已載入模型:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:static_text {
                                        title = LrView.bind("modelsLoaded"),
                                        font = "<system/small>",
                                        height_in_lines = 2,
                                        width = 300
                                    }
                                }
                            }
                        },
                        
                        f:push_button {
                            title = "下載模型",
                            action = function()
                                Settings.downloadModels()
                            end
                        }
                    }
                },
                
                -- Performance tab
                {
                    title = "性能",
                    identifier = "performance",
                    
                    f:column {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        
                        f:group_box {
                            title = "快取設置",
                            fill_horizontal = 1,
                            
                            f:column {
                                f:checkbox {
                                    title = "啟用快取",
                                    value = LrView.bind("cacheEnabled")
                                },
                                
                                f:row {
                                    f:static_text {
                                        title = "快取大小:",
                                        width = 120,
                                        alignment = "right"
                                    },
                                    f:edit_field {
                                        value = LrView.bind("cacheSize"),
                                        width = 60,
                                        precision = 0,
                                        min = 10,
                                        max = 1000,
                                        enabled = LrView.bind("cacheEnabled")
                                    },
                                    f:static_text {
                                        title = "項",
                                        font = "<system/small>"
                                    }
                                }
                            }
                        },
                        
                        f:group_box {
                            title = "並發設置",
                            fill_horizontal = 1,
                            
                            f:row {
                                f:static_text {
                                    title = "最大並發任務:",
                                    width = 120,
                                    alignment = "right"
                                },
                                f:edit_field {
                                    value = LrView.bind("maxConcurrentTasks"),
                                    width = 60,
                                    precision = 0,
                                    min = 1,
                                    max = 8
                                },
                                f:static_text {
                                    title = "(1-8)",
                                    font = "<system/small>"
                                }
                            }
                        },
                        
                        f:push_button {
                            title = "清除快取",
                            action = function()
                                Settings.clearCache()
                            end
                        }
                    }
                },
                
                -- Features tab
                {
                    title = "功能",
                    identifier = "features",
                    
                    f:column {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        
                        f:group_box {
                            title = "進階功能",
                            fill_horizontal = 1,
                            
                            f:column {
                                f:checkbox {
                                    title = "啟用雲端功能",
                                    value = LrView.bind("enableCloudFeatures"),
                                    tooltip = "使用雲端AI模型獲得更好的效果"
                                },
                                
                                f:checkbox {
                                    title = "啟用使用分析",
                                    value = LrView.bind("enableAnalytics"),
                                    tooltip = "幫助改進產品（完全匿名）"
                                },
                                
                                f:checkbox {
                                    title = "自動檢查更新",
                                    value = LrView.bind("enableAutoUpdate"),
                                    tooltip = "自動檢查並通知新版本"
                                }
                            }
                        },
                        
                        f:group_box {
                            title = "關於",
                            fill_horizontal = 1,
                            
                            f:column {
                                f:static_text {
                                    title = "AI Photo Selector",
                                    font = "<system/bold>"
                                },
                                f:static_text {
                                    title = "版本: 1.0.0 (MVP)",
                                    font = "<system/small>"
                                },
                                f:static_text {
                                    title = "© 2025 Pickit Development Team",
                                    font = "<system/small>"
                                },
                                
                                f:row {
                                    f:push_button {
                                        title = "查看日誌",
                                        action = function()
                                            Settings.viewLogs()
                                        end
                                    },
                                    f:push_button {
                                        title = "用戶手冊",
                                        action = function()
                                            LrHttp.openUrlInBrowser("https://pickit.ai/manual")
                                        end
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        -- Test bridge connection on dialog open
        Settings.testBridgeConnection(props)
        
        -- Show dialog
        local result = LrDialogs.presentModalDialog({
            title = "設置",
            contents = contents,
            cancelVerb = "取消"
        })
        
        -- Save settings if OK was clicked
        if result == "ok" then
            Settings.saveSettings(props)
        end
        
        logger:info("Settings dialog closed", {result = result})
    end)
end

-- Test bridge connection
function Settings.testBridgeConnection(props)
    props.serverStatus = "連接中..."
    props.modelsLoaded = ""
    
    LrTasks.startAsyncTask(function()
        local bridge = ONNXBridge:new({ bridgeServerUrl = props.bridgeServerUrl })
        
        if bridge:checkHealth() then
            props.serverStatus = "已連接"
            
            -- Get available models
            local models = bridge:getAvailableModels()
            if models and #models > 0 then
                local modelNames = {}
                for _, model in ipairs(models) do
                    table.insert(modelNames, model.name or model.id)
                end
                props.modelsLoaded = table.concat(modelNames, ", ")
            else
                props.modelsLoaded = "無可用模型"
            end
        else
            props.serverStatus = "未連接"
            props.modelsLoaded = "請啟動Bridge服務器"
        end
        
        bridge:cleanup()
    end)
end

-- Download models
function Settings.downloadModels()
    local message = "這將下載AI模型文件（約30MB）。\n\n" ..
                   "請確保Node.js Bridge服務器正在運行。\n" ..
                   "下載完成後需要重啟插件。\n\n" ..
                   "是否繼續？"
    
    local result = LrDialogs.confirm("下載AI模型", message, "下載", "取消")
    
    if result == "ok" then
        LrDialogs.message("下載說明", 
            "請在終端運行以下命令：\n\n" ..
            "cd LightroomAISelector/node-bridge\n" ..
            "npm run install-models\n\n" ..
            "下載完成後重啟Lightroom。"
        )
    end
end

-- Clear cache
function Settings.clearCache()
    local PhotoScorer = require 'src/core/PhotoScorer'
    local scorer = PhotoScorer:initialize()
    scorer:clearCache()
    scorer:cleanup()
    
    LrDialogs.message("快取已清除", "所有快取資料已成功清除。")
end

-- View logs
function Settings.viewLogs()
    local logPath = Logger.getLogFilePath()
    if logPath then
        LrDialogs.message("日誌位置", "日誌文件位於：\n" .. logPath)
    else
        LrDialogs.message("日誌", "日誌功能未啟用。")
    end
end

-- Reset to defaults
function Settings.resetToDefaults(props)
    local result = LrDialogs.confirm(
        "重置設置",
        "這將重置所有設置為默認值。是否繼續？",
        "重置",
        "取消"
    )
    
    if result == "ok" then
        Config.resetPreferences()
        
        -- Reload defaults
        local config = Config.load()
        props.batchSize = config.batchSize
        props.maxMemoryUsage = 500
        props.logLevel = config.logLevel
        props.useLocalModels = config.useLocalModels
        props.cacheEnabled = config.cacheEnabled
        props.cacheSize = config.cacheSize
        
        LrDialogs.message("設置已重置", "所有設置已恢復為默認值。")
    end
end

-- Save settings
function Settings.saveSettings(props)
    -- Save preferences
    Config.savePreference("preferredBatchSize", props.batchSize)
    Config.savePreference("maxMemoryUsage", props.maxMemoryUsage)
    
    -- Save runtime settings
    Config.set("logLevel", props.logLevel)
    Config.set("enableDebugUI", props.enableDebugUI)
    Config.set("useLocalModels", props.useLocalModels)
    Config.set("modelTimeout", props.modelTimeout)
    Config.set("bridgeServerUrl", props.bridgeServerUrl)
    Config.set("cacheEnabled", props.cacheEnabled)
    Config.set("cacheSize", props.cacheSize)
    Config.set("maxConcurrentTasks", props.maxConcurrentTasks)
    Config.set("enableCloudFeatures", props.enableCloudFeatures)
    Config.set("enableAnalytics", props.enableAnalytics)
    Config.set("enableAutoUpdate", props.enableAutoUpdate)
    
    -- Apply log level change
    Logger.setGlobalLogLevel(props.logLevel)
    
    logger:info("Settings saved")
end

return Settings