--[[
    Module: PhotoScorer
    Description: Core photo scoring logic integrating AI and traditional CV methods
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local Logger = require 'src/utils/Logger'
local Config = require 'src/utils/Config'
local ErrorHandler = require 'src/utils/ErrorHandler'

local logger = Logger:new('PhotoScorer')

-- Module definition
local PhotoScorer = {}
PhotoScorer.VERSION = "1.0.0"

-- Private variables
local _config = nil
local _cache = {}
local _bridgeClient = nil

-- Constants
local DEFAULT_THRESHOLD = 0.7
local MAX_CACHE_SIZE = 100
local BLUR_THRESHOLD = 100

-- Initialize module
function PhotoScorer:initialize(config)
    logger:trace("Initializing PhotoScorer")
    _config = config or Config.load()
    
    -- Initialize bridge client for ONNX inference
    _bridgeClient = require('src/models/ONNXBridge'):new(_config)
    
    return self
end

-- Main scoring function
function PhotoScorer:scorePhoto(photo, options)
    -- Parameter validation
    assert(photo, "Photo is required")
    
    options = options or {}
    local threshold = options.threshold or _config.qualityThreshold or DEFAULT_THRESHOLD
    
    -- Check cache
    local cacheKey = self:_getCacheKey(photo)
    if _cache[cacheKey] and not options.force then
        logger:debug("Returning cached score for photo: " .. cacheKey)
        return _cache[cacheKey]
    end
    
    local timer = logger:startTimer("Photo scoring")
    
    -- Get photo path
    local photoPath = photo:getRawMetadata('path')
    if not photoPath then
        ErrorHandler.handleError(
            ErrorHandler.ErrorCodes.INVALID_INPUT,
            "Photo path not found",
            {photo = photo}
        )
        return nil
    end
    
    -- Perform scoring
    local scores = {}
    
    -- 1. Technical quality checks (fast, local)
    scores.technical = self:_assessTechnicalQuality(photo, photoPath)
    
    -- 2. AI quality assessment (if enabled)
    if _config.useLocalModels then
        scores.ai = self:_assessAIQuality(photoPath)
    end
    
    -- 3. Composition analysis
    scores.composition = self:_analyzeComposition(photo)
    
    -- 4. Face detection (if enabled)
    if _config.enableFaceDetection then
        scores.faces = self:_detectFaces(photoPath)
    end
    
    -- Calculate overall score
    local overallScore = self:_calculateOverallScore(scores, options)
    
    -- Build result
    local result = {
        overall = overallScore,
        technical = scores.technical,
        ai = scores.ai,
        composition = scores.composition,
        faces = scores.faces,
        timestamp = os.time(),
        passed = overallScore >= threshold
    }
    
    -- Update cache
    self:_updateCache(cacheKey, result)
    
    timer:stop()
    
    logger:info("Photo scored", {
        photo = cacheKey,
        score = overallScore,
        passed = result.passed
    })
    
    return result
end

-- Technical quality assessment
function PhotoScorer:_assessTechnicalQuality(photo, photoPath)
    local technical = {
        blur = 0,
        exposure = 0,
        saturation = 0,
        contrast = 0,
        overall = 0
    }
    
    -- Get photo metadata
    local metadata = {
        width = photo:getRawMetadata('width'),
        height = photo:getRawMetadata('height'),
        fileSize = photo:getRawMetadata('fileSize'),
        iso = photo:getRawMetadata('isoSpeedRating'),
        aperture = photo:getRawMetadata('aperture'),
        shutterSpeed = photo:getRawMetadata('shutterSpeed')
    }
    
    -- Check basic validity
    if metadata.width < 100 or metadata.height < 100 then
        technical.overall = 0
        return technical
    end
    
    -- Blur detection (using Node.js bridge)
    local blurResult = _bridgeClient:detectBlur(photoPath)
    if blurResult then
        technical.blur = blurResult.blur_score > BLUR_THRESHOLD and 1 or 0
    end
    
    -- Exposure analysis (using histogram from Lightroom)
    local histogram = photo:getRawMetadata('histogram')
    if histogram then
        technical.exposure = self:_analyzeExposure(histogram)
    end
    
    -- Get develop settings for saturation and contrast
    local developSettings = photo:getDevelopSettings()
    if developSettings then
        technical.saturation = self:_normalizeSaturation(developSettings.Saturation or 0)
        technical.contrast = self:_normalizeContrast(developSettings.Contrast or 0)
    end
    
    -- Calculate overall technical score
    technical.overall = (
        technical.blur * 0.35 +
        technical.exposure * 0.35 +
        technical.saturation * 0.15 +
        technical.contrast * 0.15
    )
    
    return technical
end

-- AI quality assessment using ONNX models
function PhotoScorer:_assessAIQuality(photoPath)
    local aiScores = {
        aesthetic = 0,
        technical = 0,
        overall = 0
    }
    
    -- Call Node.js bridge for AI assessment
    local result = _bridgeClient:assessQuality(photoPath)
    
    if result then
        aiScores.aesthetic = result.aesthetic_score / 10  -- Normalize to 0-1
        aiScores.technical = result.technical_score / 10  -- Normalize to 0-1
        aiScores.overall = result.overall_score / 10      -- Normalize to 0-1
    else
        logger:warn("AI assessment failed, using default scores")
        aiScores.overall = 0.5
    end
    
    return aiScores
end

-- Composition analysis
function PhotoScorer:_analyzeComposition(photo)
    local composition = {
        ruleOfThirds = 0,
        balance = 0,
        leadingLines = 0,
        overall = 0
    }
    
    -- Get photo dimensions
    local width = photo:getRawMetadata('width')
    local height = photo:getRawMetadata('height')
    
    -- Analyze aspect ratio
    local aspectRatio = width / height
    local idealRatios = {1.618, 1.5, 1.333, 1.0} -- Golden ratio, 3:2, 4:3, square
    
    local minDiff = math.huge
    for _, ideal in ipairs(idealRatios) do
        local diff = math.abs(aspectRatio - ideal)
        if diff < minDiff then
            minDiff = diff
        end
    end
    
    composition.balance = 1 - math.min(minDiff, 1)
    
    -- Simple rule of thirds check (would need actual subject detection for accuracy)
    composition.ruleOfThirds = 0.7 -- Default moderate score
    
    -- Leading lines (simplified - would need edge detection)
    composition.leadingLines = 0.6 -- Default moderate score
    
    -- Calculate overall composition score
    composition.overall = (
        composition.ruleOfThirds * 0.4 +
        composition.balance * 0.3 +
        composition.leadingLines * 0.3
    )
    
    return composition
end

-- Face detection
function PhotoScorer:_detectFaces(photoPath)
    local faceData = {
        count = 0,
        quality = 0,
        hasIssues = false
    }
    
    -- Call Node.js bridge for face detection
    local result = _bridgeClient:detectFaces(photoPath)
    
    if result then
        faceData.count = result.face_count
        
        -- Analyze face quality
        if result.faces and #result.faces > 0 then
            local totalQuality = 0
            local issueCount = 0
            
            for _, face in ipairs(result.faces) do
                if face.quality == 'good' then
                    totalQuality = totalQuality + 1
                elseif face.quality == 'medium' then
                    totalQuality = totalQuality + 0.7
                else
                    totalQuality = totalQuality + 0.3
                    issueCount = issueCount + 1
                end
            end
            
            faceData.quality = totalQuality / #result.faces
            faceData.hasIssues = issueCount > 0
        end
    end
    
    return faceData
end

-- Calculate overall score
function PhotoScorer:_calculateOverallScore(scores, options)
    local weights = {
        technical = options.technicalWeight or _config.technicalWeight or 0.4,
        aesthetic = options.aestheticWeight or _config.aestheticWeight or 0.6
    }
    
    -- Ensure weights sum to 1
    local totalWeight = weights.technical + weights.aesthetic
    weights.technical = weights.technical / totalWeight
    weights.aesthetic = weights.aesthetic / totalWeight
    
    local overall = 0
    
    -- Technical component
    if scores.technical then
        overall = overall + (scores.technical.overall * weights.technical)
    end
    
    -- AI/Aesthetic component
    if scores.ai then
        overall = overall + (scores.ai.overall * weights.aesthetic)
    elseif scores.composition then
        -- Fallback to composition if AI not available
        overall = overall + (scores.composition.overall * weights.aesthetic)
    end
    
    -- Apply face detection penalty if issues found
    if scores.faces and scores.faces.hasIssues then
        overall = overall * 0.9 -- 10% penalty for face issues
    end
    
    return math.min(1, math.max(0, overall)) -- Clamp to [0, 1]
end

-- Analyze exposure from histogram
function PhotoScorer:_analyzeExposure(histogram)
    -- Simplified exposure analysis
    -- In production, would analyze the actual histogram data
    
    -- Check for clipping
    local shadows = histogram[1] or 0
    local highlights = histogram[#histogram] or 0
    
    local maxAcceptable = 0.05 -- 5% clipping threshold
    
    local shadowClipping = shadows > maxAcceptable
    local highlightClipping = highlights > maxAcceptable
    
    if shadowClipping and highlightClipping then
        return 0.3 -- Poor exposure
    elseif shadowClipping or highlightClipping then
        return 0.7 -- Moderate exposure issues
    else
        return 1.0 -- Good exposure
    end
end

-- Normalize saturation value
function PhotoScorer:_normalizeSaturation(saturation)
    -- Lightroom saturation range is typically -100 to +100
    -- Optimal range is -20 to +20
    local optimal = 20
    local distance = math.abs(saturation)
    
    if distance <= optimal then
        return 1.0
    elseif distance <= optimal * 2 then
        return 0.7
    else
        return 0.4
    end
end

-- Normalize contrast value
function PhotoScorer:_normalizeContrast(contrast)
    -- Similar to saturation normalization
    local optimal = 25
    local distance = math.abs(contrast)
    
    if distance <= optimal then
        return 1.0
    elseif distance <= optimal * 2 then
        return 0.7
    else
        return 0.4
    end
end

-- Cache management
function PhotoScorer:_getCacheKey(photo)
    local photoId = photo.localIdentifier or photo:getRawMetadata('uuid')
    return tostring(photoId)
end

function PhotoScorer:_updateCache(key, value)
    _cache[key] = value
    
    -- Limit cache size
    local cacheKeys = {}
    for k, _ in pairs(_cache) do
        table.insert(cacheKeys, k)
    end
    
    if #cacheKeys > MAX_CACHE_SIZE then
        -- Remove oldest entries (simple FIFO)
        local toRemove = #cacheKeys - MAX_CACHE_SIZE
        for i = 1, toRemove do
            _cache[cacheKeys[i]] = nil
        end
    end
end

-- Clear cache
function PhotoScorer:clearCache()
    _cache = {}
    logger:info("Photo scorer cache cleared")
end

-- Cleanup
function PhotoScorer:cleanup()
    _cache = {}
    if _bridgeClient then
        _bridgeClient:cleanup()
    end
    logger:trace("PhotoScorer cleaned up")
end

return PhotoScorer