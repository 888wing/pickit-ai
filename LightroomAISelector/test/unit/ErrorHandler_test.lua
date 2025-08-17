--[[
    Unit Tests for ErrorHandler Module
    Tests error handling and recovery mechanisms
--]]

local ErrorHandler = require 'src/utils/ErrorHandler'
local Logger = require 'src/utils/Logger'

-- Test module
local ErrorHandlerTest = {
    setup = function()
        -- Clear error history before each test
        ErrorHandler.clearHistory()
    end,
    
    teardown = function()
        ErrorHandler.cleanup()
    end,
    
    tests = {}
}

-- Test 1: Basic error handling
ErrorHandlerTest.tests.test_basic_error_handling = function()
    ErrorHandlerTest.setup()
    
    local errorInfo, recovered = ErrorHandler.handleError(
        ErrorHandler.ErrorCodes.INVALID_INPUT,
        "Test error details",
        {testContext = true}
    )
    
    assert(errorInfo ~= nil, "Error info should be returned")
    assert(errorInfo.code == ErrorHandler.ErrorCodes.INVALID_INPUT, "Error code should match")
    assert(errorInfo.message ~= nil, "Error message should exist")
    assert(errorInfo.details == "Test error details", "Details should match")
    assert(errorInfo.context.testContext == true, "Context should be preserved")
    
    ErrorHandlerTest.teardown()
end

-- Test 2: Error codes and messages
ErrorHandlerTest.tests.test_error_codes = function()
    ErrorHandlerTest.setup()
    
    -- Test system error
    local sysMsg = ErrorHandler.getErrorMessage(ErrorHandler.ErrorCodes.SYSTEM_ERROR)
    assert(sysMsg ~= nil, "System error message should exist")
    
    -- Test model error
    local modelMsg = ErrorHandler.getErrorMessage(ErrorHandler.ErrorCodes.MODEL_LOAD_FAILED)
    assert(modelMsg ~= nil, "Model error message should exist")
    
    -- Test API error
    local apiMsg = ErrorHandler.getErrorMessage(ErrorHandler.ErrorCodes.API_CONNECTION_FAILED)
    assert(apiMsg ~= nil, "API error message should exist")
    
    -- Test user error
    local userMsg = ErrorHandler.getErrorMessage(ErrorHandler.ErrorCodes.INVALID_PHOTO_FORMAT)
    assert(userMsg ~= nil, "User error message should exist")
    
    -- Test unknown error code
    local unknownMsg = ErrorHandler.getErrorMessage(9999)
    assert(unknownMsg == "未知錯誤", "Unknown error should return default message")
    
    ErrorHandlerTest.teardown()
end

-- Test 3: Recovery strategies
ErrorHandlerTest.tests.test_recovery_strategies = function()
    ErrorHandlerTest.setup()
    
    -- Register custom recovery strategy
    local recoveryExecuted = false
    ErrorHandler.registerRecoveryStrategy(
        ErrorHandler.ErrorCodes.MODEL_LOAD_FAILED,
        function(errorInfo)
            recoveryExecuted = true
            return true  -- Recovery successful
        end
    )
    
    -- Trigger error with recovery
    local errorInfo, recovered = ErrorHandler.handleError(
        ErrorHandler.ErrorCodes.MODEL_LOAD_FAILED,
        "Model loading test"
    )
    
    assert(recoveryExecuted == true, "Recovery strategy should be executed")
    assert(recovered == true, "Recovery should be successful")
    
    ErrorHandlerTest.teardown()
end

-- Test 4: Error history
ErrorHandlerTest.tests.test_error_history = function()
    ErrorHandlerTest.setup()
    
    -- Generate multiple errors
    for i = 1, 5 do
        ErrorHandler.handleError(
            ErrorHandler.ErrorCodes.INVALID_INPUT,
            "Test error " .. i
        )
    end
    
    -- Check history
    local history = ErrorHandler.getErrorHistory()
    assert(#history == 5, "History should contain 5 errors")
    
    -- Test history limit
    local limitedHistory = ErrorHandler.getErrorHistory(3)
    assert(#limitedHistory == 3, "Limited history should return 3 errors")
    
    -- Clear history
    ErrorHandler.clearHistory()
    local clearedHistory = ErrorHandler.getErrorHistory()
    assert(#clearedHistory == 0, "History should be empty after clearing")
    
    ErrorHandlerTest.teardown()
end

-- Test 5: Retry with backoff
ErrorHandlerTest.tests.test_retry_backoff = function()
    ErrorHandlerTest.setup()
    
    local attemptCount = 0
    local function unstableFunction()
        attemptCount = attemptCount + 1
        if attemptCount < 3 then
            error("Simulated failure")
        end
        return "success"
    end
    
    local result = ErrorHandler.retryWithBackoff(unstableFunction, 5, 10)
    
    assert(attemptCount == 3, "Should retry until success")
    assert(result == "success", "Should return success value")
    
    -- Test max attempts exceeded
    attemptCount = 0
    local function alwaysFailFunction()
        attemptCount = attemptCount + 1
        error("Always fails")
    end
    
    local failResult = ErrorHandler.retryWithBackoff(alwaysFailFunction, 3, 10)
    
    assert(attemptCount == 3, "Should try exactly max attempts")
    assert(failResult == nil, "Should return nil on all failures")
    
    ErrorHandlerTest.teardown()
end

-- Test 6: Error callbacks
ErrorHandlerTest.tests.test_error_callbacks = function()
    ErrorHandlerTest.setup()
    
    local callbackExecuted = false
    local callbackErrorInfo = nil
    
    -- Register callback
    ErrorHandler.registerCallback(function(errorInfo)
        callbackExecuted = true
        callbackErrorInfo = errorInfo
    end)
    
    -- Trigger error
    ErrorHandler.handleError(
        ErrorHandler.ErrorCodes.SYSTEM_ERROR,
        "Callback test"
    )
    
    assert(callbackExecuted == true, "Callback should be executed")
    assert(callbackErrorInfo ~= nil, "Callback should receive error info")
    assert(callbackErrorInfo.code == ErrorHandler.ErrorCodes.SYSTEM_ERROR, 
           "Callback should receive correct error code")
    
    ErrorHandlerTest.teardown()
end

-- Test 7: Protected call
ErrorHandlerTest.tests.test_protected_call = function()
    ErrorHandlerTest.setup()
    
    -- Test successful call
    local successResult = ErrorHandler.protectedCall(
        function() return "success value" end,
        ErrorHandler.ErrorCodes.SYSTEM_ERROR,
        {test = true}
    )
    
    assert(successResult == "success value", "Should return function result on success")
    
    -- Test failed call
    local failResult, failError = ErrorHandler.protectedCall(
        function() error("Test error") end,
        ErrorHandler.ErrorCodes.SYSTEM_ERROR,
        {test = true}
    )
    
    assert(failResult == nil, "Should return nil on failure")
    assert(failError ~= nil, "Should return error on failure")
    
    ErrorHandlerTest.teardown()
end

-- Test 8: Memory error recovery
ErrorHandlerTest.tests.test_memory_error_recovery = function()
    ErrorHandlerTest.setup()
    
    -- Test automatic memory recovery
    local errorInfo, recovered = ErrorHandler.handleError(
        ErrorHandler.ErrorCodes.MEMORY_ERROR,
        "Out of memory"
    )
    
    assert(recovered == true, "Memory error should trigger automatic recovery")
    
    ErrorHandlerTest.teardown()
end

-- Test 9: API error recovery
ErrorHandlerTest.tests.test_api_error_recovery = function()
    ErrorHandlerTest.setup()
    
    -- Test API connection failure recovery
    local errorInfo, recovered = ErrorHandler.handleError(
        ErrorHandler.ErrorCodes.API_CONNECTION_FAILED,
        "Connection timeout"
    )
    
    assert(recovered == true, "API error should trigger offline mode")
    
    ErrorHandlerTest.teardown()
end

-- Test 10: Error severity handling
ErrorHandlerTest.tests.test_error_severity = function()
    ErrorHandlerTest.setup()
    
    -- Test different error severities
    local errors = {
        {code = ErrorHandler.ErrorCodes.SYSTEM_ERROR, severity = "system"},
        {code = ErrorHandler.ErrorCodes.MODEL_LOAD_FAILED, severity = "model"},
        {code = ErrorHandler.ErrorCodes.API_RATE_LIMIT, severity = "api"},
        {code = ErrorHandler.ErrorCodes.INVALID_INPUT, severity = "user"}
    }
    
    for _, errorDef in ipairs(errors) do
        local errorInfo = ErrorHandler.handleError(errorDef.code, "Severity test")
        assert(errorInfo ~= nil, errorDef.severity .. " error should be handled")
        assert(errorInfo.code == errorDef.code, "Error code should match")
    end
    
    ErrorHandlerTest.teardown()
end

return ErrorHandlerTest