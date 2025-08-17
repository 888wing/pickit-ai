--[[
    Pickit Feedback Manager
    Handles user feedback submission to Google Sheets
    Created: 2025-01-20
--]]

local LrHttp = import 'LrHttp'
local LrApplication = import 'LrApplication'
local LrSystemInfo = import 'LrSystemInfo'
local LrDate = import 'LrDate'

local Logger = require 'src/utils/Logger'
local ErrorHandler = require 'src/utils/ErrorHandler'
local Config = require 'src/utils/Config'

-- Feedback Manager module
local FeedbackManager = {
    logger = Logger:new("FeedbackManager"),
    initialized = false,
    nodebridge = nil,
    cache = {}
}

-- Feedback types
FeedbackManager.FEEDBACK_TYPES = {
    feature_request = "功能建議",
    bug_report = "錯誤回報", 
    performance_issue = "性能問題",
    ui_feedback = "界面意見",
    workflow_suggestion = "工作流程建議",
    general_feedback = "一般意見",
    praise = "讚賞鼓勵"
}

-- Usage frequency options
FeedbackManager.USAGE_FREQUENCY = {
    daily = "每天",
    weekly = "每週數次",
    monthly = "每月數次",
    occasionally = "偶爾"
}

-- Professional level options
FeedbackManager.PROFESSIONAL_LEVEL = {
    professional = "專業攝影師",
    semi_professional = "半專業攝影師",
    enthusiast = "攝影愛好者",
    beginner = "初學者"
}

-- Initialize feedback manager
function FeedbackManager:initialize()
    if self.initialized then
        return self
    end
    
    self.nodebridge = require('src/models/NodeBridge')
    self.logger:info("FeedbackManager initialized")
    self.initialized = true
    
    -- Load cached unsent feedback if any
    self:loadCachedFeedback()
    
    return self
end

-- Generate unique submission ID
function FeedbackManager:generateSubmissionId()
    local date = LrDate.currentTime()
    local dateStr = LrDate.timeToUserFormat(date, "%Y%m%d")
    local random = math.random(1000, 9999)
    return string.format("FB%s%04d", dateStr, random)
end

-- Collect system information
function FeedbackManager:collectSystemInfo()
    return {
        pluginVersion = Config.get("version") or "1.0.0",
        lightroomVersion = LrApplication.versionString(),
        osInfo = LrSystemInfo.osVersion(),
        deviceInfo = string.format("%s (%s)", 
                                  LrSystemInfo.computerName(),
                                  LrSystemInfo.summaryString()),
        memorySize = LrSystemInfo.memSize(),
        numCPUs = LrSystemInfo.numCPUs()
    }
end

-- Validate feedback data
function FeedbackManager:validateFeedback(feedbackData)
    -- Required fields
    if not feedbackData.feedbackType then
        return false, "意見類型為必填"
    end
    
    if not feedbackData.title or feedbackData.title == "" then
        return false, "標題為必填"
    end
    
    if not feedbackData.description or feedbackData.description == "" then
        return false, "詳細描述為必填"
    end
    
    -- Validate email format if provided
    if feedbackData.userEmail and feedbackData.userEmail ~= "" then
        local emailPattern = "^[%w%._%+%-]+@[%w%.%-]+%.%w+$"
        if not string.match(feedbackData.userEmail, emailPattern) then
            return false, "請輸入有效的電子郵件地址"
        end
    end
    
    -- Validate rating range
    if feedbackData.rating then
        if feedbackData.rating < 1 or feedbackData.rating > 5 then
            return false, "評分必須在 1-5 之間"
        end
    end
    
    return true
end

-- Submit feedback
function FeedbackManager:submitFeedback(feedbackData)
    self.logger:info("Submitting feedback...")
    
    -- Validate input
    local valid, errorMsg = self:validateFeedback(feedbackData)
    if not valid then
        self.logger:error("Validation failed: " .. errorMsg)
        return false, errorMsg
    end
    
    -- Add system information
    local systemInfo = self:collectSystemInfo()
    for key, value in pairs(systemInfo) do
        feedbackData[key] = value
    end
    
    -- Generate submission ID
    feedbackData.submissionId = self:generateSubmissionId()
    feedbackData.timestamp = LrDate.currentTime()
    
    -- Prepare request data
    local requestData = {
        submissionId = feedbackData.submissionId,
        timestamp = LrDate.timeToW3CDate(feedbackData.timestamp),
        pluginVersion = feedbackData.pluginVersion,
        lightroomVersion = feedbackData.lightroomVersion,
        osInfo = feedbackData.osInfo,
        feedbackType = feedbackData.feedbackType,
        category = feedbackData.category or "",
        rating = feedbackData.rating or 0,
        title = feedbackData.title,
        description = feedbackData.description,
        userName = feedbackData.userName or "",
        userEmail = feedbackData.userEmail or "",
        contactPermission = feedbackData.allowContact or false,
        screenshotUrl = feedbackData.screenshotUrl or "",
        deviceInfo = feedbackData.deviceInfo,
        usageFrequency = feedbackData.usageFrequency or "",
        professionalLevel = feedbackData.professionalLevel or "",
        status = "pending"
    }
    
    -- Try to submit via API
    local success, result = self.nodebridge:post('/feedback/submit', requestData)
    
    if success then
        self.logger:info("Feedback submitted successfully: " .. feedbackData.submissionId)
        
        -- Store in success history
        self:addToHistory(feedbackData, "submitted")
        
        -- Clear any cached feedback for this submission
        self:removeCachedFeedback(feedbackData.submissionId)
        
        return true, feedbackData.submissionId
    else
        self.logger:error("Failed to submit feedback: " .. tostring(result))
        
        -- Cache feedback for later submission
        self:cacheFeedback(feedbackData)
        
        return false, "無法連接伺服器，意見已暫存並將稍後自動提交"
    end
end

-- Cache feedback for offline submission
function FeedbackManager:cacheFeedback(feedbackData)
    self.logger:info("Caching feedback for later submission")
    
    table.insert(self.cache, feedbackData)
    
    -- Save to persistent storage
    Config.set("cachedFeedback", self.cache)
    Config.save()
end

-- Load cached feedback from storage
function FeedbackManager:loadCachedFeedback()
    self.cache = Config.get("cachedFeedback") or {}
    
    if #self.cache > 0 then
        self.logger:info(string.format("Loaded %d cached feedback items", #self.cache))
        
        -- Try to submit cached feedback
        self:submitCachedFeedback()
    end
end

-- Remove cached feedback
function FeedbackManager:removeCachedFeedback(submissionId)
    for i = #self.cache, 1, -1 do
        if self.cache[i].submissionId == submissionId then
            table.remove(self.cache, i)
            break
        end
    end
    
    -- Update persistent storage
    Config.set("cachedFeedback", self.cache)
    Config.save()
end

-- Submit cached feedback
function FeedbackManager:submitCachedFeedback()
    if #self.cache == 0 then
        return
    end
    
    self.logger:info(string.format("Attempting to submit %d cached feedback items", #self.cache))
    
    local submitted = 0
    local failed = 0
    
    -- Try to submit each cached item
    for i = #self.cache, 1, -1 do
        local feedbackData = self.cache[i]
        
        -- Try to submit
        local success = self.nodebridge:post('/feedback/submit', feedbackData)
        
        if success then
            submitted = submitted + 1
            table.remove(self.cache, i)
        else
            failed = failed + 1
        end
    end
    
    self.logger:info(string.format("Cached submission: %d submitted, %d failed", 
                                  submitted, failed))
    
    -- Update persistent storage
    if submitted > 0 then
        Config.set("cachedFeedback", self.cache)
        Config.save()
    end
end

-- Add feedback to history
function FeedbackManager:addToHistory(feedbackData, status)
    local history = Config.get("feedbackHistory") or {}
    
    table.insert(history, {
        submissionId = feedbackData.submissionId,
        timestamp = feedbackData.timestamp,
        type = feedbackData.feedbackType,
        title = feedbackData.title,
        status = status
    })
    
    -- Keep only last 50 items
    if #history > 50 then
        table.remove(history, 1)
    end
    
    Config.set("feedbackHistory", history)
    Config.save()
end

-- Get feedback history
function FeedbackManager:getHistory(limit)
    local history = Config.get("feedbackHistory") or {}
    limit = limit or 10
    
    local result = {}
    local startIdx = math.max(1, #history - limit + 1)
    
    for i = startIdx, #history do
        table.insert(result, history[i])
    end
    
    return result
end

-- Get feedback statistics
function FeedbackManager:getStatistics()
    local history = Config.get("feedbackHistory") or {}
    local stats = {
        total = #history,
        byType = {},
        lastSubmission = nil
    }
    
    -- Count by type
    for _, item in ipairs(history) do
        local type = item.type or "unknown"
        stats.byType[type] = (stats.byType[type] or 0) + 1
    end
    
    -- Get last submission time
    if #history > 0 then
        stats.lastSubmission = history[#history].timestamp
    end
    
    return stats
end

-- Check for updates on previous feedback
function FeedbackManager:checkForResponses()
    self.logger:info("Checking for feedback responses...")
    
    local history = self:getHistory(10)
    
    if #history == 0 then
        return nil
    end
    
    -- Collect submission IDs
    local submissionIds = {}
    for _, item in ipairs(history) do
        table.insert(submissionIds, item.submissionId)
    end
    
    -- Query for responses
    local success, responses = self.nodebridge:post('/feedback/check-responses', {
        submissionIds = submissionIds
    })
    
    if success and responses then
        self.logger:info(string.format("Found %d responses", #responses))
        return responses
    end
    
    return nil
end

-- Take screenshot for feedback
function FeedbackManager:captureScreenshot()
    -- This would require platform-specific implementation
    -- For now, return nil
    self.logger:info("Screenshot capture not yet implemented")
    return nil
end

-- Cleanup
function FeedbackManager:cleanup()
    -- Submit any remaining cached feedback
    if #self.cache > 0 then
        self:submitCachedFeedback()
    end
    
    self.initialized = false
    self.logger:info("FeedbackManager cleaned up")
end

return FeedbackManager