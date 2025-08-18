#!/bin/bash

# Pickit - Lightroom Classic Plugin Installation Script
# This script automates the installation process

echo "======================================"
echo "   Pickit AI - Lightroom Plugin"
echo "   Automated Installation Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check operating system
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    print_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Step 1: Check Node.js installation
echo "Step 1: Checking Node.js installation..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    print_success "Node.js is installed: $NODE_VERSION"
else
    print_error "Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi
echo ""

# Step 2: Install dependencies
echo "Step 2: Installing dependencies..."
cd LightroomAISelector/node-bridge || exit

if [ -f "package.json" ]; then
    npm install
    if [ $? -eq 0 ]; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
else
    print_error "package.json not found"
    exit 1
fi
echo ""

# Step 3: Download AI models
echo "Step 3: Downloading AI models..."
if [ -f "scripts/download-models.js" ]; then
    npm run install-models
    if [ $? -eq 0 ]; then
        print_success "AI models downloaded successfully"
    else
        print_warning "Failed to download some models, but continuing..."
    fi
else
    print_warning "Model download script not found, skipping..."
fi
echo ""

# Step 4: Setup credentials (optional)
echo "Step 4: Setting up Google Sheets API (optional)..."
if [ ! -f "credentials.json" ] && [ -f "credentials.example.json" ]; then
    echo "Would you like to set up Google Sheets feedback? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        cp credentials.example.json credentials.json
        print_warning "Please edit credentials.json with your Google Cloud credentials"
        print_warning "See GOOGLE_SHEETS_SETUP.md for instructions"
    else
        print_success "Skipping Google Sheets setup"
    fi
else
    if [ -f "credentials.json" ]; then
        print_success "Credentials already configured"
    else
        print_success "Skipping Google Sheets setup"
    fi
fi
echo ""

# Step 5: Install Lightroom plugin
echo "Step 5: Installing Lightroom plugin..."

if [ "$OS" == "macos" ]; then
    LIGHTROOM_DIR="$HOME/Library/Application Support/Adobe/Lightroom/Modules"
else
    LIGHTROOM_DIR="$APPDATA/Adobe/Lightroom/Modules"
fi

echo "Would you like to install the plugin to Lightroom? (y/n)"
echo "Plugin will be copied to: $LIGHTROOM_DIR"
read -r response

if [[ "$response" == "y" ]]; then
    # Create directory if it doesn't exist
    mkdir -p "$LIGHTROOM_DIR"
    
    # Copy plugin
    cp -r ../../LightroomAISelector "$LIGHTROOM_DIR/"
    
    if [ $? -eq 0 ]; then
        print_success "Plugin copied to Lightroom directory"
    else
        print_error "Failed to copy plugin"
        echo "Please manually add the plugin through Lightroom's Plugin Manager"
    fi
else
    echo ""
    print_warning "Manual installation required:"
    echo "1. Open Lightroom Classic"
    echo "2. Go to File → Plug-in Manager"
    echo "3. Click 'Add' and select the 'LightroomAISelector' folder"
fi
echo ""

# Step 6: Start the server
echo "Step 6: Starting the Node.js server..."
echo ""
print_warning "The server needs to run continuously for the plugin to work"
echo "Would you like to start the server now? (y/n)"
read -r response

if [[ "$response" == "y" ]]; then
    echo ""
    print_success "Starting server..."
    print_warning "Keep this terminal window open!"
    echo ""
    echo "----------------------------------------"
    echo "Server output:"
    echo "----------------------------------------"
    npm start
else
    echo ""
    print_warning "To start the server later, run:"
    echo "  cd LightroomAISelector/node-bridge"
    echo "  npm start"
fi

echo ""
echo "======================================"
print_success "Installation Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Make sure the Node.js server is running (npm start)"
echo "2. Open Lightroom Classic"
echo "3. Enable the plugin in File → Plug-in Manager"
echo "4. Select photos and right-click → Pickit → Analyze"
echo ""
echo "For detailed instructions, see INSTALLATION_GUIDE.md"
echo ""
print_success "Happy photo selection! 📸"