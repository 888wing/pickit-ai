/**
 * ONNX Runtime Inference Module
 * Handles AI model loading and inference
 */

const ort = require('onnxruntime-node');
const path = require('path');
const fs = require('fs').promises;

class ONNXInference {
    constructor(modelManager, logger) {
        this.modelManager = modelManager;
        this.logger = logger;
        this.sessions = {};
    }

    async initialize() {
        this.logger.info('Initializing ONNX Runtime...');
        
        // Set ONNX Runtime options
        ort.env.wasm.numThreads = 4;
        ort.env.logLevel = 'warning';
        
        // Load default models
        await this.loadDefaultModels();
        
        this.logger.info('ONNX Runtime initialized');
    }

    async loadDefaultModels() {
        const defaultModels = [
            'nima_aesthetic',
            'nima_technical',
            // 'blazeface',  // Will be added when model is downloaded
        ];

        for (const modelName of defaultModels) {
            try {
                await this.loadModel(modelName);
            } catch (error) {
                this.logger.warn(`Failed to load default model ${modelName}:`, error.message);
            }
        }
    }

    async loadModel(modelName) {
        if (this.sessions[modelName]) {
            this.logger.info(`Model ${modelName} already loaded`);
            return;
        }

        const modelPath = await this.modelManager.getModelPath(modelName);
        
        try {
            this.logger.info(`Loading model: ${modelName} from ${modelPath}`);
            const session = await ort.InferenceSession.create(modelPath);
            this.sessions[modelName] = session;
            this.logger.info(`Model ${modelName} loaded successfully`);
        } catch (error) {
            this.logger.error(`Failed to load model ${modelName}:`, error);
            throw error;
        }
    }

    async assessQuality(imageData) {
        const results = {
            technical: 0,
            aesthetic: 0,
            overall: 0,
            details: {}
        };

        try {
            // Technical quality assessment
            if (this.sessions.nima_technical) {
                const technicalScore = await this.runNIMA(imageData, 'nima_technical');
                results.technical = technicalScore;
                results.details.technical = {
                    score: technicalScore,
                    rating: this.getRating(technicalScore)
                };
            }

            // Aesthetic quality assessment
            if (this.sessions.nima_aesthetic) {
                const aestheticScore = await this.runNIMA(imageData, 'nima_aesthetic');
                results.aesthetic = aestheticScore;
                results.details.aesthetic = {
                    score: aestheticScore,
                    rating: this.getRating(aestheticScore)
                };
            }

            // Calculate overall score (weighted average)
            const technicalWeight = 0.4;
            const aestheticWeight = 0.6;
            results.overall = (results.technical * technicalWeight) + 
                            (results.aesthetic * aestheticWeight);

        } catch (error) {
            this.logger.error('Error in quality assessment:', error);
            throw error;
        }

        return results;
    }

    async runNIMA(imageData, modelName) {
        const session = this.sessions[modelName];
        if (!session) {
            throw new Error(`Model ${modelName} not loaded`);
        }

        try {
            // Prepare input tensor
            // NIMA expects 224x224x3 normalized image
            const inputTensor = new ort.Tensor('float32', imageData, [1, 3, 224, 224]);
            
            // Run inference
            const feeds = { input: inputTensor };
            const results = await session.run(feeds);
            
            // Extract score (NIMA outputs distribution over 1-10)
            const output = results.output.data;
            const score = this.calculateMeanScore(output);
            
            return score;
        } catch (error) {
            this.logger.error(`Error running NIMA inference:`, error);
            throw error;
        }
    }

    calculateMeanScore(distribution) {
        // NIMA outputs a probability distribution over scores 1-10
        // Calculate weighted mean
        let meanScore = 0;
        for (let i = 0; i < 10; i++) {
            meanScore += (i + 1) * distribution[i];
        }
        return meanScore;
    }

    getRating(score) {
        if (score >= 7) return 'excellent';
        if (score >= 5) return 'good';
        if (score >= 3) return 'average';
        return 'poor';
    }

    async detectFaces(imageData) {
        const session = this.sessions.blazeface;
        if (!session) {
            // Fallback to mock data if model not loaded
            this.logger.warn('BlazeFace model not loaded, returning empty result');
            return [];
        }

        try {
            // Prepare input tensor for BlazeFace
            // BlazeFace expects 128x128x3 image
            const inputTensor = new ort.Tensor('float32', imageData, [1, 3, 128, 128]);
            
            // Run inference
            const feeds = { input: inputTensor };
            const results = await session.run(feeds);
            
            // Parse face detection results
            const faces = this.parseFaceDetections(results);
            
            return faces;
        } catch (error) {
            this.logger.error('Error in face detection:', error);
            throw error;
        }
    }

    parseFaceDetections(results) {
        // Parse BlazeFace output
        // This is a simplified version - actual implementation depends on model output format
        const faces = [];
        
        // Extract bounding boxes and confidence scores
        if (results.boxes && results.scores) {
            const boxes = results.boxes.data;
            const scores = results.scores.data;
            
            for (let i = 0; i < scores.length; i++) {
                if (scores[i] > 0.5) { // Confidence threshold
                    faces.push({
                        bbox: [
                            boxes[i * 4],
                            boxes[i * 4 + 1],
                            boxes[i * 4 + 2],
                            boxes[i * 4 + 3]
                        ],
                        confidence: scores[i],
                        quality: this.assessFaceQuality(boxes, i)
                    });
                }
            }
        }
        
        return faces;
    }

    assessFaceQuality(boxes, index) {
        // Simple face quality assessment based on size and position
        const width = boxes[index * 4 + 2] - boxes[index * 4];
        const height = boxes[index * 4 + 3] - boxes[index * 4 + 1];
        const size = width * height;
        
        // Quality based on face size (larger is generally better)
        if (size > 0.1) return 'good';
        if (size > 0.05) return 'medium';
        return 'poor';
    }

    async extractFeatures(imageBuffer) {
        // Feature extraction for similarity comparison
        // This would use a feature extraction model like MobileNet
        // For now, return mock features
        
        this.logger.info('Extracting features from image');
        
        // In production, this would run a feature extraction model
        // For MVP, we'll use a simple approach
        const features = new Float32Array(512); // 512-dimensional feature vector
        for (let i = 0; i < 512; i++) {
            features[i] = Math.random(); // Placeholder
        }
        
        return features;
    }

    async cleanup() {
        this.logger.info('Cleaning up ONNX sessions...');
        
        for (const [name, session] of Object.entries(this.sessions)) {
            try {
                await session.release();
                this.logger.info(`Released session: ${name}`);
            } catch (error) {
                this.logger.error(`Error releasing session ${name}:`, error);
            }
        }
        
        this.sessions = {};
    }
}

module.exports = ONNXInference;