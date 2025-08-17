--[[
    Module: ONNXBridge
    Description: Bridge between Lua plugin and Node.js ONNX Runtime server
    Author: Pickit Development Team
    Created: 2025-01-01
    Last Modified: 2025-01-01
--]]

local LrHttp = import 'LrHttp'
local LrStringUtils = import 'LrStringUtils'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'

local Logger = require 'src/utils/Logger'
local ErrorHandler = require 'src/utils/ErrorHandler'
local Config = require 'src/utils/Config'

local logger = Logger:new('ONNXBridge')

-- Module definition
local ONNXBridge = {}
ONNXBridge.VERSION = "1.0.0"

-- Private variables
local _serverUrl = nil
local _timeout = 30
local _isConnected = false

-- Create new bridge instance
function ONNXBridge:new(config)
    local bridge = {}
    setmetatable(bridge, { __index = self })
    
    -- Initialize configuration
    config = config or Config.load()
    bridge._serverUrl = config.bridgeServerUrl or "http://localhost:3000"
    bridge._timeout = config.bridgeTimeout or 30
    
    -- Check server health on initialization
    bridge:checkHealth()
    
    return bridge
end

-- Check server health
function ONNXBridge:checkHealth()
    local url = self._serverUrl .. "/health"
    
    local result, headers = LrHttp.get(url, nil, self._timeout)
    
    if result then
        local success, health = pcall(function()
            return self:_parseJSON(result)
        end)
        
        if success and health.status == "healthy" then
            self._isConnected = true
            logger:info("ONNX Bridge connected", {
                version = health.version,
                models = health.models
            })
            return true
        end
    end
    
    self._isConnected = false
    logger:warn("ONNX Bridge server not available")
    return false
end

-- Assess image quality using NIMA models
function ONNXBridge:assessQuality(photoPath)
    if not self._isConnected then
        if not self:checkHealth() then
            logger:error("Cannot connect to ONNX Bridge server")
            return nil
        end
    end
    
    local url = self._serverUrl .. "/assess/quality"
    
    -- Read image file
    local imageData = self:_readImageFile(photoPath)
    if not imageData then
        return nil
    end
    
    -- Prepare multipart form data
    local boundary = "----LightroomBoundary" .. os.time()
    local body = self:_createMultipartBody(imageData, "image.jpg", boundary)
    
    local headers = {
        { field = "Content-Type", value = "multipart/form-data; boundary=" .. boundary },
        { field = "Content-Length", value = tostring(#body) }
    }
    
    -- Make HTTP request
    local result, respHeaders = LrHttp.post(url, body, headers, "POST", self._timeout)
    
    if result then
        local success, scores = pcall(function()
            return self:_parseJSON(result)
        end)
        
        if success then
            logger:debug("Quality assessment complete", scores)
            return scores
        else
            logger:error("Failed to parse quality assessment response")
        end
    else
        logger:error("Quality assessment request failed")
    end
    
    return nil
end

-- Detect faces in image
function ONNXBridge:detectFaces(photoPath)
    if not self._isConnected then
        if not self:checkHealth() then
            return nil
        end
    end
    
    local url = self._serverUrl .. "/detect/faces"
    
    -- Read image file
    local imageData = self:_readImageFile(photoPath)
    if not imageData then
        return nil
    end
    
    -- Prepare multipart form data
    local boundary = "----LightroomBoundary" .. os.time()
    local body = self:_createMultipartBody(imageData, "image.jpg", boundary)
    
    local headers = {
        { field = "Content-Type", value = "multipart/form-data; boundary=" .. boundary },
        { field = "Content-Length", value = tostring(#body) }
    }
    
    -- Make HTTP request
    local result, respHeaders = LrHttp.post(url, body, headers, "POST", self._timeout)
    
    if result then
        local success, faces = pcall(function()
            return self:_parseJSON(result)
        end)
        
        if success then
            logger:debug("Face detection complete", {count = faces.face_count})
            return faces
        end
    end
    
    return nil
end

-- Detect blur in image
function ONNXBridge:detectBlur(photoPath)
    if not self._isConnected then
        if not self:checkHealth() then
            return nil
        end
    end
    
    local url = self._serverUrl .. "/detect/blur"
    
    -- Read image file
    local imageData = self:_readImageFile(photoPath)
    if not imageData then
        return nil
    end
    
    -- Prepare multipart form data
    local boundary = "----LightroomBoundary" .. os.time()
    local body = self:_createMultipartBody(imageData, "image.jpg", boundary)
    
    local headers = {
        { field = "Content-Type", value = "multipart/form-data; boundary=" .. boundary },
        { field = "Content-Length", value = tostring(#body) }
    }
    
    -- Make HTTP request
    local result, respHeaders = LrHttp.post(url, body, headers, "POST", self._timeout)
    
    if result then
        local success, blur = pcall(function()
            return self:_parseJSON(result)
        end)
        
        if success then
            logger:debug("Blur detection complete", blur)
            return blur
        end
    end
    
    return nil
end

-- Compare two images for similarity
function ONNXBridge:compareSimilarity(photoPath1, photoPath2)
    if not self._isConnected then
        if not self:checkHealth() then
            return nil
        end
    end
    
    local url = self._serverUrl .. "/compare/similarity"
    
    -- Read both image files
    local imageData1 = self:_readImageFile(photoPath1)
    local imageData2 = self:_readImageFile(photoPath2)
    
    if not imageData1 or not imageData2 then
        return nil
    end
    
    -- Prepare multipart form data with two images
    local boundary = "----LightroomBoundary" .. os.time()
    local body = self:_createMultipartBodyMultiple({
        {data = imageData1, filename = "image1.jpg"},
        {data = imageData2, filename = "image2.jpg"}
    }, boundary)
    
    local headers = {
        { field = "Content-Type", value = "multipart/form-data; boundary=" .. boundary },
        { field = "Content-Length", value = tostring(#body) }
    }
    
    -- Make HTTP request
    local result, respHeaders = LrHttp.post(url, body, headers, "POST", self._timeout * 2)
    
    if result then
        local success, similarity = pcall(function()
            return self:_parseJSON(result)
        end)
        
        if success then
            logger:debug("Similarity comparison complete", similarity)
            return similarity
        end
    end
    
    return nil
end

-- Batch process multiple images
function ONNXBridge:batchProcess(photoPaths, progressCallback)
    if not self._isConnected then
        if not self:checkHealth() then
            return nil
        end
    end
    
    local url = self._serverUrl .. "/batch/process"
    local results = {}
    
    -- Process in chunks to avoid memory issues
    local chunkSize = 10
    local totalPhotos = #photoPaths
    
    for i = 1, totalPhotos, chunkSize do
        local chunkEnd = math.min(i + chunkSize - 1, totalPhotos)
        local chunk = {}
        
        -- Prepare chunk
        for j = i, chunkEnd do
            local imageData = self:_readImageFile(photoPaths[j])
            if imageData then
                table.insert(chunk, {
                    data = imageData,
                    filename = LrPathUtils.leafName(photoPaths[j])
                })
            end
        end
        
        if #chunk > 0 then
            -- Process chunk
            local boundary = "----LightroomBoundary" .. os.time()
            local body = self:_createMultipartBodyMultiple(chunk, boundary)
            
            local headers = {
                { field = "Content-Type", value = "multipart/form-data; boundary=" .. boundary },
                { field = "Content-Length", value = tostring(#body) }
            }
            
            local result, respHeaders = LrHttp.post(url, body, headers, "POST", self._timeout * #chunk)
            
            if result then
                local success, batchResults = pcall(function()
                    return self:_parseJSON(result)
                end)
                
                if success and batchResults.results then
                    for _, r in ipairs(batchResults.results) do
                        table.insert(results, r)
                    end
                end
            end
        end
        
        -- Report progress
        if progressCallback then
            progressCallback(chunkEnd, totalPhotos)
        end
    end
    
    return results
end

-- Load a specific model
function ONNXBridge:loadModel(modelName)
    if not self._isConnected then
        if not self:checkHealth() then
            return false
        end
    end
    
    local url = self._serverUrl .. "/models/load"
    
    local body = self:_toJSON({ modelName = modelName })
    
    local headers = {
        { field = "Content-Type", value = "application/json" },
        { field = "Content-Length", value = tostring(#body) }
    }
    
    local result, respHeaders = LrHttp.post(url, body, headers, "POST", self._timeout)
    
    if result then
        local success, response = pcall(function()
            return self:_parseJSON(result)
        end)
        
        if success and response.success then
            logger:info("Model loaded: " .. modelName)
            return true
        end
    end
    
    logger:error("Failed to load model: " .. modelName)
    return false
end

-- Get available models
function ONNXBridge:getAvailableModels()
    if not self._isConnected then
        if not self:checkHealth() then
            return {}
        end
    end
    
    local url = self._serverUrl .. "/models"
    
    local result, headers = LrHttp.get(url, nil, self._timeout)
    
    if result then
        local success, response = pcall(function()
            return self:_parseJSON(result)
        end)
        
        if success and response.models then
            return response.models
        end
    end
    
    return {}
end

-- Private helper functions

function ONNXBridge:_readImageFile(photoPath)
    -- Check if file exists
    if not LrFileUtils.exists(photoPath) then
        logger:error("Image file not found: " .. photoPath)
        return nil
    end
    
    -- Read file content
    local file = io.open(photoPath, "rb")
    if not file then
        logger:error("Cannot open image file: " .. photoPath)
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    return content
end

function ONNXBridge:_createMultipartBody(imageData, filename, boundary)
    local body = ""
    
    -- Add image part
    body = body .. "--" .. boundary .. "\r\n"
    body = body .. 'Content-Disposition: form-data; name="image"; filename="' .. filename .. '"\r\n'
    body = body .. "Content-Type: image/jpeg\r\n\r\n"
    body = body .. imageData
    body = body .. "\r\n--" .. boundary .. "--\r\n"
    
    return body
end

function ONNXBridge:_createMultipartBodyMultiple(images, boundary)
    local body = ""
    
    for _, image in ipairs(images) do
        body = body .. "--" .. boundary .. "\r\n"
        body = body .. 'Content-Disposition: form-data; name="images"; filename="' .. image.filename .. '"\r\n'
        body = body .. "Content-Type: image/jpeg\r\n\r\n"
        body = body .. image.data
        body = body .. "\r\n"
    end
    
    body = body .. "--" .. boundary .. "--\r\n"
    
    return body
end

function ONNXBridge:_parseJSON(jsonString)
    -- Simple JSON parser for Lua
    -- In production, would use a proper JSON library
    
    -- Remove whitespace
    jsonString = jsonString:gsub("^%s*", ""):gsub("%s*$", "")
    
    -- Try to parse as table
    local func = loadstring("return " .. jsonString)
    if func then
        local success, result = pcall(func)
        if success then
            return result
        end
    end
    
    -- Fallback: basic parsing
    local result = {}
    
    -- Parse key-value pairs
    for key, value in jsonString:gmatch('"([^"]+)"%s*:%s*([^,}]+)') do
        -- Clean up value
        value = value:gsub('^"', ''):gsub('"$', ''):gsub('^%s*', ''):gsub('%s*$', '')
        
        -- Convert to appropriate type
        if value == "true" then
            result[key] = true
        elseif value == "false" then
            result[key] = false
        elseif value == "null" then
            result[key] = nil
        elseif tonumber(value) then
            result[key] = tonumber(value)
        else
            result[key] = value
        end
    end
    
    return result
end

function ONNXBridge:_toJSON(table)
    -- Simple JSON encoder
    local json = "{"
    local first = true
    
    for key, value in pairs(table) do
        if not first then
            json = json .. ","
        end
        first = false
        
        json = json .. '"' .. key .. '":'
        
        if type(value) == "string" then
            json = json .. '"' .. value .. '"'
        elseif type(value) == "number" then
            json = json .. tostring(value)
        elseif type(value) == "boolean" then
            json = json .. tostring(value)
        elseif value == nil then
            json = json .. "null"
        end
    end
    
    json = json .. "}"
    
    return json
end

-- Cleanup
function ONNXBridge:cleanup()
    self._isConnected = false
    logger:info("ONNXBridge cleaned up")
end

return ONNXBridge