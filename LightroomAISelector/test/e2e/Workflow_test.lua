--[[
    End-to-End Workflow Tests
    Simulates complete user workflows from start to finish
--]]

local PhotoScorer = require 'src/core/PhotoScorer'
local BatchProcessor = require 'src/core/BatchProcessor'
local SimilarityDetector = require 'src/core/SimilarityDetector'
local NodeBridge = require 'src/models/NodeBridge'
local Config = require 'src/utils/Config'
local Logger = require 'src/utils/Logger'
local ErrorHandler = require 'src/utils/ErrorHandler'

-- Test module
local WorkflowTest = {
    logger = Logger:new("WorkflowTest"),
    
    setup = function()
        Config.load()
        PhotoScorer:initialize()
        BatchProcessor:initialize()
        SimilarityDetector:initialize()
        NodeBridge:initialize()
    end,
    
    teardown = function()
        PhotoScorer:cleanup()
        BatchProcessor:cleanup()
        SimilarityDetector:cleanup()
        NodeBridge:cleanup()
    end,
    
    tests = {}
}

-- Mock photo creation with realistic metadata
local function createRealisticPhotoBatch(scenario)
    local photos = {}
    
    if scenario == "wedding" then
        -- Wedding scenario: mix of portraits, groups, details
        for i = 1, 20 do
            local photoType = i % 3
            photos[i] = {
                localIdentifier = "wedding-" .. i,
                getRawMetadata = function(self, key)
                    local metadata = {
                        path = "/wedding/photo" .. i .. ".jpg",
                        width = 6000,
                        height = 4000,
                        fileSize = 12582912,  -- 12MB
                        fileFormat = "JPG",
                        dateTimeOriginal = os.time() + i * 30,
                        isoSpeedRating = photoType == 0 and 800 or 400,
                        aperture = photoType == 1 and 1.4 or 2.8,
                        shutterSpeed = 1/250,
                        focalLength = photoType == 2 and 85 or 50
                    }
                    return metadata[key]
                end,
                getDevelopSettings = function() return {} end,
                setRawMetadata = function(self, key, value)
                    self[key] = value
                    return true
                end
            }
        end
        
    elseif scenario == "sports" then
        -- Sports scenario: burst sequences, action shots
        local baseTime = os.time()
        for i = 1, 30 do
            local burstGroup = math.floor((i-1) / 5)  -- 5 photos per burst
            photos[i] = {
                localIdentifier = "sports-" .. i,
                getRawMetadata = function(self, key)
                    local metadata = {
                        path = "/sports/action" .. i .. ".jpg",
                        width = 6000,
                        height = 4000,
                        fileSize = 10485760,  -- 10MB
                        fileFormat = "JPG",
                        dateTimeOriginal = baseTime + burstGroup * 60 + (i % 5) * 0.2,
                        isoSpeedRating = 1600,
                        aperture = 2.8,
                        shutterSpeed = 1/2000,
                        focalLength = 300
                    }
                    return metadata[key]
                end,
                getDevelopSettings = function() return {} end,
                setRawMetadata = function() return true end
            }
        end
        
    elseif scenario == "landscape" then
        -- Landscape scenario: HDR brackets, panoramas
        for i = 1, 15 do
            local bracketGroup = math.floor((i-1) / 3)  -- 3 exposure brackets
            photos[i] = {
                localIdentifier = "landscape-" .. i,
                getRawMetadata = function(self, key)
                    local metadata = {
                        path = "/landscape/scene" .. i .. ".jpg",
                        width = 7360,
                        height = 4912,
                        fileSize = 20971520,  -- 20MB
                        fileFormat = "JPG",
                        dateTimeOriginal = os.time() + bracketGroup * 300,
                        isoSpeedRating = 100,
                        aperture = 11,
                        shutterSpeed = (i % 3 == 0) and 1/125 or ((i % 3 == 1) and 1/60 or 1/250),
                        focalLength = 24
                    }
                    return metadata[key]
                end,
                getDevelopSettings = function() return {} end,
                setRawMetadata = function() return true end
            }
        end
    end
    
    return photos
end

-- Test 1: Complete wedding workflow
WorkflowTest.tests.test_wedding_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting wedding workflow test...")
    
    -- Create wedding photos
    local photos = createRealisticPhotoBatch("wedding")
    
    -- Configure for wedding photography
    Config.set("qualityThreshold", 0.7)
    Config.set("technicalWeight", 0.3)
    Config.set("aestheticWeight", 0.7)  -- Emphasize aesthetics
    
    -- Process batch
    local processedCount = 0
    local passedPhotos = {}
    
    BatchProcessor:processBatch(photos, {
        enableAI = true,
        enableFaceDetection = true,
        enableGrouping = true,
        autoRate = true,
        autoLabel = true,
        passedLabel = "green",
        threshold = 0.7
    }, function(progress)
        processedCount = progress.current or processedCount
        if progress.phase == "finalizing" and progress.results then
            for _, result in ipairs(progress.results) do
                if result.passed then
                    table.insert(passedPhotos, result)
                end
            end
        end
        return true
    end)
    
    -- Verify results
    WorkflowTest.logger:info(string.format(
        "Wedding workflow: %d processed, %d passed",
        processedCount, #passedPhotos
    ))
    
    assert(processedCount == #photos, "All photos should be processed")
    assert(#passedPhotos > 0, "Some photos should pass")
    assert(#passedPhotos < #photos, "Not all photos should pass (quality filter)")
    
    WorkflowTest.teardown()
end

-- Test 2: Sports burst sequence workflow
WorkflowTest.tests.test_sports_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting sports workflow test...")
    
    -- Create sports photos with bursts
    local photos = createRealisticPhotoBatch("sports")
    
    -- Configure for sports photography
    Config.set("qualityThreshold", 0.65)
    Config.set("technicalWeight", 0.7)  -- Emphasize sharpness
    Config.set("aestheticWeight", 0.3)
    Config.set("blurThreshold", 150)  -- Stricter blur detection
    
    -- Process with similarity detection
    local groups = {}
    
    BatchProcessor:processBatch(photos, {
        enableAI = false,  -- Faster processing for sports
        enableFaceDetection = false,
        enableGrouping = true,
        similarityThreshold = 0.9,  -- High similarity for burst detection
        autoRate = true,
        threshold = 0.65
    }, function(progress)
        if progress.phase == "grouping" and progress.groups then
            groups = progress.groups
        end
        return true
    end)
    
    -- Verify burst detection
    WorkflowTest.logger:info(string.format(
        "Sports workflow: Detected %d burst groups from %d photos",
        #groups, #photos
    ))
    
    assert(#groups > 0, "Burst groups should be detected")
    assert(#groups < #photos, "Photos should be grouped (not all separate)")
    
    -- Check each group has a best pick
    for _, group in ipairs(groups) do
        assert(group.bestPhoto ~= nil, "Each group should have a best photo")
        assert(#group.photos > 1, "Groups should have multiple photos")
    end
    
    WorkflowTest.teardown()
end

-- Test 3: Landscape HDR workflow
WorkflowTest.tests.test_landscape_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting landscape HDR workflow test...")
    
    -- Create landscape photos with brackets
    local photos = createRealisticPhotoBatch("landscape")
    
    -- Configure for landscape photography
    Config.set("qualityThreshold", 0.8)  -- High quality standard
    Config.set("technicalWeight", 0.6)
    Config.set("aestheticWeight", 0.4)
    
    -- Process with HDR bracket detection
    local brackets = {}
    
    BatchProcessor:processBatch(photos, {
        enableAI = true,
        enableFaceDetection = false,  -- No faces in landscapes
        enableGrouping = true,
        similarityThreshold = 0.95,  -- Very high for HDR brackets
        autoRate = true,
        threshold = 0.8
    }, function(progress)
        if progress.phase == "grouping" then
            -- Detect HDR brackets (3 photos within 5 seconds)
            local currentBracket = {}
            local lastTime = nil
            
            for _, photo in ipairs(photos) do
                local photoTime = photo:getRawMetadata("dateTimeOriginal")
                if lastTime and (photoTime - lastTime) > 5 then
                    if #currentBracket >= 3 then
                        table.insert(brackets, currentBracket)
                    end
                    currentBracket = {}
                end
                table.insert(currentBracket, photo)
                lastTime = photoTime
            end
            
            if #currentBracket >= 3 then
                table.insert(brackets, currentBracket)
            end
        end
        return true
    end)
    
    WorkflowTest.logger:info(string.format(
        "Landscape workflow: Detected %d HDR bracket sets",
        #brackets
    ))
    
    assert(#brackets > 0, "HDR brackets should be detected")
    
    WorkflowTest.teardown()
end

-- Test 4: Error recovery workflow
WorkflowTest.tests.test_error_recovery_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting error recovery workflow test...")
    
    -- Create photos with some problematic ones
    local photos = {}
    for i = 1, 10 do
        photos[i] = {
            localIdentifier = "error-test-" .. i,
            getRawMetadata = function(self, key)
                -- Simulate error on photo 5
                if i == 5 and key == "path" then
                    error("Simulated metadata error")
                end
                
                local metadata = {
                    path = "/test/photo" .. i .. ".jpg",
                    width = 4000,
                    height = 3000,
                    fileFormat = i == 7 and "INVALID" or "JPG",  -- Invalid format on photo 7
                    fileSize = i == 3 and 0 or 5242880,  -- Zero size on photo 3
                    dateTimeOriginal = os.time() + i
                }
                return metadata[key]
            end,
            getDevelopSettings = function() return {} end,
            setRawMetadata = function() return true end
        }
    end
    
    -- Process with error handling
    local errors = {}
    local processed = 0
    
    BatchProcessor:processBatch(photos, {
        enableAI = false,
        enableGrouping = false
    }, function(progress)
        processed = progress.current or processed
        if progress.error then
            table.insert(errors, progress.error)
        end
        return true  -- Continue despite errors
    end)
    
    WorkflowTest.logger:info(string.format(
        "Error recovery: %d processed, %d errors",
        processed, #errors
    ))
    
    -- Should process most photos despite errors
    assert(processed >= 7, "Should process non-error photos")
    assert(#errors <= 3, "Should have limited errors")
    
    -- Check error history
    local errorHistory = ErrorHandler.getErrorHistory()
    assert(#errorHistory > 0, "Errors should be logged")
    
    WorkflowTest.teardown()
end

-- Test 5: Performance stress test
WorkflowTest.tests.test_performance_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting performance stress test...")
    
    -- Create large batch
    local photos = {}
    for i = 1, 100 do
        photos[i] = {
            localIdentifier = "perf-" .. i,
            getRawMetadata = function(self, key)
                local metadata = {
                    path = "/stress/photo" .. i .. ".jpg",
                    width = 6000,
                    height = 4000,
                    fileSize = 15728640,
                    fileFormat = "JPG",
                    dateTimeOriginal = os.time() + i
                }
                return metadata[key]
            end,
            getDevelopSettings = function() return {} end,
            setRawMetadata = function() return true end
        }
    end
    
    -- Measure performance
    local startTime = os.time()
    local processed = 0
    
    BatchProcessor:processBatch(photos, {
        enableAI = false,  -- Disable AI for speed test
        enableFaceDetection = false,
        enableGrouping = false,
        batchSize = 20  -- Process in smaller batches
    }, function(progress)
        processed = progress.current or processed
        return true
    end)
    
    local endTime = os.time()
    local duration = endTime - startTime
    local photosPerSecond = duration > 0 and (#photos / duration) or 0
    
    WorkflowTest.logger:info(string.format(
        "Performance test: %d photos in %d seconds (%.1f photos/sec)",
        #photos, duration, photosPerSecond
    ))
    
    assert(processed == #photos, "All photos should be processed")
    assert(photosPerSecond > 1, "Should process at least 1 photo per second")
    
    WorkflowTest.teardown()
end

-- Test 6: User cancellation workflow
WorkflowTest.tests.test_cancellation_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting cancellation workflow test...")
    
    local photos = createRealisticPhotoBatch("wedding")
    
    -- Process with cancellation
    local cancelAt = 5
    local processedBeforeCancel = 0
    local cancelled = false
    
    BatchProcessor:processBatch(photos, {}, function(progress)
        processedBeforeCancel = progress.current or processedBeforeCancel
        
        -- Simulate user cancellation
        if processedBeforeCancel >= cancelAt then
            cancelled = true
            return false  -- Cancel processing
        end
        return true
    end)
    
    WorkflowTest.logger:info(string.format(
        "Cancellation test: Processed %d before cancel",
        processedBeforeCancel
    ))
    
    assert(cancelled == true, "Processing should be cancelled")
    assert(processedBeforeCancel >= cancelAt, "Should process until cancel point")
    assert(processedBeforeCancel < #photos, "Should not process all photos")
    
    WorkflowTest.teardown()
end

-- Test 7: Settings persistence workflow
WorkflowTest.tests.test_settings_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting settings persistence test...")
    
    -- Save custom settings
    local customSettings = {
        qualityThreshold = 0.85,
        technicalWeight = 0.35,
        aestheticWeight = 0.65,
        batchSize = 25,
        enableAI = true,
        passedLabel = "red"
    }
    
    for key, value in pairs(customSettings) do
        Config.set(key, value)
    end
    
    -- Save configuration
    Config.save()
    
    -- Clear and reload
    Config.load()
    
    -- Verify settings persisted
    for key, expectedValue in pairs(customSettings) do
        local actualValue = Config.get(key)
        assert(actualValue == expectedValue, 
               string.format("Setting %s should be %s, got %s", 
                           key, tostring(expectedValue), tostring(actualValue)))
    end
    
    WorkflowTest.logger:info("Settings persisted successfully")
    
    WorkflowTest.teardown()
end

-- Test 8: Export results workflow
WorkflowTest.tests.test_export_workflow = function()
    WorkflowTest.setup()
    
    WorkflowTest.logger:info("Starting export workflow test...")
    
    local photos = createRealisticPhotoBatch("wedding")
    
    -- Process photos
    BatchProcessor:processBatch(photos, {
        threshold = 0.7
    }, function() return true end)
    
    -- Export results in different formats
    local csvExport = BatchProcessor:exportResults("csv", "/tmp/test_export.csv")
    local jsonExport = BatchProcessor:exportResults("json", "/tmp/test_export.json")
    
    assert(csvExport ~= nil, "CSV export should succeed")
    assert(jsonExport ~= nil, "JSON export should succeed")
    
    WorkflowTest.logger:info("Export formats tested successfully")
    
    WorkflowTest.teardown()
end

return WorkflowTest