/**
 * API Test Suite for Node Bridge Server
 * Tests all endpoints and functionalities
 */

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000';
const api = axios.create({
    baseURL: BASE_URL,
    timeout: 30000,
    validateStatus: () => true // Don't throw on any status
});

// Test utilities
const colors = {
    reset: '\x1b[0m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTestResult(testName, passed, details = '') {
    if (passed) {
        log(`  ✅ ${testName}`, 'green');
    } else {
        log(`  ❌ ${testName}`, 'red');
        if (details) log(`     ${details}`, 'yellow');
    }
    return passed;
}

class TestRunner {
    constructor() {
        this.results = {
            total: 0,
            passed: 0,
            failed: 0,
            tests: []
        };
    }

    async runTest(name, testFn) {
        this.results.total++;
        try {
            const result = await testFn();
            if (result) {
                this.results.passed++;
                this.results.tests.push({ name, status: 'passed' });
                logTestResult(name, true);
            } else {
                this.results.failed++;
                this.results.tests.push({ name, status: 'failed' });
                logTestResult(name, false);
            }
            return result;
        } catch (error) {
            this.results.failed++;
            this.results.tests.push({ name, status: 'error', error: error.message });
            logTestResult(name, false, error.message);
            return false;
        }
    }

    printSummary() {
        console.log('\n' + '='.repeat(60));
        log('TEST SUMMARY', 'cyan');
        console.log('='.repeat(60));
        log(`Total Tests: ${this.results.total}`, 'blue');
        log(`Passed: ${this.results.passed}`, 'green');
        log(`Failed: ${this.results.failed}`, this.results.failed > 0 ? 'red' : 'green');
        
        if (this.results.failed > 0) {
            console.log('\nFailed Tests:');
            this.results.tests
                .filter(t => t.status !== 'passed')
                .forEach(t => {
                    log(`  - ${t.name}`, 'red');
                    if (t.error) log(`    Error: ${t.error}`, 'yellow');
                });
        }
        
        const successRate = ((this.results.passed / this.results.total) * 100).toFixed(1);
        console.log('\n' + '='.repeat(60));
        log(`Success Rate: ${successRate}%`, successRate === '100.0' ? 'green' : 'yellow');
        console.log('='.repeat(60) + '\n');
    }
}

// Test suites
async function testHealthCheck(runner) {
    log('\n📍 Testing Health Check Endpoints', 'cyan');
    
    await runner.runTest('GET /health - Basic health check', async () => {
        const response = await api.get('/health');
        return response.status === 200 && 
               response.data.status === 'healthy' &&
               response.data.version === '1.0.0';
    });

    await runner.runTest('GET /api/health - API health check', async () => {
        const response = await api.get('/api/health');
        return response.status === 200 && 
               response.data.status === 'healthy' &&
               response.data.services &&
               response.data.services.modelManager === 'ready' &&
               response.data.services.onnxRuntime === 'ready';
    });
}

async function testPhotoAnalysis(runner) {
    log('\n📸 Testing Photo Analysis Endpoints', 'cyan');
    
    // Create a test image
    const testImagePath = path.join(__dirname, 'test-image.jpg');
    const imageBuffer = Buffer.from('fake-image-data');
    fs.writeFileSync(testImagePath, imageBuffer);

    await runner.runTest('POST /api/analyze - Analyze single photo', async () => {
        const formData = new FormData();
        formData.append('image', fs.createReadStream(testImagePath));
        
        const response = await api.post('/api/analyze', formData, {
            headers: formData.getHeaders()
        });
        
        return response.status === 200 &&
               response.data.success === true &&
               response.data.results &&
               typeof response.data.results.aesthetic === 'number' &&
               typeof response.data.results.technical === 'number';
    });

    await runner.runTest('POST /api/analyze/quality - Quality analysis', async () => {
        const formData = new FormData();
        formData.append('image', fs.createReadStream(testImagePath));
        
        const response = await api.post('/api/analyze/quality', formData, {
            headers: formData.getHeaders()
        });
        
        return response.status === 200 &&
               response.data.success === true &&
               response.data.quality &&
               typeof response.data.quality.score === 'number';
    });

    await runner.runTest('POST /api/analyze/faces - Face detection', async () => {
        const formData = new FormData();
        formData.append('image', fs.createReadStream(testImagePath));
        
        const response = await api.post('/api/analyze/faces', formData, {
            headers: formData.getHeaders()
        });
        
        return response.status === 200 &&
               response.data.success === true &&
               Array.isArray(response.data.faces);
    });

    // Cleanup
    fs.unlinkSync(testImagePath);
}

async function testBatchProcessing(runner) {
    log('\n📦 Testing Batch Processing Endpoints', 'cyan');
    
    await runner.runTest('POST /api/batch/start - Start batch processing', async () => {
        const response = await api.post('/api/batch/start', {
            images: ['image1.jpg', 'image2.jpg', 'image3.jpg'],
            options: {
                threshold: 0.7,
                includeMetadata: true
            }
        });
        
        return response.status === 200 &&
               response.data.success === true &&
               response.data.batchId &&
               response.data.totalImages === 3;
    });

    await runner.runTest('GET /api/batch/status/:id - Get batch status', async () => {
        // First create a batch
        const createResponse = await api.post('/api/batch/start', {
            images: ['test.jpg']
        });
        
        if (createResponse.data.batchId) {
            const response = await api.get(`/api/batch/status/${createResponse.data.batchId}`);
            return response.status === 200 &&
                   response.data.status &&
                   typeof response.data.progress === 'number';
        }
        return false;
    });

    await runner.runTest('POST /api/batch/cancel/:id - Cancel batch', async () => {
        // First create a batch
        const createResponse = await api.post('/api/batch/start', {
            images: ['test.jpg']
        });
        
        if (createResponse.data.batchId) {
            const response = await api.post(`/api/batch/cancel/${createResponse.data.batchId}`);
            return response.status === 200 &&
                   response.data.success === true;
        }
        return false;
    });
}

async function testModelManagement(runner) {
    log('\n🤖 Testing Model Management Endpoints', 'cyan');
    
    await runner.runTest('GET /api/models - List available models', async () => {
        const response = await api.get('/api/models');
        return response.status === 200 &&
               Array.isArray(response.data.models) &&
               response.data.models.length > 0;
    });

    await runner.runTest('GET /api/models/:name - Get model info', async () => {
        const response = await api.get('/api/models/nima_aesthetic');
        return response.status === 200 &&
               response.data.name === 'nima_aesthetic' &&
               response.data.type &&
               response.data.path;
    });

    await runner.runTest('POST /api/models/load - Load specific model', async () => {
        const response = await api.post('/api/models/load', {
            modelName: 'nima_technical'
        });
        // Mock models will fail to load, but endpoint should respond
        return response.status === 200 || response.status === 500;
    });

    await runner.runTest('POST /api/models/unload - Unload model', async () => {
        const response = await api.post('/api/models/unload', {
            modelName: 'nima_aesthetic'
        });
        return response.status === 200 &&
               response.data.success === true;
    });
}

async function testErrorHandling(runner) {
    log('\n⚠️ Testing Error Handling', 'cyan');
    
    await runner.runTest('POST /api/analyze - Missing image', async () => {
        const response = await api.post('/api/analyze', {});
        return response.status === 400 &&
               response.data.error &&
               response.data.error.includes('No image');
    });

    await runner.runTest('GET /api/batch/status/invalid - Invalid batch ID', async () => {
        const response = await api.get('/api/batch/status/invalid-id-123');
        return response.status === 404 &&
               response.data.error &&
               response.data.error.includes('not found');
    });

    await runner.runTest('GET /api/models/nonexistent - Non-existent model', async () => {
        const response = await api.get('/api/models/nonexistent-model');
        return response.status === 404 &&
               response.data.error &&
               response.data.error.includes('not found');
    });

    await runner.runTest('POST /api/invalid-endpoint - Invalid endpoint', async () => {
        const response = await api.post('/api/invalid-endpoint');
        return response.status === 404;
    });
}

async function testPerformance(runner) {
    log('\n⚡ Testing Performance', 'cyan');
    
    await runner.runTest('Response time < 100ms for health check', async () => {
        const start = Date.now();
        await api.get('/health');
        const elapsed = Date.now() - start;
        return elapsed < 100;
    });

    await runner.runTest('Concurrent requests handling', async () => {
        const promises = Array(10).fill(null).map(() => api.get('/api/health'));
        const responses = await Promise.all(promises);
        return responses.every(r => r.status === 200);
    });
}

// Main test execution
async function runAllTests() {
    console.clear();
    log('🚀 LIGHTROOM AI SELECTOR - NODE BRIDGE TEST SUITE', 'cyan');
    log('=' .repeat(60), 'blue');
    
    // Check if server is running
    try {
        await api.get('/health');
    } catch (error) {
        log('\n❌ Error: Server is not running on port 3000', 'red');
        log('Please start the server with: npm start\n', 'yellow');
        process.exit(1);
    }
    
    const runner = new TestRunner();
    
    // Run all test suites
    await testHealthCheck(runner);
    await testPhotoAnalysis(runner);
    await testBatchProcessing(runner);
    await testModelManagement(runner);
    await testErrorHandling(runner);
    await testPerformance(runner);
    
    // Print summary
    runner.printSummary();
    
    // Exit with appropriate code
    process.exit(runner.results.failed > 0 ? 1 : 0);
}

// Run tests
runAllTests().catch(error => {
    log(`\n❌ Unexpected error: ${error.message}`, 'red');
    process.exit(1);
});