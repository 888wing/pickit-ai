/**
 * Image Processing Module
 * Handles image preprocessing and computer vision operations
 */

const sharp = require('sharp');

class ImageProcessor {
    constructor(logger) {
        this.logger = logger;
    }

    async preprocessForNIMA(imageBuffer) {
        try {
            // NIMA expects 224x224 RGB image, normalized to [0, 1]
            const processed = await sharp(imageBuffer)
                .resize(224, 224, {
                    fit: 'cover',
                    position: 'center'
                })
                .removeAlpha()
                .raw()
                .toBuffer();

            // Convert to float32 array and normalize
            const pixels = new Float32Array(processed.length);
            for (let i = 0; i < processed.length; i++) {
                pixels[i] = processed[i] / 255.0;
            }

            // Reshape to CHW format (channels, height, width)
            const reshapedData = this.reshapeToCHW(pixels, 224, 224, 3);
            
            return reshapedData;
        } catch (error) {
            this.logger.error('Error preprocessing image for NIMA:', error);
            throw error;
        }
    }

    async preprocessForFaceDetection(imageBuffer) {
        try {
            // BlazeFace expects 128x128 RGB image
            const processed = await sharp(imageBuffer)
                .resize(128, 128, {
                    fit: 'cover',
                    position: 'center'
                })
                .removeAlpha()
                .raw()
                .toBuffer();

            // Convert to float32 array and normalize
            const pixels = new Float32Array(processed.length);
            for (let i = 0; i < processed.length; i++) {
                pixels[i] = processed[i] / 255.0;
            }

            // Reshape to CHW format
            const reshapedData = this.reshapeToCHW(pixels, 128, 128, 3);
            
            return reshapedData;
        } catch (error) {
            this.logger.error('Error preprocessing image for face detection:', error);
            throw error;
        }
    }

    reshapeToCHW(data, height, width, channels) {
        // Convert from HWC (height, width, channels) to CHW (channels, height, width)
        const chw = new Float32Array(data.length);
        let idx = 0;
        
        for (let c = 0; c < channels; c++) {
            for (let h = 0; h < height; h++) {
                for (let w = 0; w < width; w++) {
                    chw[idx++] = data[h * width * channels + w * channels + c];
                }
            }
        }
        
        return chw;
    }

    async calculateBlur(imageBuffer) {
        try {
            // Convert to grayscale and get raw pixels
            const { data, info } = await sharp(imageBuffer)
                .grayscale()
                .raw()
                .toBuffer({ resolveWithObject: true });

            // Calculate Laplacian variance (measure of blur)
            const laplacian = this.applyLaplacianKernel(data, info.width, info.height);
            const variance = this.calculateVariance(laplacian);
            
            return variance;
        } catch (error) {
            this.logger.error('Error calculating blur:', error);
            throw error;
        }
    }

    applyLaplacianKernel(pixels, width, height) {
        // Laplacian kernel for edge detection
        const kernel = [
            [0, 1, 0],
            [1, -4, 1],
            [0, 1, 0]
        ];
        
        const result = new Float32Array((width - 2) * (height - 2));
        let idx = 0;
        
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                let sum = 0;
                
                for (let ky = 0; ky < 3; ky++) {
                    for (let kx = 0; kx < 3; kx++) {
                        const pixelIdx = (y + ky - 1) * width + (x + kx - 1);
                        sum += pixels[pixelIdx] * kernel[ky][kx];
                    }
                }
                
                result[idx++] = Math.abs(sum);
            }
        }
        
        return result;
    }

    calculateVariance(data) {
        const mean = data.reduce((sum, val) => sum + val, 0) / data.length;
        const variance = data.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / data.length;
        return variance;
    }

    async analyzeHistogram(imageBuffer) {
        try {
            const { data, info } = await sharp(imageBuffer)
                .raw()
                .toBuffer({ resolveWithObject: true });

            const histogram = {
                r: new Array(256).fill(0),
                g: new Array(256).fill(0),
                b: new Array(256).fill(0)
            };

            // Build histogram
            for (let i = 0; i < data.length; i += info.channels) {
                histogram.r[data[i]]++;
                if (info.channels > 1) histogram.g[data[i + 1]]++;
                if (info.channels > 2) histogram.b[data[i + 2]]++;
            }

            // Analyze histogram for exposure issues
            const analysis = this.analyzeExposure(histogram, info.width * info.height);
            
            return analysis;
        } catch (error) {
            this.logger.error('Error analyzing histogram:', error);
            throw error;
        }
    }

    analyzeExposure(histogram, totalPixels) {
        // Check for over/underexposure
        const threshold = totalPixels * 0.05; // 5% threshold
        
        let underexposed = 0;
        let overexposed = 0;
        
        // Check dark pixels (0-20)
        for (let i = 0; i < 20; i++) {
            underexposed += histogram.r[i] + histogram.g[i] + histogram.b[i];
        }
        
        // Check bright pixels (235-255)
        for (let i = 235; i < 256; i++) {
            overexposed += histogram.r[i] + histogram.g[i] + histogram.b[i];
        }
        
        return {
            isUnderexposed: underexposed > threshold * 3,
            isOverexposed: overexposed > threshold * 3,
            underexposureRatio: underexposed / (totalPixels * 3),
            overexposureRatio: overexposed / (totalPixels * 3)
        };
    }

    calculateSimilarity(features1, features2) {
        // Calculate cosine similarity between feature vectors
        if (features1.length !== features2.length) {
            throw new Error('Feature vectors must have the same length');
        }
        
        let dotProduct = 0;
        let norm1 = 0;
        let norm2 = 0;
        
        for (let i = 0; i < features1.length; i++) {
            dotProduct += features1[i] * features2[i];
            norm1 += features1[i] * features1[i];
            norm2 += features2[i] * features2[i];
        }
        
        norm1 = Math.sqrt(norm1);
        norm2 = Math.sqrt(norm2);
        
        if (norm1 === 0 || norm2 === 0) {
            return 0;
        }
        
        return dotProduct / (norm1 * norm2);
    }

    async analyzeSaturation(imageBuffer) {
        try {
            const { data, info } = await sharp(imageBuffer)
                .raw()
                .toBuffer({ resolveWithObject: true });

            let totalSaturation = 0;
            const pixelCount = info.width * info.height;
            
            for (let i = 0; i < data.length; i += info.channels) {
                const r = data[i] / 255;
                const g = data[i + 1] / 255;
                const b = data[i + 2] / 255;
                
                const max = Math.max(r, g, b);
                const min = Math.min(r, g, b);
                
                const saturation = max === 0 ? 0 : (max - min) / max;
                totalSaturation += saturation;
            }
            
            return totalSaturation / pixelCount;
        } catch (error) {
            this.logger.error('Error analyzing saturation:', error);
            throw error;
        }
    }

    async analyzeContrast(imageBuffer) {
        try {
            const { data, info } = await sharp(imageBuffer)
                .grayscale()
                .raw()
                .toBuffer({ resolveWithObject: true });

            // Calculate standard deviation as a measure of contrast
            const mean = data.reduce((sum, val) => sum + val, 0) / data.length;
            const variance = data.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / data.length;
            const stdDev = Math.sqrt(variance);
            
            // Normalize to 0-1 range
            return stdDev / 128; // Max std dev for 8-bit image is ~128
        } catch (error) {
            this.logger.error('Error analyzing contrast:', error);
            throw error;
        }
    }
}

module.exports = ImageProcessor;