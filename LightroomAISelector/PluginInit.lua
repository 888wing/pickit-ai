--[[
    Module: PluginInit
    Description: Plugin initialization and lifecycle management
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local Logger = require 'src/utils/Logger'
local Config = require 'src/utils/Config'
local ErrorHandler = require 'src/utils/ErrorHandler'

local logger = Logger:new('PluginInit')

-- Plugin state
local PluginState = {
    initialized = false,
    modules = {},
    tasks = {},
    cleanupHandlers = {}
}

-- Initialize plugin
local function initializePlugin()
    logger:info("===========================================")
    logger:info("AI Photo Selector Plugin Initializing...")
    logger:info("===========================================")
    
    -- Load configuration
    local config = Config.load()
    logger:info("Configuration loaded", {
        environment = Config.getEnvironment(),
        version = _PLUGIN.version
    })
    
    -- Register error recovery strategies
    ErrorHandler.registerRecoveryStrategy(
        ErrorHandler.ErrorCodes.MEMORY_ERROR,
        function()
            -- Clean up memory
            collectgarbage("collect")
            -- Clear caches
            if PluginState.modules.cache then
                PluginState.modules.cache:clear()
            end
            return true
        end
    )
    
    ErrorHandler.registerRecoveryStrategy(
        ErrorHandler.ErrorCodes.MODEL_LOAD_FAILED,
        function()
            -- Try to reload models
            if PluginState.modules.modelLoader then
                return PluginState.modules.modelLoader:reload()
            end
            return false
        end
    )
    
    -- Initialize core modules
    local modulesToLoad = {
        -- Will add more modules as we develop them
        -- {name = "PhotoScorer", path = "src/core/PhotoScorer"},
        -- {name = "BatchProcessor", path = "src/core/BatchProcessor"},
        -- {name = "ModelLoader", path = "src/models/ModelLoader"},
    }
    
    for _, moduleInfo in ipairs(modulesToLoad) do
        local success, module = pcall(require, moduleInfo.path)
        if success then
            PluginState.modules[moduleInfo.name] = module
            if module.initialize then
                module:initialize(config)
            end
            logger:info("Module loaded: " .. moduleInfo.name)
        else
            logger:error("Failed to load module: " .. moduleInfo.name, {
                error = tostring(module)
            })
        end
    end
    
    -- Set initialized flag
    PluginState.initialized = true
    
    logger:info("Plugin initialization complete")
    
    -- Show initialization notification in development mode
    if Config.isDevelopment() then
        local LrDialogs = import 'LrDialogs'
        LrDialogs.message(
            "AI Photo Selector - Development Mode",
            "Plugin initialized successfully!\n" ..
            "Environment: " .. Config.getEnvironment() .. "\n" ..
            "Log Level: " .. config.logLevel
        )
    end
end

-- Shutdown plugin
local function shutdownPlugin()
    logger:info("===========================================")
    logger:info("AI Photo Selector Plugin Shutting Down...")
    logger:info("===========================================")
    
    -- Cancel all running tasks
    for taskId, task in pairs(PluginState.tasks) do
        if task.cancel then
            task:cancel()
        end
        logger:debug("Task cancelled: " .. taskId)
    end
    PluginState.tasks = {}
    
    -- Run cleanup handlers
    for name, handler in pairs(PluginState.cleanupHandlers) do
        local success, err = pcall(handler)
        if not success then
            logger:error("Cleanup handler failed: " .. name, {error = err})
        else
            logger:debug("Cleanup handler executed: " .. name)
        end
    end
    
    -- Cleanup modules
    for name, module in pairs(PluginState.modules) do
        if module.cleanup then
            local success, err = pcall(module.cleanup, module)
            if not success then
                logger:error("Module cleanup failed: " .. name, {error = err})
            else
                logger:debug("Module cleaned up: " .. name)
            end
        end
    end
    PluginState.modules = {}
    
    -- Cleanup utilities
    ErrorHandler.cleanup()
    Config.cleanup()
    Logger.cleanup()
    
    PluginState.initialized = false
    
    -- Force garbage collection
    collectgarbage("collect")
end

-- Register cleanup handler
local function registerCleanupHandler(name, handler)
    PluginState.cleanupHandlers[name] = handler
    logger:debug("Cleanup handler registered: " .. name)
end

-- Register task
local function registerTask(taskId, task)
    PluginState.tasks[taskId] = task
    logger:debug("Task registered: " .. taskId)
end

-- Unregister task
local function unregisterTask(taskId)
    PluginState.tasks[taskId] = nil
    logger:debug("Task unregistered: " .. taskId)
end

-- Get module
local function getModule(name)
    return PluginState.modules[name]
end

-- Check if initialized
local function isInitialized()
    return PluginState.initialized
end

-- Plugin lifecycle hooks
local LrTasks = import 'LrTasks'

-- Auto-initialize on first use
local initialized = false
local function ensureInitialized()
    if not initialized then
        LrTasks.startAsyncTask(function()
            initializePlugin()
        end)
        initialized = true
    end
end

-- Export public interface
return {
    initialize = initializePlugin,
    shutdown = shutdownPlugin,
    ensureInitialized = ensureInitialized,
    registerCleanupHandler = registerCleanupHandler,
    registerTask = registerTask,
    unregisterTask = unregisterTask,
    getModule = getModule,
    isInitialized = isInitialized,
    
    -- Plugin metadata
    version = "1.0.0",
    name = "AI Photo Selector",
}