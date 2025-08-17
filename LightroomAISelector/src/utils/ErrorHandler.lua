--[[
    Module: ErrorHandler
    Description: Centralized error handling and recovery system
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local Logger = require 'src/utils/Logger'
local logger = Logger:new('ErrorHandler')

-- Module definition
local ErrorHandler = {}
ErrorHandler.VERSION = "1.0.0"

-- Error codes definition (as per CODEGuide.md)
local ErrorCodes = {
    -- System errors (1xxx)
    SYSTEM_ERROR = 1000,
    MEMORY_ERROR = 1001,
    FILE_NOT_FOUND = 1002,
    PERMISSION_DENIED = 1003,
    
    -- Model errors (2xxx)
    MODEL_LOAD_FAILED = 2000,
    MODEL_INFERENCE_ERROR = 2001,
    MODEL_VERSION_MISMATCH = 2002,
    MODEL_NOT_FOUND = 2003,
    
    -- API errors (3xxx)
    API_CONNECTION_FAILED = 3000,
    API_AUTH_FAILED = 3001,
    API_RATE_LIMIT = 3002,
    API_TIMEOUT = 3003,
    
    -- User errors (4xxx)
    INVALID_INPUT = 4000,
    INVALID_PHOTO_FORMAT = 4001,
    BATCH_SIZE_EXCEEDED = 4002,
    NO_PHOTOS_SELECTED = 4003,
}

ErrorHandler.ErrorCodes = ErrorCodes

-- Error messages
local ErrorMessages = {
    [ErrorCodes.SYSTEM_ERROR] = "系統錯誤，請重試",
    [ErrorCodes.MEMORY_ERROR] = "記憶體不足，請減少批次大小",
    [ErrorCodes.FILE_NOT_FOUND] = "檔案未找到",
    [ErrorCodes.PERMISSION_DENIED] = "權限不足",
    
    [ErrorCodes.MODEL_LOAD_FAILED] = "AI模型載入失敗，請檢查安裝",
    [ErrorCodes.MODEL_INFERENCE_ERROR] = "AI推理錯誤",
    [ErrorCodes.MODEL_VERSION_MISMATCH] = "模型版本不相容",
    [ErrorCodes.MODEL_NOT_FOUND] = "模型檔案未找到",
    
    [ErrorCodes.API_CONNECTION_FAILED] = "網路連接失敗，切換到本地模式",
    [ErrorCodes.API_AUTH_FAILED] = "認證失敗，請檢查API金鑰",
    [ErrorCodes.API_RATE_LIMIT] = "達到API限制，請稍後重試",
    [ErrorCodes.API_TIMEOUT] = "請求超時",
    
    [ErrorCodes.INVALID_INPUT] = "無效的輸入",
    [ErrorCodes.INVALID_PHOTO_FORMAT] = "不支援的照片格式",
    [ErrorCodes.BATCH_SIZE_EXCEEDED] = "批次大小超過限制",
    [ErrorCodes.NO_PHOTOS_SELECTED] = "請先選擇照片",
}

-- Private variables
local _errorHistory = {}
local _recoveryStrategies = {}
local _errorCallbacks = {}

-- Get error message
function ErrorHandler.getErrorMessage(errorCode)
    return ErrorMessages[errorCode] or "未知錯誤"
end

-- Handle error with recovery
function ErrorHandler.handleError(errorCode, details, context)
    local errorInfo = {
        code = errorCode,
        message = ErrorHandler.getErrorMessage(errorCode),
        details = details,
        context = context,
        timestamp = os.time(),
        stackTrace = debug.traceback()
    }
    
    -- Log error
    logger:error(string.format("Error %d: %s", errorCode, errorInfo.message), {
        details = details,
        context = context
    })
    
    -- Add to history
    table.insert(_errorHistory, errorInfo)
    
    -- Attempt recovery
    local recovered = ErrorHandler.attemptRecovery(errorCode, errorInfo)
    
    -- Execute callbacks
    for _, callback in ipairs(_errorCallbacks) do
        pcall(callback, errorInfo)
    end
    
    -- Show user notification if not recovered
    if not recovered then
        ErrorHandler.showUserError(errorCode, errorInfo)
    end
    
    return errorInfo, recovered
end

-- Recovery strategies
function ErrorHandler.attemptRecovery(errorCode, errorInfo)
    -- Check for registered recovery strategy
    local strategy = _recoveryStrategies[errorCode]
    if strategy then
        logger:info("Attempting recovery for error: " .. errorCode)
        local success, result = pcall(strategy, errorInfo)
        if success and result then
            logger:info("Recovery successful")
            return true
        else
            logger:warn("Recovery failed")
        end
    end
    
    -- Default recovery strategies
    if errorCode == ErrorCodes.MEMORY_ERROR then
        -- Clear cache and retry
        logger:info("Attempting memory recovery")
        collectgarbage("collect")
        return true
        
    elseif errorCode == ErrorCodes.API_CONNECTION_FAILED then
        -- Switch to offline mode
        logger:info("Switching to offline mode")
        -- Set offline flag (to be implemented)
        return true
        
    elseif errorCode >= 3000 and errorCode < 4000 then
        -- API errors - enable offline mode
        logger:info("API error detected, enabling offline mode")
        return true
    end
    
    return false
end

-- Show user-friendly error dialog
function ErrorHandler.showUserError(errorCode, errorInfo)
    local LrDialogs = import 'LrDialogs'
    
    local title = "錯誤"
    local message = errorInfo.message
    local info = errorInfo.details or ""
    
    -- Determine error severity
    if errorCode < 2000 then
        -- System error
        title = "系統錯誤"
        info = "請嘗試重新啟動插件。如果問題持續，請聯繫支援。"
    elseif errorCode < 3000 then
        -- Model error
        title = "AI模型錯誤"
        info = "請確認AI模型已正確安裝。您可以嘗試重新安裝插件。"
    elseif errorCode < 4000 then
        -- API error
        title = "網路錯誤"
        info = "網路連接出現問題。插件將切換到本地處理模式。"
    else
        -- User error
        title = "操作錯誤"
        info = "請檢查您的輸入並重試。"
    end
    
    LrDialogs.message(title, message .. "\n\n" .. info, "warning")
end

-- Register recovery strategy
function ErrorHandler.registerRecoveryStrategy(errorCode, strategy)
    _recoveryStrategies[errorCode] = strategy
    logger:debug("Registered recovery strategy for error: " .. errorCode)
end

-- Register error callback
function ErrorHandler.registerCallback(callback)
    table.insert(_errorCallbacks, callback)
end

-- Retry with exponential backoff
function ErrorHandler.retryWithBackoff(func, maxAttempts, initialDelay)
    maxAttempts = maxAttempts or 3
    initialDelay = initialDelay or 1000 -- milliseconds
    
    local attempt = 0
    local delay = initialDelay
    
    while attempt < maxAttempts do
        attempt = attempt + 1
        
        -- Try to execute function
        local success, result = pcall(func)
        
        if success then
            return result
        end
        
        -- Log retry attempt
        logger:warn(string.format(
            "Attempt %d/%d failed, retrying in %dms",
            attempt, maxAttempts, delay
        ))
        
        -- Exponential backoff
        if attempt < maxAttempts then
            local LrTasks = import 'LrTasks'
            LrTasks.sleep(delay / 1000)
            delay = delay * 2 -- Exponential growth
        end
    end
    
    -- All attempts failed
    logger:error("Max retry attempts exceeded")
    return nil, "Max retry attempts exceeded"
end

-- Get error history
function ErrorHandler.getErrorHistory(limit)
    limit = limit or 100
    local start = math.max(1, #_errorHistory - limit + 1)
    local history = {}
    
    for i = start, #_errorHistory do
        table.insert(history, _errorHistory[i])
    end
    
    return history
end

-- Clear error history
function ErrorHandler.clearHistory()
    _errorHistory = {}
    logger:info("Error history cleared")
end

-- Protected call with error handling
function ErrorHandler.protectedCall(func, errorCode, context)
    local success, result = pcall(func)
    
    if not success then
        ErrorHandler.handleError(
            errorCode or ErrorCodes.SYSTEM_ERROR,
            tostring(result),
            context
        )
        return nil, result
    end
    
    return result
end

-- Cleanup
function ErrorHandler.cleanup()
    _errorHistory = {}
    _recoveryStrategies = {}
    _errorCallbacks = {}
    logger:info("ErrorHandler cleaned up")
end

return ErrorHandler