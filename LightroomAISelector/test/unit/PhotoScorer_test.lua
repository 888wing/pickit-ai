--[[
    Unit Tests for PhotoScorer Module
    Tests core scoring functionality
--]]

local PhotoScorer = require 'src/core/PhotoScorer'
local Config = require 'src/utils/Config'

-- Mock photo object
local function createMockPhoto(params)
    params = params or {}
    return {
        localIdentifier = params.id or "test-photo-001",
        getRawMetadata = function(self, key)
            local metadata = {
                path = params.path or "/test/photo.jpg",
                width = params.width or 4000,
                height = params.height or 3000,
                fileSize = params.fileSize or 5242880,
                isoSpeedRating = params.iso or 200,
                aperture = params.aperture or 2.8,
                shutterSpeed = params.shutter or 1/250,
                fileFormat = params.format or "JPG",
                dateTimeOriginal = params.timestamp or os.time(),
                focalLength = params.focalLength or 50,
                histogram = params.histogram or {0.1, 0.2, 0.3, 0.2, 0.1, 0.1}
            }
            return metadata[key]
        end,
        getDevelopSettings = function(self)
            return {
                Saturation = params.saturation or 10,
                Contrast = params.contrast or 15
            }
        end,
        setRawMetadata = function(self, key, value)
            -- Mock implementation
            return true
        end
    }
end

-- Test module
local PhotoScorerTest = {
    setup = function()
        -- Initialize configuration
        Config.load()
        
        -- Initialize PhotoScorer
        return PhotoScorer:initialize()
    end,
    
    teardown = function()
        PhotoScorer:cleanup()
    end,
    
    tests = {}
}

-- Test 1: Basic scoring functionality
PhotoScorerTest.tests.test_basic_scoring = function()
    local scorer = PhotoScorerTest.setup()
    local photo = createMockPhoto()
    
    local result = scorer:scorePhoto(photo)
    
    assert(result ~= nil, "Score result should not be nil")
    assert(result.overall ~= nil, "Overall score should exist")
    assert(result.overall >= 0 and result.overall <= 1, "Score should be between 0 and 1")
    assert(result.technical ~= nil, "Technical score should exist")
    
    PhotoScorerTest.teardown()
end

-- Test 2: Cache functionality
PhotoScorerTest.tests.test_cache = function()
    local scorer = PhotoScorerTest.setup()
    local photo = createMockPhoto({id = "cache-test-001"})
    
    -- First call - should calculate
    local result1 = scorer:scorePhoto(photo)
    
    -- Second call - should use cache
    local result2 = scorer:scorePhoto(photo)
    
    assert(result1.overall == result2.overall, "Cached score should match")
    assert(result1.timestamp ~= nil, "Timestamp should exist")
    
    -- Force recalculation
    local result3 = scorer:scorePhoto(photo, {force = true})
    assert(result3 ~= nil, "Force recalculation should work")
    
    PhotoScorerTest.teardown()
end

-- Test 3: Blur detection
PhotoScorerTest.tests.test_blur_detection = function()
    local scorer = PhotoScorerTest.setup()
    
    -- Clear photo
    local clearPhoto = createMockPhoto({id = "clear-001"})
    local clearResult = scorer:scorePhoto(clearPhoto)
    
    -- Blurry photo simulation
    local blurryPhoto = createMockPhoto({id = "blurry-001"})
    local blurryResult = scorer:scorePhoto(blurryPhoto)
    
    assert(clearResult.technical ~= nil, "Technical score should exist")
    assert(blurryResult.technical ~= nil, "Technical score should exist for blurry")
    
    PhotoScorerTest.teardown()
end

-- Test 4: Exposure analysis
PhotoScorerTest.tests.test_exposure_analysis = function()
    local scorer = PhotoScorerTest.setup()
    
    -- Good exposure
    local goodPhoto = createMockPhoto({
        histogram = {0.05, 0.15, 0.3, 0.3, 0.15, 0.05}
    })
    local goodResult = scorer:scorePhoto(goodPhoto)
    
    -- Overexposed
    local overPhoto = createMockPhoto({
        histogram = {0, 0, 0.1, 0.2, 0.3, 0.4}
    })
    local overResult = scorer:scorePhoto(overPhoto)
    
    -- Underexposed
    local underPhoto = createMockPhoto({
        histogram = {0.4, 0.3, 0.2, 0.1, 0, 0}
    })
    local underResult = scorer:scorePhoto(underPhoto)
    
    assert(goodResult.technical.exposure ~= nil, "Exposure score should exist")
    assert(overResult.technical.exposure ~= nil, "Overexposed score should exist")
    assert(underResult.technical.exposure ~= nil, "Underexposed score should exist")
    
    -- Good exposure should score higher
    assert(goodResult.technical.exposure > overResult.technical.exposure, 
           "Good exposure should score higher than overexposed")
    assert(goodResult.technical.exposure > underResult.technical.exposure,
           "Good exposure should score higher than underexposed")
    
    PhotoScorerTest.teardown()
end

-- Test 5: Composition analysis
PhotoScorerTest.tests.test_composition_analysis = function()
    local scorer = PhotoScorerTest.setup()
    
    -- Golden ratio aspect
    local goldenPhoto = createMockPhoto({
        width = 1618,
        height = 1000
    })
    local goldenResult = scorer:scorePhoto(goldenPhoto)
    
    -- Standard 3:2 aspect
    local standardPhoto = createMockPhoto({
        width = 3000,
        height = 2000
    })
    local standardResult = scorer:scorePhoto(standardPhoto)
    
    -- Unusual aspect ratio
    local unusualPhoto = createMockPhoto({
        width = 1000,
        height = 3000
    })
    local unusualResult = scorer:scorePhoto(unusualPhoto)
    
    assert(goldenResult.composition ~= nil, "Composition score should exist")
    assert(standardResult.composition ~= nil, "Standard composition should exist")
    assert(unusualResult.composition ~= nil, "Unusual composition should exist")
    
    PhotoScorerTest.teardown()
end

-- Test 6: Weight calculations
PhotoScorerTest.tests.test_weight_calculations = function()
    local scorer = PhotoScorerTest.setup()
    local photo = createMockPhoto()
    
    -- Test with different weights
    local result1 = scorer:scorePhoto(photo, {
        technicalWeight = 0.8,
        aestheticWeight = 0.2
    })
    
    local result2 = scorer:scorePhoto(photo, {
        technicalWeight = 0.2,
        aestheticWeight = 0.8
    })
    
    assert(result1.overall ~= nil, "Score with custom weights should work")
    assert(result2.overall ~= nil, "Score with inverted weights should work")
    
    PhotoScorerTest.teardown()
end

-- Test 7: Invalid photo handling
PhotoScorerTest.tests.test_invalid_photo = function()
    local scorer = PhotoScorerTest.setup()
    
    -- Nil photo
    local success, error = pcall(function()
        scorer:scorePhoto(nil)
    end)
    assert(not success, "Nil photo should throw error")
    
    -- Photo with missing metadata
    local invalidPhoto = createMockPhoto({
        width = 50,  -- Too small
        height = 50
    })
    local result = scorer:scorePhoto(invalidPhoto)
    assert(result ~= nil, "Should handle small photos")
    assert(result.technical.overall == 0, "Invalid photo should score 0")
    
    PhotoScorerTest.teardown()
end

-- Test 8: Threshold testing
PhotoScorerTest.tests.test_threshold = function()
    local scorer = PhotoScorerTest.setup()
    local photo = createMockPhoto()
    
    -- Test with low threshold
    local lowResult = scorer:scorePhoto(photo, {threshold = 0.3})
    
    -- Test with high threshold
    local highResult = scorer:scorePhoto(photo, {threshold = 0.9})
    
    assert(lowResult.passed ~= nil, "Pass/fail should be determined")
    assert(highResult.passed ~= nil, "Pass/fail should be determined with high threshold")
    
    PhotoScorerTest.teardown()
end

return PhotoScorerTest