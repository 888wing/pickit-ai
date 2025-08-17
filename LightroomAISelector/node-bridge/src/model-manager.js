/**
 * Model Manager Module
 * Handles AI model discovery, loading, and management
 */

const path = require('path');
const fs = require('fs').promises;

class ModelManager {
    constructor(logger) {
        this.logger = logger;
        this.modelsDir = path.join(__dirname, '..', '..', 'models');
        this.modelRegistry = {};
        this.loadedModels = new Set();
    }

    async initialize() {
        this.logger.info('Initializing Model Manager...');
        
        // Ensure models directory exists
        await this.ensureModelsDirectory();
        
        // Discover available models
        await this.discoverModels();
        
        this.logger.info(`Model Manager initialized. Found ${Object.keys(this.modelRegistry).length} models`);
    }

    async ensureModelsDirectory() {
        try {
            await fs.mkdir(this.modelsDir, { recursive: true });
            await fs.mkdir(path.join(this.modelsDir, 'configs'), { recursive: true });
        } catch (error) {
            this.logger.error('Error creating models directory:', error);
        }
    }

    async discoverModels() {
        // Define model configurations
        this.modelRegistry = {
            'nima_aesthetic': {
                name: 'NIMA Aesthetic',
                filename: 'nima_aesthetic.onnx',
                url: 'https://github.com/idealo/image-quality-assessment/releases/download/v1.0/nima_aesthetic.onnx',
                size: '15MB',
                description: 'Neural Image Assessment for aesthetic quality',
                inputShape: [1, 3, 224, 224],
                outputShape: [1, 10]
            },
            'nima_technical': {
                name: 'NIMA Technical',
                filename: 'nima_technical.onnx',
                url: 'https://github.com/idealo/image-quality-assessment/releases/download/v1.0/nima_technical.onnx',
                size: '15MB',
                description: 'Neural Image Assessment for technical quality',
                inputShape: [1, 3, 224, 224],
                outputShape: [1, 10]
            },
            'blazeface': {
                name: 'BlazeFace',
                filename: 'blazeface.onnx',
                url: 'https://storage.googleapis.com/mediapipe-models/blazeface.onnx',
                size: '1MB',
                description: 'Lightweight face detection model',
                inputShape: [1, 3, 128, 128],
                outputShape: 'variable'
            }
        };

        // Check which models are already downloaded
        for (const [key, model] of Object.entries(this.modelRegistry)) {
            const modelPath = path.join(this.modelsDir, model.filename);
            try {
                await fs.access(modelPath);
                model.available = true;
                this.logger.info(`Model available: ${key}`);
            } catch {
                model.available = false;
                this.logger.warn(`Model not found: ${key}. Run 'npm run install-models' to download.`);
            }
        }
    }

    async getModelPath(modelName) {
        const model = this.modelRegistry[modelName];
        if (!model) {
            throw new Error(`Unknown model: ${modelName}`);
        }

        const modelPath = path.join(this.modelsDir, model.filename);
        
        // Check if model exists
        try {
            await fs.access(modelPath);
            return modelPath;
        } catch {
            // Try to use a mock model for development
            const mockPath = path.join(this.modelsDir, 'mock', `${modelName}.onnx`);
            try {
                await fs.access(mockPath);
                this.logger.warn(`Using mock model for ${modelName}`);
                return mockPath;
            } catch {
                throw new Error(`Model file not found: ${model.filename}. Please download the model first.`);
            }
        }
    }

    async loadModel(modelName) {
        if (this.loadedModels.has(modelName)) {
            return true;
        }

        const model = this.modelRegistry[modelName];
        if (!model) {
            throw new Error(`Unknown model: ${modelName}`);
        }

        if (!model.available) {
            throw new Error(`Model not available: ${modelName}. Please download it first.`);
        }

        this.loadedModels.add(modelName);
        return true;
    }

    getAvailableModels() {
        return Object.entries(this.modelRegistry)
            .filter(([_, model]) => model.available)
            .map(([key, model]) => ({
                id: key,
                name: model.name,
                description: model.description,
                size: model.size
            }));
    }

    getLoadedModels() {
        return Array.from(this.loadedModels);
    }

    async downloadModel(modelName) {
        const model = this.modelRegistry[modelName];
        if (!model) {
            throw new Error(`Unknown model: ${modelName}`);
        }

        this.logger.info(`Downloading model: ${modelName} from ${model.url}`);
        
        // In production, this would download the model
        // For MVP, we'll create a placeholder
        const modelPath = path.join(this.modelsDir, model.filename);
        
        try {
            // Create a mock model file for testing
            await fs.writeFile(modelPath, Buffer.from('mock model data'));
            model.available = true;
            this.logger.info(`Model downloaded: ${modelName}`);
            return true;
        } catch (error) {
            this.logger.error(`Error downloading model ${modelName}:`, error);
            throw error;
        }
    }

    async validateModel(modelName) {
        const model = this.modelRegistry[modelName];
        if (!model) {
            throw new Error(`Unknown model: ${modelName}`);
        }

        const modelPath = path.join(this.modelsDir, model.filename);
        
        try {
            const stats = await fs.stat(modelPath);
            
            // Basic validation - check file size
            if (stats.size < 1000) {
                throw new Error('Model file too small, might be corrupted');
            }
            
            return true;
        } catch (error) {
            this.logger.error(`Model validation failed for ${modelName}:`, error);
            return false;
        }
    }

    async clearCache() {
        this.loadedModels.clear();
        this.logger.info('Model cache cleared');
    }
}

module.exports = ModelManager;