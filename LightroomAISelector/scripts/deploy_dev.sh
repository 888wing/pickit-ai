#!/bin/bash

# Development deployment script
# Deploys plugin to Lightroom for testing

PLUGIN_NAME="LightroomAISelector.lrplugin"
LIGHTROOM_PLUGINS="$HOME/Library/Application Support/Adobe/Lightroom/Modules"
SOURCE_DIR="$(dirname $(dirname $(realpath $0)))"

echo "🔧 Deploying plugin for development..."

# Check if Lightroom plugins directory exists
if [ ! -d "$LIGHTROOM_PLUGINS" ]; then
    echo "❌ Lightroom plugins directory not found at: $LIGHTROOM_PLUGINS"
    echo "Creating directory..."
    mkdir -p "$LIGHTROOM_PLUGINS"
fi

# Remove existing plugin
if [ -d "$LIGHTROOM_PLUGINS/$PLUGIN_NAME" ]; then
    echo "🗑️  Removing existing plugin..."
    rm -rf "$LIGHTROOM_PLUGINS/$PLUGIN_NAME"
fi

# Create symlink for development (faster updates)
echo "🔗 Creating symlink to development folder..."
ln -s "$SOURCE_DIR" "$LIGHTROOM_PLUGINS/$PLUGIN_NAME"

echo "✅ Development deployment complete!"
echo "📍 Plugin linked from: $SOURCE_DIR"
echo "📍 Plugin linked to: $LIGHTROOM_PLUGINS/$PLUGIN_NAME"
echo ""
echo "⚠️  Please restart Lightroom Classic to reload the plugin."
echo "💡 Tip: Enable Plugin Manager reload for faster development."