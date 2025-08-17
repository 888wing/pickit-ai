--[[
    Module: BatchProcessor
    Description: Handles batch processing of photos with queue management
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local LrTasks = import 'LrTasks'
local LrProgressScope = import 'LrProgressScope'
local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'

local Logger = require 'src/utils/Logger'
local Config = require 'src/utils/Config'
local ErrorHandler = require 'src/utils/ErrorHandler'
local PhotoScorer = require 'src/core/PhotoScorer'

local logger = Logger:new('BatchProcessor')

-- Module definition
local BatchProcessor = {}
BatchProcessor.VERSION = "1.0.0"

-- Private variables
local _config = nil
local _photoScorer = nil
local _currentTask = nil
local _isCancelled = false
local _processedCount = 0
local _results = {}

-- Processing states
local ProcessingState = {
    IDLE = "idle",
    PREPARING = "preparing",
    PROCESSING = "processing",
    GROUPING = "grouping",
    FINALIZING = "finalizing",
    COMPLETED = "completed",
    CANCELLED = "cancelled",
    ERROR = "error"
}

-- Initialize module
function BatchProcessor:initialize(config)
    logger:trace("Initializing BatchProcessor")
    _config = config or Config.load()
    
    -- Initialize photo scorer
    _photoScorer = PhotoScorer:initialize(_config)
    
    return self
end

-- Process batch of photos
function BatchProcessor:processBatch(photos, options, progressCallback)
    if _currentTask then
        logger:warn("Batch processing already in progress")
        return nil
    end
    
    options = options or {}
    _isCancelled = false
    _processedCount = 0
    _results = {}
    
    local totalPhotos = #photos
    logger:info("Starting batch processing", {count = totalPhotos})
    
    -- Create async task
    _currentTask = LrTasks.startAsyncTask(function()
        local progressScope = LrProgressScope({
            title = "AI智能選片處理中",
            caption = "準備處理...",
            functionContext = context
        })
        
        progressScope:setCancelable(true)
        
        -- Processing phases
        local phases = {
            {name = "preparing", weight = 0.1, handler = self._preparePhotos},
            {name = "processing", weight = 0.6, handler = self._processPhotos},
            {name = "grouping", weight = 0.2, handler = self._groupSimilarPhotos},
            {name = "finalizing", weight = 0.1, handler = self._finalizeResults}
        }
        
        local success = true
        local currentPhase = 1
        local phaseStartProgress = 0
        
        for _, phase in ipairs(phases) do
            if progressScope:isCanceled() or _isCancelled then
                _isCancelled = true
                break
            end
            
            logger:info("Starting phase: " .. phase.name)
            
            -- Execute phase
            local phaseSuccess = phase.handler(self, photos, options, function(current, total, message)
                -- Calculate overall progress
                local phaseProgress = current / total
                local overallProgress = phaseStartProgress + (phaseProgress * phase.weight)
                
                progressScope:setPortionComplete(overallProgress, 1)
                progressScope:setCaption(message or string.format("處理中 %d/%d", current, total))
                
                -- Call external progress callback if provided
                if progressCallback then
                    progressCallback({
                        phase = phase.name,
                        current = current,
                        total = total,
                        overall = overallProgress,
                        message = message
                    })
                end
                
                return not progressScope:isCanceled()
            end)
            
            if not phaseSuccess then
                success = false
                break
            end
            
            phaseStartProgress = phaseStartProgress + phase.weight
        end
        
        progressScope:done()
        
        -- Clean up
        _currentTask = nil
        
        if _isCancelled then
            logger:info("Batch processing cancelled")
            return nil
        elseif success then
            logger:info("Batch processing completed", {
                processed = _processedCount,
                passed = self:_countPassed()
            })
            return _results
        else
            logger:error("Batch processing failed")
            return nil
        end
    end)
    
    return _currentTask
end

-- Cancel current processing
function BatchProcessor:cancel()
    _isCancelled = true
    logger:info("Batch processing cancel requested")
end

-- Get current results
function BatchProcessor:getResults()
    return _results
end

-- Private methods

-- Phase 1: Prepare photos
function BatchProcessor:_preparePhotos(photos, options, progressCallback)
    local total = #photos
    
    for i, photo in ipairs(photos) do
        if not progressCallback(i, total, "準備照片 " .. i .. "/" .. total) then
            return false
        end
        
        -- Validate photo
        local isValid = self:_validatePhoto(photo)
        if not isValid then
            logger:warn("Invalid photo skipped", {index = i})
            _results[photo] = {
                valid = false,
                error = "Invalid photo format or metadata"
            }
        end
    end
    
    return true
end

-- Phase 2: Process photos
function BatchProcessor:_processPhotos(photos, options, progressCallback)
    local total = #photos
    local batchSize = _config.batchSize or 20
    local batches = {}
    
    -- Split into batches
    for i = 1, total, batchSize do
        local batchEnd = math.min(i + batchSize - 1, total)
        local batch = {}
        
        for j = i, batchEnd do
            table.insert(batch, photos[j])
        end
        
        table.insert(batches, batch)
    end
    
    -- Process each batch
    local currentPhoto = 0
    
    for batchIndex, batch in ipairs(batches) do
        for _, photo in ipairs(batch) do
            currentPhoto = currentPhoto + 1
            
            if not progressCallback(currentPhoto, total, "評分中 " .. currentPhoto .. "/" .. total) then
                return false
            end
            
            -- Skip if already marked invalid
            if _results[photo] and not _results[photo].valid then
                -- Skip invalid photos
            else
                -- Score photo
                local timer = logger:startTimer("Score photo")
                local score = _photoScorer:scorePhoto(photo, options)
                timer:stop()
                
                if score then
                    _results[photo] = {
                        valid = true,
                        score = score,
                        timestamp = os.time()
                    }
                    _processedCount = _processedCount + 1
                    
                    -- Apply rating if passed threshold
                    if score.passed and options.autoRate then
                        self:_applyRating(photo, score.overall)
                    end
                    
                    -- Apply color label if configured
                    if score.passed and options.autoLabel then
                        self:_applyColorLabel(photo, options.passedLabel or "green")
                    end
                else
                    _results[photo] = {
                        valid = false,
                        error = "Scoring failed"
                    }
                end
            end
        end
        
        -- Small delay between batches to prevent overload
        LrTasks.sleep(0.1)
    end
    
    return true
end

-- Phase 3: Group similar photos
function BatchProcessor:_groupSimilarPhotos(photos, options, progressCallback)
    if not options.enableGrouping then
        return true
    end
    
    local total = #photos
    local groups = {}
    local processed = {}
    
    for i, photo1 in ipairs(photos) do
        if not progressCallback(i, total, "分組相似照片 " .. i .. "/" .. total) then
            return false
        end
        
        if not processed[photo1] and _results[photo1] and _results[photo1].valid then
            local group = {photo1}
            processed[photo1] = true
            
            -- Find similar photos
            for j = i + 1, total do
                local photo2 = photos[j]
                
                if not processed[photo2] and _results[photo2] and _results[photo2].valid then
                    local similarity = self:_calculateSimilarity(photo1, photo2)
                    
                    if similarity > (_config.similarityThreshold or 0.85) then
                        table.insert(group, photo2)
                        processed[photo2] = true
                    end
                end
            end
            
            if #group > 1 then
                table.insert(groups, group)
                self:_markGroupBest(group)
            end
        end
    end
    
    -- Store groups in results
    for _, group in ipairs(groups) do
        for _, photo in ipairs(group) do
            if _results[photo] then
                _results[photo].group = group
            end
        end
    end
    
    logger:info("Photo grouping complete", {groups = #groups})
    
    return true
end

-- Phase 4: Finalize results
function BatchProcessor:_finalizeResults(photos, options, progressCallback)
    local total = #photos
    local passed = 0
    local failed = 0
    local grouped = 0
    
    for i, photo in ipairs(photos) do
        if not progressCallback(i, total, "完成處理 " .. i .. "/" .. total) then
            return false
        end
        
        local result = _results[photo]
        if result then
            if result.valid and result.score and result.score.passed then
                passed = passed + 1
            else
                failed = failed + 1
            end
            
            if result.group then
                grouped = grouped + 1
            end
        end
    end
    
    -- Generate summary
    local summary = {
        total = total,
        processed = _processedCount,
        passed = passed,
        failed = failed,
        grouped = grouped,
        processingTime = os.time()
    }
    
    _results.summary = summary
    
    logger:info("Batch processing finalized", summary)
    
    -- Show completion dialog if configured
    if options.showSummary then
        self:_showSummaryDialog(summary)
    end
    
    return true
end

-- Helper methods

function BatchProcessor:_validatePhoto(photo)
    if not photo then
        return false
    end
    
    local fileFormat = photo:getRawMetadata('fileFormat')
    local supportedFormats = {
        "JPG", "JPEG", "PNG", "TIFF", "DNG", "RAF", "NEF", "CR2", "CR3", "ARW"
    }
    
    local isSupported = false
    for _, format in ipairs(supportedFormats) do
        if fileFormat == format then
            isSupported = true
            break
        end
    end
    
    return isSupported
end

function BatchProcessor:_calculateSimilarity(photo1, photo2)
    -- Simple similarity based on capture time and metadata
    local time1 = photo1:getRawMetadata('dateTimeOriginal')
    local time2 = photo2:getRawMetadata('dateTimeOriginal')
    
    if time1 and time2 then
        local timeDiff = math.abs(time1 - time2)
        
        -- If photos taken within 5 seconds, likely similar
        if timeDiff < 5 then
            return 0.9
        elseif timeDiff < 30 then
            return 0.7
        end
    end
    
    -- Check focal length and aperture
    local focal1 = photo1:getRawMetadata('focalLength')
    local focal2 = photo2:getRawMetadata('focalLength')
    local aperture1 = photo1:getRawMetadata('aperture')
    local aperture2 = photo2:getRawMetadata('aperture')
    
    if focal1 == focal2 and aperture1 == aperture2 then
        return 0.6
    end
    
    return 0.3
end

function BatchProcessor:_markGroupBest(group)
    -- Find best photo in group based on scores
    local bestPhoto = nil
    local bestScore = 0
    
    for _, photo in ipairs(group) do
        local result = _results[photo]
        if result and result.score and result.score.overall then
            if result.score.overall > bestScore then
                bestScore = result.score.overall
                bestPhoto = photo
            end
        end
    end
    
    if bestPhoto then
        _results[bestPhoto].isGroupBest = true
    end
end

function BatchProcessor:_applyRating(photo, score)
    -- Convert score (0-1) to rating (0-5)
    local rating = math.floor(score * 5)
    
    photo:setRawMetadata('rating', rating)
    
    logger:debug("Applied rating", {photo = photo.localIdentifier, rating = rating})
end

function BatchProcessor:_applyColorLabel(photo, color)
    local colorMap = {
        red = "red",
        yellow = "yellow",
        green = "green",
        blue = "blue",
        purple = "purple"
    }
    
    local label = colorMap[color] or "green"
    photo:setRawMetadata('colorNameForLabel', label)
    
    logger:debug("Applied color label", {photo = photo.localIdentifier, label = label})
end

function BatchProcessor:_countPassed()
    local count = 0
    for photo, result in pairs(_results) do
        if photo ~= "summary" and result.valid and result.score and result.score.passed then
            count = count + 1
        end
    end
    return count
end

function BatchProcessor:_showSummaryDialog(summary)
    local message = string.format(
        "處理完成！\n\n" ..
        "總計: %d 張照片\n" ..
        "通過: %d 張\n" ..
        "失敗: %d 張\n" ..
        "分組: %d 張",
        summary.total,
        summary.passed,
        summary.failed,
        summary.grouped
    )
    
    LrDialogs.message("AI選片完成", message)
end

-- Export results
function BatchProcessor:exportResults(format, filepath)
    format = format or "csv"
    
    if format == "csv" then
        return self:_exportCSV(filepath)
    elseif format == "json" then
        return self:_exportJSON(filepath)
    else
        logger:error("Unsupported export format: " .. format)
        return false
    end
end

function BatchProcessor:_exportCSV(filepath)
    local file = io.open(filepath, "w")
    if not file then
        return false
    end
    
    -- Write header
    file:write("Photo,Overall Score,Technical,Aesthetic,Passed,Group\n")
    
    -- Write data
    for photo, result in pairs(_results) do
        if photo ~= "summary" and result.valid and result.score then
            local row = string.format(
                "%s,%.2f,%.2f,%.2f,%s,%s\n",
                photo.localIdentifier or "unknown",
                result.score.overall or 0,
                result.score.technical and result.score.technical.overall or 0,
                result.score.ai and result.score.ai.overall or 0,
                result.score.passed and "Yes" or "No",
                result.group and "Yes" or "No"
            )
            file:write(row)
        end
    end
    
    file:close()
    return true
end

function BatchProcessor:_exportJSON(filepath)
    -- Convert results to JSON-compatible format
    local exportData = {
        summary = _results.summary,
        photos = {}
    }
    
    for photo, result in pairs(_results) do
        if photo ~= "summary" and result.valid then
            table.insert(exportData.photos, {
                id = photo.localIdentifier,
                scores = result.score,
                timestamp = result.timestamp
            })
        end
    end
    
    -- Simple JSON encoding
    local json = "{\n"
    json = json .. '  "summary": ' .. self:_tableToJSON(_results.summary) .. ",\n"
    json = json .. '  "photos": [\n'
    
    for i, photo in ipairs(exportData.photos) do
        json = json .. "    " .. self:_tableToJSON(photo)
        if i < #exportData.photos then
            json = json .. ","
        end
        json = json .. "\n"
    end
    
    json = json .. "  ]\n}"
    
    local file = io.open(filepath, "w")
    if not file then
        return false
    end
    
    file:write(json)
    file:close()
    
    return true
end

function BatchProcessor:_tableToJSON(t)
    -- Simple table to JSON converter
    local json = "{"
    local first = true
    
    for k, v in pairs(t) do
        if not first then
            json = json .. ", "
        end
        first = false
        
        json = json .. '"' .. tostring(k) .. '": '
        
        if type(v) == "table" then
            json = json .. self:_tableToJSON(v)
        elseif type(v) == "string" then
            json = json .. '"' .. v .. '"'
        elseif type(v) == "boolean" then
            json = json .. tostring(v)
        else
            json = json .. tostring(v or "null")
        end
    end
    
    json = json .. "}"
    return json
end

-- Cleanup
function BatchProcessor:cleanup()
    if _currentTask then
        _isCancelled = true
        LrTasks.sleep(1)
    end
    
    _results = {}
    _processedCount = 0
    
    if _photoScorer then
        _photoScorer:cleanup()
    end
    
    logger:trace("BatchProcessor cleaned up")
end

return BatchProcessor