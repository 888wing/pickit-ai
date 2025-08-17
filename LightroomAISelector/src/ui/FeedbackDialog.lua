--[[
    Pickit Feedback Dialog
    User interface for submitting feedback
    Created: 2025-01-20
--]]

local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrColor = import 'LrColor'
local LrApplication = import 'LrApplication'

local FeedbackManager = require 'src/feedback/FeedbackManager'
local Logger = require 'src/utils/Logger'

-- Feedback Dialog module
local FeedbackDialog = {
    logger = Logger:new("FeedbackDialog")
}

-- Show feedback dialog
function FeedbackDialog.show()
    return LrFunctionContext.callWithContext("feedback_dialog", function(context)
        local f = LrView.osFactory()
        local properties = LrBinding.makePropertyTable(context)
        
        -- Initialize default values
        properties.feedbackType = "general_feedback"
        properties.rating = 4
        properties.title = ""
        properties.description = ""
        properties.usageFrequency = "weekly"
        properties.professionalLevel = "enthusiast"
        properties.allowContact = false
        properties.userName = ""
        properties.userEmail = ""
        properties.includeSystemInfo = true
        
        -- Create rating display
        local function getRatingDisplay(rating)
            local stars = ""
            for i = 1, 5 do
                if i <= rating then
                    stars = stars .. "★"
                else
                    stars = stars .. "☆"
                end
            end
            return stars .. " (" .. rating .. "/5)"
        end
        
        -- Update rating display
        properties:addObserver("rating", function()
            properties.ratingDisplay = getRatingDisplay(properties.rating)
        end)
        properties.ratingDisplay = getRatingDisplay(properties.rating)
        
        -- Main dialog content
        local contents = f:column {
            spacing = f:control_spacing(),
            bind_to_object = properties,
            
            -- Header
            f:row {
                f:static_text {
                    title = "Pickit 意見回饋",
                    font = "<system/bold>",
                    size = "large"
                },
                fill_horizontal = 1,
                f:static_text {
                    title = "v1.0.0",
                    font = "<system/small>",
                    text_color = LrColor(0.5, 0.5, 0.5)
                }
            },
            
            f:static_text {
                title = "您的意見對我們非常重要，將協助 Pickit 持續改進",
                font = "<system/small>",
                text_color = LrColor(0.3, 0.3, 0.3),
                height_in_lines = 1
            },
            
            f:separator { fill_horizontal = 1 },
            
            -- Feedback type
            f:row {
                spacing = f:label_spacing(),
                f:static_text {
                    title = "意見類型:",
                    width = LrView.share "label_width",
                    alignment = "right"
                },
                f:popup_menu {
                    value = LrView.bind("feedbackType"),
                    width = LrView.share "field_width",
                    items = {
                        { title = "功能建議", value = "feature_request" },
                        { title = "錯誤回報", value = "bug_report" },
                        { title = "性能問題", value = "performance_issue" },
                        { title = "界面意見", value = "ui_feedback" },
                        { title = "工作流程建議", value = "workflow_suggestion" },
                        { title = "一般意見", value = "general_feedback" },
                        { title = "讚賞鼓勵", value = "praise" }
                    }
                }
            },
            
            -- Overall rating
            f:row {
                spacing = f:label_spacing(),
                f:static_text {
                    title = "整體滿意度:",
                    width = LrView.share "label_width",
                    alignment = "right"
                },
                f:slider {
                    value = LrView.bind("rating"),
                    min = 1,
                    max = 5,
                    integral = true,
                    width = 200
                },
                f:static_text {
                    title = LrView.bind("ratingDisplay"),
                    width = 100,
                    font = "<system/bold>"
                }
            },
            
            -- Title
            f:row {
                spacing = f:label_spacing(),
                f:static_text {
                    title = "標題: *",
                    width = LrView.share "label_width",
                    alignment = "right"
                },
                f:edit_field {
                    value = LrView.bind("title"),
                    width = LrView.share "field_width",
                    immediate = true,
                    placeholder = "簡短描述您的意見"
                }
            },
            
            -- Description
            f:row {
                spacing = f:label_spacing(),
                f:static_text {
                    title = "詳細描述: *",
                    width = LrView.share "label_width",
                    alignment = "right"
                },
                f:scrolled_view {
                    width = LrView.share "field_width",
                    height = 120,
                    f:edit_field {
                        value = LrView.bind("description"),
                        width_in_chars = 40,
                        height_in_lines = 8,
                        placeholder = "請詳細描述您的意見、建議或遇到的問題..."
                    }
                }
            },
            
            f:separator { fill_horizontal = 1 },
            
            -- Usage information
            f:group_box {
                title = "使用資訊",
                font = "<system/small/bold>",
                
                f:column {
                    spacing = f:control_spacing(),
                    
                    f:row {
                        spacing = f:label_spacing(),
                        f:static_text {
                            title = "使用頻率:",
                            width = LrView.share "label_width",
                            alignment = "right"
                        },
                        f:popup_menu {
                            value = LrView.bind("usageFrequency"),
                            width = 150,
                            items = {
                                { title = "每天", value = "daily" },
                                { title = "每週數次", value = "weekly" },
                                { title = "每月數次", value = "monthly" },
                                { title = "偶爾", value = "occasionally" }
                            }
                        }
                    },
                    
                    f:row {
                        spacing = f:label_spacing(),
                        f:static_text {
                            title = "您是:",
                            width = LrView.share "label_width",
                            alignment = "right"
                        },
                        f:popup_menu {
                            value = LrView.bind("professionalLevel"),
                            width = 150,
                            items = {
                                { title = "專業攝影師", value = "professional" },
                                { title = "半專業攝影師", value = "semi_professional" },
                                { title = "攝影愛好者", value = "enthusiast" },
                                { title = "初學者", value = "beginner" }
                            }
                        }
                    }
                }
            },
            
            f:separator { fill_horizontal = 1 },
            
            -- Contact information (optional)
            f:group_box {
                title = "聯絡資訊（選填）",
                font = "<system/small/bold>",
                
                f:column {
                    spacing = f:control_spacing(),
                    
                    f:checkbox {
                        value = LrView.bind("allowContact"),
                        title = "願意接收官方回覆",
                        font = "<system/small>"
                    },
                    
                    f:row {
                        spacing = f:label_spacing(),
                        f:static_text {
                            title = "姓名:",
                            width = LrView.share "label_width",
                            alignment = "right",
                            enabled = LrView.bind("allowContact")
                        },
                        f:edit_field {
                            value = LrView.bind("userName"),
                            width = 200,
                            enabled = LrView.bind("allowContact"),
                            placeholder = "您的姓名"
                        }
                    },
                    
                    f:row {
                        spacing = f:label_spacing(),
                        f:static_text {
                            title = "Email:",
                            width = LrView.share "label_width",
                            alignment = "right",
                            enabled = LrView.bind("allowContact")
                        },
                        f:edit_field {
                            value = LrView.bind("userEmail"),
                            width = 200,
                            enabled = LrView.bind("allowContact"),
                            placeholder = "your@email.com"
                        }
                    }
                }
            },
            
            -- System info checkbox
            f:checkbox {
                value = LrView.bind("includeSystemInfo"),
                title = "包含系統資訊（有助於解決技術問題）",
                font = "<system/small>",
                checked_value = true
            },
            
            -- Privacy notice
            f:static_text {
                title = "📌 隱私聲明：您的資料將被安全儲存，僅用於改進 Pickit。",
                font = "<system/small>",
                text_color = LrColor(0.4, 0.4, 0.4),
                height_in_lines = 1
            },
            
            -- Previous feedback
            f:row {
                fill_horizontal = 1,
                f:push_button {
                    title = "查看歷史意見",
                    font = "<system/small>",
                    action = function()
                        FeedbackDialog.showHistory()
                    end
                }
            }
        }
        
        -- Present dialog
        local result = LrDialogs.presentModalDialog {
            title = "Pickit 意見回饋",
            contents = contents,
            actionVerb = "提交",
            cancelVerb = "取消",
            windowWillClose = function()
                -- Save draft if cancelled
                if properties.title ~= "" or properties.description ~= "" then
                    FeedbackDialog.saveDraft(properties)
                end
            end
        }
        
        -- Handle submission
        if result == "ok" then
            -- Validate required fields
            if properties.title == "" then
                LrDialogs.message("請輸入標題", "標題為必填欄位", "warning")
                return FeedbackDialog.show()
            end
            
            if properties.description == "" then
                LrDialogs.message("請輸入詳細描述", "詳細描述為必填欄位", "warning")
                return FeedbackDialog.show()
            end
            
            -- Initialize feedback manager
            local feedbackManager = FeedbackManager:initialize()
            
            -- Prepare feedback data
            local feedbackData = {
                feedbackType = properties.feedbackType,
                rating = properties.rating,
                title = properties.title,
                description = properties.description,
                usageFrequency = properties.usageFrequency,
                professionalLevel = properties.professionalLevel,
                allowContact = properties.allowContact,
                userName = properties.allowContact and properties.userName or nil,
                userEmail = properties.allowContact and properties.userEmail or nil,
                includeSystemInfo = properties.includeSystemInfo
            }
            
            -- Submit feedback
            local success, result = feedbackManager:submitFeedback(feedbackData)
            
            if success then
                -- Clear draft
                FeedbackDialog.clearDraft()
                
                -- Show success message
                LrDialogs.message(
                    "感謝您的意見！",
                    string.format(
                        "您的意見已成功提交。\n\n" ..
                        "提交編號: %s\n\n" ..
                        "我們會仔細閱讀每一條意見，並持續改進 Pickit。\n" ..
                        "%s",
                        result,
                        properties.allowContact and 
                        "如有需要，我們會透過您提供的聯絡方式與您聯繫。" or ""
                    ),
                    "info"
                )
            else
                -- Show error message with retry option
                local retry = LrDialogs.confirm(
                    "提交失敗",
                    string.format(
                        "%s\n\n是否重試？",
                        result or "無法連接伺服器"
                    ),
                    "重試",
                    "稍後再試"
                )
                
                if retry then
                    return FeedbackDialog.show()
                else
                    -- Save as draft
                    FeedbackDialog.saveDraft(properties)
                    LrDialogs.message(
                        "已儲存草稿",
                        "您的意見已儲存為草稿，可稍後再提交。",
                        "info"
                    )
                end
            end
        end
    end)
end

-- Show feedback history
function FeedbackDialog.showHistory()
    return LrFunctionContext.callWithContext("feedback_history", function(context)
        local f = LrView.osFactory()
        local feedbackManager = FeedbackManager:initialize()
        local history = feedbackManager:getHistory(20)
        
        -- Create history list
        local historyItems = {}
        for _, item in ipairs(history) do
            local date = LrDate.timeToUserFormat(item.timestamp, "%Y-%m-%d %H:%M")
            local type = FeedbackManager.FEEDBACK_TYPES[item.type] or item.type
            table.insert(historyItems, {
                title = string.format("[%s] %s - %s", date, type, item.title),
                value = item.submissionId
            })
        end
        
        if #historyItems == 0 then
            table.insert(historyItems, {
                title = "尚無提交記錄",
                value = ""
            })
        end
        
        -- Get statistics
        local stats = feedbackManager:getStatistics()
        
        local contents = f:column {
            spacing = f:control_spacing(),
            
            -- Statistics
            f:group_box {
                title = "統計資訊",
                font = "<system/small/bold>",
                
                f:column {
                    f:static_text {
                        title = string.format("總提交數: %d", stats.total),
                        font = "<system/small>"
                    },
                    f:static_text {
                        title = string.format("最後提交: %s", 
                                            stats.lastSubmission and 
                                            LrDate.timeToUserFormat(stats.lastSubmission, "%Y-%m-%d") or 
                                            "無"),
                        font = "<system/small>"
                    }
                }
            },
            
            -- History list
            f:static_text {
                title = "提交歷史（最近20條）:",
                font = "<system/small/bold>"
            },
            
            f:scrolled_view {
                width = 500,
                height = 200,
                f:simple_list {
                    items = historyItems
                }
            },
            
            -- Check for responses button
            f:push_button {
                title = "檢查官方回覆",
                action = function()
                    local responses = feedbackManager:checkForResponses()
                    if responses and #responses > 0 then
                        LrDialogs.message(
                            "官方回覆",
                            string.format("您有 %d 條新回覆", #responses),
                            "info"
                        )
                    else
                        LrDialogs.message(
                            "無新回覆",
                            "暫時沒有新的官方回覆",
                            "info"
                        )
                    end
                end
            }
        }
        
        LrDialogs.presentModalDialog {
            title = "意見提交歷史",
            contents = contents,
            actionVerb = "關閉"
        }
    end)
end

-- Save draft
function FeedbackDialog.saveDraft(properties)
    local Config = require 'src/utils/Config'
    Config.set("feedbackDraft", {
        feedbackType = properties.feedbackType,
        rating = properties.rating,
        title = properties.title,
        description = properties.description,
        usageFrequency = properties.usageFrequency,
        professionalLevel = properties.professionalLevel,
        userName = properties.userName,
        userEmail = properties.userEmail
    })
    Config.save()
end

-- Load draft
function FeedbackDialog.loadDraft()
    local Config = require 'src/utils/Config'
    return Config.get("feedbackDraft")
end

-- Clear draft
function FeedbackDialog.clearDraft()
    local Config = require 'src/utils/Config'
    Config.set("feedbackDraft", nil)
    Config.save()
end

return FeedbackDialog