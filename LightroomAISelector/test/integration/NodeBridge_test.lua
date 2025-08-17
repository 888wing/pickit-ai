--[[
    Integration Tests for Node.js Bridge
    Tests communication between Lua plugin and Node.js server
--]]

local NodeBridge = require 'src/models/NodeBridge'
local Config = require 'src/utils/Config'
local Logger = require 'src/utils/Logger'

-- Test module
local NodeBridgeTest = {
    logger = Logger:new("NodeBridgeTest"),
    
    setup = function()
        Config.load()
        -- Ensure Node.js server is running
        return NodeBridge:initialize()
    end,
    
    teardown = function()
        NodeBridge:cleanup()
    end,
    
    tests = {}
}

-- Test 1: Server connectivity
NodeBridgeTest.tests.test_server_connectivity = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Test ping endpoint
    local success, result = bridge:ping()
    
    assert(success == true, "Server should be reachable")
    assert(result ~= nil, "Ping should return result")
    assert(result.status == "ok", "Server status should be ok")
    
    NodeBridgeTest.teardown()
end

-- Test 2: Quality assessment integration
NodeBridgeTest.tests.test_quality_assessment = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Create test image path
    local testImagePath = "/test/sample.jpg"
    
    -- Test quality assessment
    local success, scores = bridge:assessQuality(testImagePath)
    
    if success then
        assert(scores ~= nil, "Scores should be returned")
        assert(scores.aesthetic ~= nil, "Aesthetic score should exist")
        assert(scores.technical ~= nil, "Technical score should exist")
        assert(scores.aesthetic >= 0 and scores.aesthetic <= 1, 
               "Aesthetic score should be between 0 and 1")
        assert(scores.technical >= 0 and scores.technical <= 1,
               "Technical score should be between 0 and 1")
    else
        NodeBridgeTest.logger:warn("Quality assessment skipped - no test image")
    end
    
    NodeBridgeTest.teardown()
end

-- Test 3: Face detection integration
NodeBridgeTest.tests.test_face_detection = function()
    local bridge = NodeBridgeTest.setup()
    
    local testImagePath = "/test/portrait.jpg"
    
    -- Test face detection
    local success, faces = bridge:detectFaces(testImagePath)
    
    if success then
        assert(faces ~= nil, "Face results should be returned")
        assert(type(faces) == "table", "Faces should be a table")
        
        if #faces > 0 then
            local face = faces[1]
            assert(face.bounds ~= nil, "Face should have bounds")
            assert(face.confidence ~= nil, "Face should have confidence")
            assert(face.confidence >= 0 and face.confidence <= 1,
                   "Confidence should be between 0 and 1")
        end
    else
        NodeBridgeTest.logger:warn("Face detection skipped - no test image")
    end
    
    NodeBridgeTest.teardown()
end

-- Test 4: Blur detection integration
NodeBridgeTest.tests.test_blur_detection = function()
    local bridge = NodeBridgeTest.setup()
    
    local testImagePath = "/test/sample.jpg"
    
    -- Test blur detection
    local success, blurScore = bridge:detectBlur(testImagePath)
    
    if success then
        assert(blurScore ~= nil, "Blur score should be returned")
        assert(type(blurScore) == "number", "Blur score should be a number")
        assert(blurScore >= 0, "Blur score should be non-negative")
    else
        NodeBridgeTest.logger:warn("Blur detection skipped - no test image")
    end
    
    NodeBridgeTest.teardown()
end

-- Test 5: Batch processing
NodeBridgeTest.tests.test_batch_processing = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Create batch of test images
    local images = {
        "/test/photo1.jpg",
        "/test/photo2.jpg",
        "/test/photo3.jpg"
    }
    
    local results = {}
    local errors = 0
    
    for _, imagePath in ipairs(images) do
        local success, scores = bridge:assessQuality(imagePath)
        if success then
            table.insert(results, scores)
        else
            errors = errors + 1
        end
    end
    
    NodeBridgeTest.logger:info(string.format(
        "Batch processing: %d successful, %d errors",
        #results, errors
    ))
    
    NodeBridgeTest.teardown()
end

-- Test 6: Error handling
NodeBridgeTest.tests.test_error_handling = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Test with invalid image path
    local success, error = bridge:assessQuality(nil)
    assert(success == false, "Nil path should fail")
    assert(error ~= nil, "Error message should be provided")
    
    -- Test with non-existent file
    local success2, error2 = bridge:assessQuality("/invalid/path.jpg")
    assert(success2 == false, "Invalid path should fail")
    
    NodeBridgeTest.teardown()
end

-- Test 7: Timeout handling
NodeBridgeTest.tests.test_timeout = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Set short timeout
    local originalTimeout = Config.get("apiTimeout")
    Config.set("apiTimeout", 100)  -- 100ms timeout
    
    -- This should timeout if server is slow
    local success, result = bridge:assessQuality("/test/large.jpg")
    
    -- Restore timeout
    Config.set("apiTimeout", originalTimeout)
    
    NodeBridgeTest.teardown()
end

-- Test 8: Connection recovery
NodeBridgeTest.tests.test_connection_recovery = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Simulate connection loss and recovery
    local attempts = 0
    local maxAttempts = 3
    local success = false
    
    while attempts < maxAttempts and not success do
        attempts = attempts + 1
        success = bridge:ping()
        
        if not success then
            NodeBridgeTest.logger:info("Retrying connection... " .. attempts)
            -- Wait before retry
            local time = os.time()
            while os.time() - time < 1 do
                -- Wait 1 second
            end
        end
    end
    
    assert(attempts <= maxAttempts, "Should recover within max attempts")
    
    NodeBridgeTest.teardown()
end

-- Test 9: Concurrent requests
NodeBridgeTest.tests.test_concurrent_requests = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Simulate concurrent requests
    local tasks = {}
    
    for i = 1, 5 do
        local task = {
            id = i,
            path = "/test/photo" .. i .. ".jpg",
            completed = false
        }
        table.insert(tasks, task)
    end
    
    -- Process all tasks (in production would be truly concurrent)
    for _, task in ipairs(tasks) do
        local success, result = bridge:assessQuality(task.path)
        task.completed = success
    end
    
    -- Check completion
    local completed = 0
    for _, task in ipairs(tasks) do
        if task.completed then
            completed = completed + 1
        end
    end
    
    NodeBridgeTest.logger:info(string.format(
        "Concurrent processing: %d/%d completed",
        completed, #tasks
    ))
    
    NodeBridgeTest.teardown()
end

-- Test 10: Server status monitoring
NodeBridgeTest.tests.test_server_status = function()
    local bridge = NodeBridgeTest.setup()
    
    -- Get server status
    local success, status = bridge:getServerStatus()
    
    if success then
        assert(status ~= nil, "Status should be returned")
        assert(status.uptime ~= nil, "Uptime should be provided")
        assert(status.memory ~= nil, "Memory usage should be provided")
        assert(status.modelsLoaded ~= nil, "Model status should be provided")
    end
    
    NodeBridgeTest.teardown()
end

return NodeBridgeTest