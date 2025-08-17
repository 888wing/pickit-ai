#!/bin/bash

# Lightroom AI Selector Plugin Build Script
# Builds the plugin package for distribution

PLUGIN_NAME="LightroomAISelector.lrplugin"
BUILD_DIR="build"
DIST_DIR="dist"
VERSION="1.0.0"

echo "🚀 Building Lightroom AI Selector Plugin v${VERSION}"

# Clean previous builds
echo "📦 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"

# Create build directory
mkdir -p "$BUILD_DIR/$PLUGIN_NAME"
mkdir -p "$DIST_DIR"

# Copy plugin files
echo "📋 Copying plugin files..."
cp -r src "$BUILD_DIR/$PLUGIN_NAME/"
cp Info.lua "$BUILD_DIR/$PLUGIN_NAME/"
cp PluginInfoProvider.lua "$BUILD_DIR/$PLUGIN_NAME/" 2>/dev/null || true
cp MetadataDefinition.lua "$BUILD_DIR/$PLUGIN_NAME/" 2>/dev/null || true
cp -r node-bridge "$BUILD_DIR/$PLUGIN_NAME/" 2>/dev/null || true

# Copy models (exclude large model files)
echo "🤖 Copying model configurations..."
mkdir -p "$BUILD_DIR/$PLUGIN_NAME/models"
cp -r src/models/configs "$BUILD_DIR/$PLUGIN_NAME/models/" 2>/dev/null || true

# Create version file
echo "VERSION=${VERSION}" > "$BUILD_DIR/$PLUGIN_NAME/version.txt"
echo "BUILD_DATE=$(date +%Y-%m-%d)" >> "$BUILD_DIR/$PLUGIN_NAME/version.txt"
echo "BUILD_NUMBER=$(git rev-parse --short HEAD 2>/dev/null || echo 'dev')" >> "$BUILD_DIR/$PLUGIN_NAME/version.txt"

# Package the plugin
echo "📦 Creating plugin package..."
cd "$BUILD_DIR"
zip -r "../$DIST_DIR/${PLUGIN_NAME%.lrplugin}-${VERSION}.zip" "$PLUGIN_NAME" -x "*.DS_Store" "*.git*"
cd ..

# Create installer script
cat > "$DIST_DIR/install.sh" << 'EOF'
#!/bin/bash
LIGHTROOM_PLUGINS="$HOME/Library/Application Support/Adobe/Lightroom/Modules"
if [ -d "$LIGHTROOM_PLUGINS" ]; then
    unzip -o *.zip -d "$LIGHTROOM_PLUGINS"
    echo "✅ Plugin installed successfully!"
    echo "Please restart Lightroom Classic to load the plugin."
else
    echo "❌ Lightroom plugins directory not found."
    echo "Please install manually to your Lightroom Modules folder."
fi
EOF

chmod +x "$DIST_DIR/install.sh"

echo "✅ Build complete!"
echo "📍 Plugin package: $DIST_DIR/${PLUGIN_NAME%.lrplugin}-${VERSION}.zip"
echo ""
echo "To install:"
echo "1. Run: cd $DIST_DIR && ./install.sh"
echo "2. Or manually copy $BUILD_DIR/$PLUGIN_NAME to Lightroom Modules folder"