--[[
    Module: Logger
    Description: Centralized logging system for debugging and error tracking
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local LrLogger = import 'LrLogger'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrDate = import 'LrDate'

-- Module definition
local Logger = {}
Logger.VERSION = "1.0.0"

-- Private variables
local _loggers = {}
local _globalLogLevel = 'info'
local _logToFile = true
local _logFilePath = nil

-- Log levels
local LOG_LEVELS = {
    trace = 1,
    debug = 2,
    info = 3,
    warn = 4,
    error = 5,
    fatal = 6
}

-- Initialize log file path
local function _initLogFile()
    local logDir = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), 'LightroomAISelector/logs')
    LrFileUtils.createAllDirectories(logDir)
    
    local timestamp = LrDate.timeToUserFormat(LrDate.currentTime(), "%Y%m%d_%H%M%S")
    _logFilePath = LrPathUtils.child(logDir, string.format("aiselector_%s.log", timestamp))
end

-- Write to log file
local function _writeToFile(message)
    if not _logToFile or not _logFilePath then
        return
    end
    
    local file = io.open(_logFilePath, "a")
    if file then
        file:write(message .. "\n")
        file:close()
    end
end

-- Format log message
local function _formatMessage(level, module, message, context)
    local timestamp = LrDate.timeToUserFormat(LrDate.currentTime(), "%Y-%m-%d %H:%M:%S")
    local contextStr = ""
    
    if context then
        local contextParts = {}
        for k, v in pairs(context) do
            table.insert(contextParts, string.format("%s=%s", k, tostring(v)))
        end
        contextStr = " [" .. table.concat(contextParts, ", ") .. "]"
    end
    
    return string.format("[%s] [%s] [%s] %s%s", timestamp, level:upper(), module, message, contextStr)
end

-- Create logger instance
function Logger:new(moduleName)
    if _loggers[moduleName] then
        return _loggers[moduleName]
    end
    
    local lrLogger = LrLogger(moduleName)
    
    local logger = {
        moduleName = moduleName,
        lrLogger = lrLogger,
        enabled = true
    }
    
    -- Initialize log file on first logger creation
    if not _logFilePath then
        _initLogFile()
    end
    
    -- Log method factory
    local function createLogMethod(level)
        return function(self, message, context)
            if not self.enabled then return end
            
            local currentLevel = LOG_LEVELS[_globalLogLevel] or LOG_LEVELS.info
            local messageLevel = LOG_LEVELS[level] or LOG_LEVELS.info
            
            if messageLevel >= currentLevel then
                local formattedMessage = _formatMessage(level, self.moduleName, message, context)
                
                -- Log to Lightroom console
                if level == 'trace' then
                    self.lrLogger:trace(message)
                elseif level == 'debug' then
                    self.lrLogger:debug(message)
                elseif level == 'info' then
                    self.lrLogger:info(message)
                elseif level == 'warn' then
                    self.lrLogger:warn(message)
                elseif level == 'error' or level == 'fatal' then
                    self.lrLogger:error(message)
                end
                
                -- Log to file
                _writeToFile(formattedMessage)
                
                -- Fatal errors should trigger error dialog
                if level == 'fatal' then
                    local LrDialogs = import 'LrDialogs'
                    LrDialogs.showError("致命錯誤: " .. message)
                end
            end
        end
    end
    
    -- Create log methods
    logger.trace = createLogMethod('trace')
    logger.debug = createLogMethod('debug')
    logger.info = createLogMethod('info')
    logger.warn = createLogMethod('warn')
    logger.error = createLogMethod('error')
    logger.fatal = createLogMethod('fatal')
    
    -- Enable/disable logger
    function logger:enable()
        self.enabled = true
    end
    
    function logger:disable()
        self.enabled = false
    end
    
    -- Performance logging
    function logger:startTimer(operationName)
        local startTime = LrDate.currentTime()
        return {
            operation = operationName,
            start = startTime,
            stop = function(self)
                local endTime = LrDate.currentTime()
                local duration = endTime - self.start
                logger:debug(string.format("Operation '%s' took %.2f seconds", self.operation, duration))
                return duration
            end
        }
    end
    
    _loggers[moduleName] = logger
    
    logger:info("Logger initialized for module: " .. moduleName)
    
    return logger
end

-- Global configuration
function Logger.setGlobalLogLevel(level)
    if LOG_LEVELS[level] then
        _globalLogLevel = level
    end
end

function Logger.enableFileLogging(enable)
    _logToFile = enable
end

function Logger.getLogFilePath()
    return _logFilePath
end

-- Cleanup function
function Logger.cleanup()
    for name, logger in pairs(_loggers) do
        logger:info("Logger shutting down")
    end
    _loggers = {}
end

return Logger