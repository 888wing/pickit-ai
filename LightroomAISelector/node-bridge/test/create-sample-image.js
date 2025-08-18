/**
 * Create a valid sample JPEG image for testing
 */

const sharp = require('sharp');
const path = require('path');

async function createSampleImages() {
    // Create a simple 100x100 colored image
    const imageBuffer = await sharp({
        create: {
            width: 100,
            height: 100,
            channels: 3,
            background: { r: 255, g: 100, b: 50 }
        }
    })
    .jpeg()
    .toBuffer();
    
    // Save test images
    const testPath1 = path.join(__dirname, 'sample1.jpg');
    const testPath2 = path.join(__dirname, 'sample2.jpg');
    
    await sharp(imageBuffer).toFile(testPath1);
    
    // Create a second image with different color
    const imageBuffer2 = await sharp({
        create: {
            width: 100,
            height: 100,
            channels: 3,
            background: { r: 50, g: 100, b: 255 }
        }
    })
    .jpeg()
    .toBuffer();
    
    await sharp(imageBuffer2).toFile(testPath2);
    
    console.log('✅ Created sample images:');
    console.log('  - sample1.jpg (orange)');
    console.log('  - sample2.jpg (blue)');
}

createSampleImages().catch(console.error);