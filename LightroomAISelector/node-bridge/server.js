/**
 * Node.js Bridge Server for ONNX Runtime
 * Provides HTTP API for Lua plugin to perform AI inference
 */

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs').promises;
const winston = require('winston');
require('dotenv').config();

// Import inference modules
const ONNXInference = require('./src/onnx-inference');
const ImageProcessor = require('./src/image-processor');
const ModelManager = require('./src/model-manager');
const FeedbackService = require('./feedback-service');

// Configure logger
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console({
            format: winston.format.simple()
        }),
        new winston.transports.File({ 
            filename: 'logs/bridge-error.log', 
            level: 'error' 
        }),
        new winston.transports.File({ 
            filename: 'logs/bridge-combined.log' 
        })
    ]
});

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Configure multer for file uploads
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 50 * 1024 * 1024, // 50MB max file size
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|tiff|dng|raw/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        
        if (mimetype || extname) {
            return cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only image files are allowed.'));
        }
    }
});

// Initialize services
let onnxInference;
let imageProcessor;
let modelManager;

async function initializeServices() {
    try {
        logger.info('Initializing services...');
        
        // Initialize model manager
        modelManager = new ModelManager(logger);
        await modelManager.initialize();
        
        // Initialize image processor
        imageProcessor = new ImageProcessor(logger);
        
        // Initialize ONNX inference
        onnxInference = new ONNXInference(modelManager, logger);
        await onnxInference.initialize();
        
        logger.info('All services initialized successfully');
    } catch (error) {
        logger.error('Failed to initialize services:', error);
        process.exit(1);
    }
}

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        version: '1.0.0',
        uptime: process.uptime(),
        models: modelManager ? modelManager.getLoadedModels() : []
    });
});

// Get available models
app.get('/models', (req, res) => {
    try {
        const models = modelManager.getAvailableModels();
        res.json({ models });
    } catch (error) {
        logger.error('Error getting models:', error);
        res.status(500).json({ error: error.message });
    }
});

// Load a specific model
app.post('/models/load', async (req, res) => {
    try {
        const { modelName } = req.body;
        await modelManager.loadModel(modelName);
        res.json({ 
            success: true, 
            message: `Model ${modelName} loaded successfully` 
        });
    } catch (error) {
        logger.error('Error loading model:', error);
        res.status(500).json({ error: error.message });
    }
});

// Image quality assessment endpoint
app.post('/assess/quality', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided' });
        }
        
        // Process image
        const processedImage = await imageProcessor.preprocessForNIMA(req.file.buffer);
        
        // Run inference
        const scores = await onnxInference.assessQuality(processedImage);
        
        res.json({
            technical_score: scores.technical,
            aesthetic_score: scores.aesthetic,
            overall_score: scores.overall,
            details: scores.details
        });
    } catch (error) {
        logger.error('Error assessing image quality:', error);
        res.status(500).json({ error: error.message });
    }
});

// Face detection endpoint
app.post('/detect/faces', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided' });
        }
        
        // Process image for face detection
        const processedImage = await imageProcessor.preprocessForFaceDetection(req.file.buffer);
        
        // Run face detection
        const faces = await onnxInference.detectFaces(processedImage);
        
        res.json({
            face_count: faces.length,
            faces: faces.map(face => ({
                bbox: face.bbox,
                confidence: face.confidence,
                landmarks: face.landmarks,
                quality: face.quality
            }))
        });
    } catch (error) {
        logger.error('Error detecting faces:', error);
        res.status(500).json({ error: error.message });
    }
});

// Blur detection endpoint
app.post('/detect/blur', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided' });
        }
        
        // Calculate blur using Laplacian variance
        const blurScore = await imageProcessor.calculateBlur(req.file.buffer);
        
        res.json({
            blur_score: blurScore,
            is_blurry: blurScore < 100,
            threshold: 100
        });
    } catch (error) {
        logger.error('Error detecting blur:', error);
        res.status(500).json({ error: error.message });
    }
});

// Batch processing endpoint
app.post('/batch/process', upload.array('images', 50), async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ error: 'No image files provided' });
        }
        
        const results = [];
        
        for (const file of req.files) {
            try {
                // Process each image
                const processedImage = await imageProcessor.preprocessForNIMA(file.buffer);
                const scores = await onnxInference.assessQuality(processedImage);
                const blurScore = await imageProcessor.calculateBlur(file.buffer);
                
                results.push({
                    filename: file.originalname,
                    scores: scores,
                    blur_score: blurScore,
                    success: true
                });
            } catch (error) {
                results.push({
                    filename: file.originalname,
                    error: error.message,
                    success: false
                });
            }
        }
        
        res.json({ results });
    } catch (error) {
        logger.error('Error in batch processing:', error);
        res.status(500).json({ error: error.message });
    }
});

// Feedback endpoints
const feedbackService = new FeedbackService();

app.post('/feedback/submit', async (req, res) => {
    try {
        const result = await feedbackService.submitFeedback(req.body);
        res.json(result);
    } catch (error) {
        logger.error('Error submitting feedback:', error);
        res.status(500).json({ 
            error: 'Failed to submit feedback',
            message: error.message 
        });
    }
});

app.post('/feedback/check-responses', async (req, res) => {
    try {
        const { submissionIds } = req.body;
        const responses = await feedbackService.checkResponses(submissionIds);
        res.json(responses);
    } catch (error) {
        logger.error('Error checking responses:', error);
        res.status(500).json({ 
            error: 'Failed to check responses',
            message: error.message 
        });
    }
});

app.get('/feedback/statistics', async (req, res) => {
    try {
        const stats = await feedbackService.getStatistics();
        res.json(stats);
    } catch (error) {
        logger.error('Error getting statistics:', error);
        res.status(500).json({ 
            error: 'Failed to get statistics',
            message: error.message 
        });
    }
});

// Similarity comparison endpoint
app.post('/compare/similarity', upload.array('images', 2), async (req, res) => {
    try {
        if (!req.files || req.files.length !== 2) {
            return res.status(400).json({ error: 'Exactly 2 images required for comparison' });
        }
        
        // Extract features from both images
        const features1 = await onnxInference.extractFeatures(req.files[0].buffer);
        const features2 = await onnxInference.extractFeatures(req.files[1].buffer);
        
        // Calculate similarity
        const similarity = imageProcessor.calculateSimilarity(features1, features2);
        
        res.json({
            similarity_score: similarity,
            are_similar: similarity > 0.85,
            threshold: 0.85
        });
    } catch (error) {
        logger.error('Error comparing images:', error);
        res.status(500).json({ error: error.message });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    logger.error('Unhandled error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: error.message
    });
});

// Start server
async function startServer() {
    await initializeServices();
    
    app.listen(PORT, () => {
        logger.info(`🚀 ONNX Bridge Server running on port ${PORT}`);
        logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
}

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM received, shutting down gracefully...');
    if (onnxInference) {
        await onnxInference.cleanup();
    }
    process.exit(0);
});

process.on('SIGINT', async () => {
    logger.info('SIGINT received, shutting down gracefully...');
    if (onnxInference) {
        await onnxInference.cleanup();
    }
    process.exit(0);
});

// Start the server
startServer().catch(error => {
    logger.error('Failed to start server:', error);
    process.exit(1);
});