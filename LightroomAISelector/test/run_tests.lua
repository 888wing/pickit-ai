--[[
    Test Runner for Lightroom AI Selector Plugin
    Runs all unit and integration tests
--]]

local Logger = require 'src/utils/Logger'
local logger = Logger:new('TestRunner')

-- Test modules
local tests = {
    'test/unit/PhotoScorer_test',
    'test/unit/BatchProcessor_test',
    'test/unit/ErrorHandler_test',
    'test/integration/EndToEnd_test'
}

-- Simple test framework
local TestFramework = {}

function TestFramework:new()
    local framework = {
        passed = 0,
        failed = 0,
        errors = {},
        startTime = os.time()
    }
    setmetatable(framework, { __index = self })
    return framework
end

function TestFramework:run(testModule)
    local success, module = pcall(require, testModule)
    
    if not success then
        logger:error("Failed to load test module: " .. testModule, {error = module})
        self.failed = self.failed + 1
        table.insert(self.errors, {
            module = testModule,
            error = "Failed to load: " .. tostring(module)
        })
        return
    end
    
    if not module.tests then
        logger:warn("No tests found in module: " .. testModule)
        return
    end
    
    logger:info("Running tests from: " .. testModule)
    
    -- Run setup if exists
    if module.setup then
        local success, err = pcall(module.setup)
        if not success then
            logger:error("Setup failed", {error = err})
        end
    end
    
    -- Run each test
    for testName, testFunc in pairs(module.tests) do
        local success, err = pcall(testFunc)
        
        if success then
            self.passed = self.passed + 1
            logger:info("✓ " .. testName)
        else
            self.failed = self.failed + 1
            logger:error("✗ " .. testName, {error = err})
            table.insert(self.errors, {
                module = testModule,
                test = testName,
                error = tostring(err)
            })
        end
    end
    
    -- Run teardown if exists
    if module.teardown then
        local success, err = pcall(module.teardown)
        if not success then
            logger:error("Teardown failed", {error = err})
        end
    end
end

function TestFramework:printSummary()
    local duration = os.time() - self.startTime
    
    print("\n" .. string.rep("=", 50))
    print("TEST RESULTS")
    print(string.rep("=", 50))
    print(string.format("Passed: %d", self.passed))
    print(string.format("Failed: %d", self.failed))
    print(string.format("Total: %d", self.passed + self.failed))
    print(string.format("Duration: %d seconds", duration))
    print(string.rep("=", 50))
    
    if self.failed > 0 then
        print("\nFAILED TESTS:")
        for _, error in ipairs(self.errors) do
            print(string.format("  • %s::%s", error.module or "unknown", error.test or "load"))
            print(string.format("    %s", error.error))
        end
    end
    
    if self.failed == 0 then
        print("\n✅ All tests passed!")
    else
        print(string.format("\n❌ %d tests failed", self.failed))
    end
end

-- Main execution
local function main()
    logger:info("Starting test run")
    
    local framework = TestFramework:new()
    
    -- Run all tests
    for _, testModule in ipairs(tests) do
        framework:run(testModule)
    end
    
    -- Print summary
    framework:printSummary()
    
    -- Return exit code
    return framework.failed == 0 and 0 or 1
end

-- Run if executed directly
if arg and arg[0]:match("run_tests%.lua$") then
    os.exit(main())
end

return {
    run = main,
    TestFramework = TestFramework
}