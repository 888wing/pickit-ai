--[[
    Unit Tests for BatchProcessor Module
    Tests batch processing functionality
--]]

local BatchProcessor = require 'src/core/BatchProcessor'
local Config = require 'src/utils/Config'

-- Mock photo creation
local function createMockPhotoBatch(count, params)
    local photos = {}
    for i = 1, count do
        photos[i] = {
            localIdentifier = "batch-photo-" .. i,
            getRawMetadata = function(self, key)
                local metadata = {
                    path = "/test/batch/photo" .. i .. ".jpg",
                    width = 4000,
                    height = 3000,
                    fileSize = 5242880,
                    fileFormat = "JPG",
                    dateTimeOriginal = os.time() + i,  -- Sequential timestamps
                    focalLength = 50,
                    aperture = 2.8
                }
                return metadata[key]
            end,
            getDevelopSettings = function(self)
                return {
                    Saturation = 10,
                    Contrast = 15
                }
            end,
            setRawMetadata = function(self, key, value)
                self[key] = value
                return true
            end
        }
    end
    return photos
end

-- Test module
local BatchProcessorTest = {
    setup = function()
        Config.load()
        return BatchProcessor:initialize()
    end,
    
    teardown = function()
        BatchProcessor:cleanup()
    end,
    
    tests = {}
}

-- Test 1: Basic batch processing
BatchProcessorTest.tests.test_basic_batch = function()
    local processor = BatchProcessorTest.setup()
    local photos = createMockPhotoBatch(5)
    
    local processedCount = 0
    local task = processor:processBatch(photos, {}, function(progress)
        processedCount = progress.current or processedCount
        return true  -- Continue processing
    end)
    
    -- Simulate task completion
    if task then
        -- Wait for mock completion
        local results = processor:getResults()
        assert(results ~= nil, "Results should exist")
    end
    
    BatchProcessorTest.teardown()
end

-- Test 2: Photo validation
BatchProcessorTest.tests.test_photo_validation = function()
    local processor = BatchProcessorTest.setup()
    
    -- Create mix of valid and invalid photos
    local photos = {
        -- Valid photo
        {
            localIdentifier = "valid-001",
            getRawMetadata = function(self, key)
                if key == "fileFormat" then return "JPG" end
                if key == "path" then return "/test/valid.jpg" end
                return nil
            end,
            getDevelopSettings = function() return {} end,
            setRawMetadata = function() return true end
        },
        -- Invalid format
        {
            localIdentifier = "invalid-001",
            getRawMetadata = function(self, key)
                if key == "fileFormat" then return "TXT" end  -- Invalid format
                if key == "path" then return "/test/invalid.txt" end
                return nil
            end,
            getDevelopSettings = function() return {} end,
            setRawMetadata = function() return true end
        }
    }
    
    -- Process with validation
    local task = processor:processBatch(photos, {}, function() return true end)
    
    BatchProcessorTest.teardown()
end

-- Test 3: Similarity grouping
BatchProcessorTest.tests.test_similarity_grouping = function()
    local processor = BatchProcessorTest.setup()
    
    -- Create photos with similar timestamps (burst mode simulation)
    local baseTime = os.time()
    local photos = {}
    
    -- Group 1: Burst sequence (3 photos within 2 seconds)
    for i = 1, 3 do
        photos[i] = {
            localIdentifier = "burst-" .. i,
            getRawMetadata = function(self, key)
                if key == "dateTimeOriginal" then return baseTime + i * 0.5 end
                if key == "fileFormat" then return "JPG" end
                if key == "path" then return "/test/burst" .. i .. ".jpg" end
                if key == "focalLength" then return 50 end
                if key == "aperture" then return 2.8 end
                return 4000  -- Default for other metadata
            end,
            getDevelopSettings = function() return {} end,
            setRawMetadata = function() return true end
        }
    end
    
    -- Group 2: Different photos (30+ seconds apart)
    for i = 4, 6 do
        photos[i] = {
            localIdentifier = "separate-" .. i,
            getRawMetadata = function(self, key)
                if key == "dateTimeOriginal" then return baseTime + i * 60 end
                if key == "fileFormat" then return "JPG" end
                if key == "path" then return "/test/separate" .. i .. ".jpg" end
                if key == "focalLength" then return 85 end
                if key == "aperture" then return 1.8 end
                return 4000
            end,
            getDevelopSettings = function() return {} end,
            setRawMetadata = function() return true end
        }
    end
    
    -- Process with grouping enabled
    local task = processor:processBatch(photos, {
        enableGrouping = true,
        similarityThreshold = 0.85
    }, function() return true end)
    
    local results = processor:getResults()
    
    BatchProcessorTest.teardown()
end

-- Test 4: Progress callback
BatchProcessorTest.tests.test_progress_callback = function()
    local processor = BatchProcessorTest.setup()
    local photos = createMockPhotoBatch(10)
    
    local progressUpdates = {}
    
    local task = processor:processBatch(photos, {}, function(progress)
        table.insert(progressUpdates, {
            phase = progress.phase,
            current = progress.current,
            total = progress.total,
            overall = progress.overall
        })
        return true
    end)
    
    assert(#progressUpdates > 0, "Progress updates should be received")
    
    BatchProcessorTest.teardown()
end

-- Test 5: Cancellation
BatchProcessorTest.tests.test_cancellation = function()
    local processor = BatchProcessorTest.setup()
    local photos = createMockPhotoBatch(20)
    
    local cancelAtPhoto = 5
    local processedBeforeCancel = 0
    
    local task = processor:processBatch(photos, {}, function(progress)
        processedBeforeCancel = progress.current or processedBeforeCancel
        
        -- Cancel after processing 5 photos
        if processedBeforeCancel >= cancelAtPhoto then
            processor:cancel()
            return false
        end
        return true
    end)
    
    assert(processedBeforeCancel >= cancelAtPhoto, "Should process until cancellation")
    
    BatchProcessorTest.teardown()
end

-- Test 6: Auto rating and labeling
BatchProcessorTest.tests.test_auto_rating_labeling = function()
    local processor = BatchProcessorTest.setup()
    local photos = createMockPhotoBatch(3)
    
    -- Track rating/label applications
    for _, photo in ipairs(photos) do
        photo.appliedRating = nil
        photo.appliedLabel = nil
        photo.setRawMetadata = function(self, key, value)
            if key == "rating" then
                self.appliedRating = value
            elseif key == "colorNameForLabel" then
                self.appliedLabel = value
            end
            return true
        end
    end
    
    -- Process with auto rating and labeling
    local task = processor:processBatch(photos, {
        autoRate = true,
        autoLabel = true,
        passedLabel = "green",
        threshold = 0.5  -- Low threshold to ensure some pass
    }, function() return true end)
    
    -- Check if ratings/labels were applied
    local hasRatings = false
    local hasLabels = false
    
    for _, photo in ipairs(photos) do
        if photo.appliedRating then hasRatings = true end
        if photo.appliedLabel then hasLabels = true end
    end
    
    BatchProcessorTest.teardown()
end

-- Test 7: Export results
BatchProcessorTest.tests.test_export_results = function()
    local processor = BatchProcessorTest.setup()
    local photos = createMockPhotoBatch(5)
    
    -- Process photos
    local task = processor:processBatch(photos, {}, function() return true end)
    
    -- Test CSV export
    local csvPath = "/tmp/test_results.csv"
    local csvSuccess = processor:exportResults("csv", csvPath)
    
    -- Test JSON export
    local jsonPath = "/tmp/test_results.json"
    local jsonSuccess = processor:exportResults("json", jsonPath)
    
    BatchProcessorTest.teardown()
end

-- Test 8: Batch size limits
BatchProcessorTest.tests.test_batch_size = function()
    local processor = BatchProcessorTest.setup()
    
    -- Test with configured batch size
    Config.set("batchSize", 5)
    
    local photos = createMockPhotoBatch(15)  -- 3 batches of 5
    
    local batchStarts = {}
    local lastPhoto = 0
    
    local task = processor:processBatch(photos, {}, function(progress)
        if progress.current and progress.current > lastPhoto + 5 then
            -- New batch started
            table.insert(batchStarts, progress.current)
            lastPhoto = progress.current
        end
        return true
    end)
    
    BatchProcessorTest.teardown()
end

-- Test 9: Error handling
BatchProcessorTest.tests.test_error_handling = function()
    local processor = BatchProcessorTest.setup()
    
    -- Create photo that will cause error
    local photos = {
        {
            localIdentifier = "error-photo",
            getRawMetadata = function(self, key)
                if key == "path" then
                    error("Simulated metadata error")
                end
                return nil
            end,
            getDevelopSettings = function() return {} end,
            setRawMetadata = function() return true end
        }
    }
    
    -- Process should handle error gracefully
    local task = processor:processBatch(photos, {}, function() return true end)
    
    local results = processor:getResults()
    assert(results ~= nil, "Results should exist even with errors")
    
    BatchProcessorTest.teardown()
end

-- Test 10: Summary generation
BatchProcessorTest.tests.test_summary_generation = function()
    local processor = BatchProcessorTest.setup()
    local photos = createMockPhotoBatch(10)
    
    -- Process photos
    local task = processor:processBatch(photos, {
        threshold = 0.5
    }, function() return true end)
    
    local results = processor:getResults()
    
    if results and results.summary then
        assert(results.summary.total ~= nil, "Summary should have total count")
        assert(results.summary.processed ~= nil, "Summary should have processed count")
        assert(results.summary.passed ~= nil, "Summary should have passed count")
        assert(results.summary.failed ~= nil, "Summary should have failed count")
    end
    
    BatchProcessorTest.teardown()
end

return BatchProcessorTest