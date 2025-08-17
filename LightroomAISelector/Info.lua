--[[
    Lightroom AI Selector Plugin
    Plugin Information and Configuration
    Created: 2025-01-01
--]]

return {
    LrSdkVersion = 12.0,
    LrSdkMinimumVersion = 12.0,
    
    LrToolkitIdentifier = 'com.pickit.aiselector',
    LrPluginName = "Pickit - AI Photo Selector",
    LrPluginVersion = "1.0.0",
    
    LrPluginInfoProvider = 'PluginInfoProvider.lua',
    
    -- Export Service Provider
    LrExportServiceProvider = {
        title = "AI Photo Selection",
        file = 'AIPhotoSelectionService.lua',
        builtInPresetsDir = 'presets',
    },
    
    -- Library Menu Items
    LrLibraryMenuItems = {
        {
            title = "Pickit - AI智能選片",
            file = "src/ui/MainDialog.lua",
            enabledWhen = "photosSelected",
        },
        {
            title = "Pickit - 批次評分",
            file = "src/ui/BatchScoring.lua",
            enabledWhen = "photosSelected",
        },
        {
            title = "Pickit - 設定",
            file = "src/ui/Settings.lua",
        },
        {
            title = "Pickit - 意見回饋",
            file = "src/ui/FeedbackDialog.lua",
        },
    },
    
    -- Metadata Definition
    LrMetadataProvider = 'MetadataDefinition.lua',
    
    VERSION = { major=1, minor=0, revision=0, build=1 },
}