--[[
    Module: Config
    Description: Configuration management for development and production environments
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local Logger = require 'src/utils/Logger'
local logger = Logger:new('Config')

-- Module definition
local Config = {}
Config.VERSION = "1.0.0"

-- Private variables
local _config = {}
local _environment = nil
local _configLoaded = false

-- Default configurations
local DEFAULT_CONFIG = {
    development = {
        -- Logging
        logLevel = "trace",
        logToFile = true,
        enableDebugUI = true,
        
        -- Performance
        batchSize = 20,
        maxConcurrentTasks = 2,
        cacheEnabled = true,
        cacheSize = 100,
        
        -- AI Models
        modelPath = "models/dev/",
        useLocalModels = true,
        modelTimeout = 30, -- seconds
        
        -- API
        apiEndpoint = "https://dev-api.pickit.ai",
        apiTimeout = 10,
        apiRetries = 3,
        
        -- Features
        enableCloudFeatures = false,
        enableAnalytics = false,
        enableAutoUpdate = false,
        
        -- UI
        showAdvancedOptions = true,
        showDebugInfo = true,
        defaultThreshold = 0.7,
    },
    
    production = {
        -- Logging
        logLevel = "info",
        logToFile = true,
        enableDebugUI = false,
        
        -- Performance
        batchSize = 50,
        maxConcurrentTasks = 4,
        cacheEnabled = true,
        cacheSize = 500,
        
        -- AI Models
        modelPath = "models/prod/",
        useLocalModels = true,
        modelTimeout = 60,
        
        -- API
        apiEndpoint = "https://api.pickit.ai",
        apiTimeout = 30,
        apiRetries = 5,
        
        -- Features
        enableCloudFeatures = true,
        enableAnalytics = true,
        enableAutoUpdate = true,
        
        -- UI
        showAdvancedOptions = false,
        showDebugInfo = false,
        defaultThreshold = 0.75,
    },
    
    test = {
        -- Logging
        logLevel = "debug",
        logToFile = true,
        enableDebugUI = true,
        
        -- Performance
        batchSize = 10,
        maxConcurrentTasks = 1,
        cacheEnabled = false,
        cacheSize = 10,
        
        -- AI Models
        modelPath = "models/test/",
        useLocalModels = true,
        modelTimeout = 5,
        
        -- API
        apiEndpoint = "https://test-api.pickit.ai",
        apiTimeout = 5,
        apiRetries = 1,
        
        -- Features
        enableCloudFeatures = false,
        enableAnalytics = false,
        enableAutoUpdate = false,
        
        -- UI
        showAdvancedOptions = true,
        showDebugInfo = true,
        defaultThreshold = 0.5,
    }
}

-- User preferences (persisted)
local USER_PREFERENCES = {
    -- Scoring weights
    technicalWeight = 0.4,
    aestheticWeight = 0.6,
    
    -- Processing options
    enableFaceDetection = true,
    enableSceneDetection = true,
    enableDuplicateDetection = true,
    
    -- Thresholds
    qualityThreshold = 0.75,
    similarityThreshold = 0.85,
    blurThreshold = 100,
    
    -- UI preferences
    windowSize = {width = 900, height = 600},
    thumbnailSize = 150,
    resultsPerPage = 50,
    
    -- Performance
    preferredBatchSize = nil, -- Use environment default
    maxMemoryUsage = 500, -- MB
}

-- Detect environment
local function _detectEnvironment()
    -- Check for environment variable
    local env = os.getenv("PICKIT_ENV")
    if env then
        logger:info("Environment from variable: " .. env)
        return env
    end
    
    -- Check for debug flag file
    local LrFileUtils = import 'LrFileUtils'
    local LrPathUtils = import 'LrPathUtils'
    local debugFile = LrPathUtils.child(
        LrPathUtils.parent(_PLUGIN.path),
        ".debug"
    )
    
    if LrFileUtils.exists(debugFile) then
        logger:info("Debug file found, using development environment")
        return "development"
    end
    
    -- Default to production
    logger:info("Using production environment")
    return "production"
end

-- Load configuration
function Config.load()
    if _configLoaded then
        return _config
    end
    
    -- Detect environment
    _environment = _detectEnvironment()
    
    -- Load environment config
    _config = DEFAULT_CONFIG[_environment] or DEFAULT_CONFIG.production
    
    -- Load user preferences
    local LrPrefs = import 'LrPrefs'
    local prefs = LrPrefs.prefsForPlugin(_PLUGIN.id)
    
    -- Merge user preferences
    for key, defaultValue in pairs(USER_PREFERENCES) do
        local userValue = prefs[key]
        if userValue ~= nil then
            _config[key] = userValue
        else
            _config[key] = defaultValue
        end
    end
    
    -- Apply log level
    Logger.setGlobalLogLevel(_config.logLevel)
    Logger.enableFileLogging(_config.logToFile)
    
    _configLoaded = true
    
    logger:info("Configuration loaded", {
        environment = _environment,
        logLevel = _config.logLevel
    })
    
    return _config
end

-- Get configuration value
function Config.get(key, defaultValue)
    if not _configLoaded then
        Config.load()
    end
    
    local value = _config[key]
    if value ~= nil then
        return value
    end
    
    return defaultValue
end

-- Set configuration value (runtime only)
function Config.set(key, value)
    if not _configLoaded then
        Config.load()
    end
    
    _config[key] = value
    logger:debug("Config updated", {key = key, value = value})
end

-- Save user preference
function Config.savePreference(key, value)
    if USER_PREFERENCES[key] == nil then
        logger:warn("Unknown preference key: " .. key)
        return false
    end
    
    local LrPrefs = import 'LrPrefs'
    local prefs = LrPrefs.prefsForPlugin(_PLUGIN.id)
    prefs[key] = value
    
    -- Update runtime config
    _config[key] = value
    
    logger:info("Preference saved", {key = key, value = value})
    return true
end

-- Get all user preferences
function Config.getPreferences()
    local prefs = {}
    for key, _ in pairs(USER_PREFERENCES) do
        prefs[key] = Config.get(key)
    end
    return prefs
end

-- Reset preferences to defaults
function Config.resetPreferences()
    local LrPrefs = import 'LrPrefs'
    local prefs = LrPrefs.prefsForPlugin(_PLUGIN.id)
    
    for key, defaultValue in pairs(USER_PREFERENCES) do
        prefs[key] = nil
        _config[key] = defaultValue
    end
    
    logger:info("Preferences reset to defaults")
end

-- Get environment
function Config.getEnvironment()
    if not _environment then
        _environment = _detectEnvironment()
    end
    return _environment
end

-- Check if in development mode
function Config.isDevelopment()
    return Config.getEnvironment() == "development"
end

-- Check if in production mode
function Config.isProduction()
    return Config.getEnvironment() == "production"
end

-- Check if feature is enabled
function Config.isFeatureEnabled(feature)
    return Config.get("enable" .. feature, false)
end

-- Get model configuration
function Config.getModelConfig()
    return {
        path = Config.get("modelPath"),
        useLocal = Config.get("useLocalModels"),
        timeout = Config.get("modelTimeout"),
    }
end

-- Get API configuration
function Config.getAPIConfig()
    return {
        endpoint = Config.get("apiEndpoint"),
        timeout = Config.get("apiTimeout"),
        retries = Config.get("apiRetries"),
    }
end

-- Get performance configuration
function Config.getPerformanceConfig()
    return {
        batchSize = Config.get("preferredBatchSize") or Config.get("batchSize"),
        maxConcurrentTasks = Config.get("maxConcurrentTasks"),
        cacheEnabled = Config.get("cacheEnabled"),
        cacheSize = Config.get("cacheSize"),
        maxMemoryUsage = Config.get("maxMemoryUsage"),
    }
end

-- Export configuration (for debugging)
function Config.export()
    return {
        environment = _environment,
        config = _config,
        version = Config.VERSION
    }
end

-- Cleanup
function Config.cleanup()
    _config = {}
    _configLoaded = false
    logger:info("Config cleaned up")
end

return Config