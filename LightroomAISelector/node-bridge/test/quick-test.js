/**
 * Quick test to check available endpoints
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function quickTest() {
    console.log('🔍 Quick Server Test\n');
    
    const tests = [
        { method: 'GET', path: '/health', name: 'Basic Health' },
        { method: 'GET', path: '/api/status', name: 'API Status' },
        { method: 'POST', path: '/analyze', name: 'Analyze (root)' },
        { method: 'POST', path: '/api/analyze', name: 'Analyze (API)' },
        { method: 'GET', path: '/models', name: 'Models List' },
    ];
    
    for (const test of tests) {
        try {
            const response = await axios({
                method: test.method,
                url: `${BASE_URL}${test.path}`,
                validateStatus: () => true,
                timeout: 5000
            });
            
            const status = response.status;
            const statusIcon = status < 400 ? '✅' : status < 500 ? '⚠️' : '❌';
            console.log(`${statusIcon} ${test.name}: ${status} - ${test.method} ${test.path}`);
            
            if (status === 200) {
                console.log(`   Response: ${JSON.stringify(response.data).substring(0, 100)}...`);
            }
        } catch (error) {
            console.log(`❌ ${test.name}: Connection error - ${error.message}`);
        }
    }
    
    console.log('\n📝 Testing with actual implementation from server.js...\n');
    
    // Test the actual implemented endpoints based on server.js
    try {
        // Test /analyze endpoint
        const analyzeResponse = await axios.post(`${BASE_URL}/analyze`, {
            imagePath: 'test.jpg'
        });
        console.log('✅ POST /analyze works:', analyzeResponse.data);
    } catch (error) {
        console.log('❌ POST /analyze error:', error.response?.data || error.message);
    }
    
    try {
        // Test /models endpoint  
        const modelsResponse = await axios.get(`${BASE_URL}/models`);
        console.log('✅ GET /models works:', modelsResponse.data);
    } catch (error) {
        console.log('❌ GET /models error:', error.response?.data || error.message);
    }
}

quickTest().catch(console.error);