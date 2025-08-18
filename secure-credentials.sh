#!/bin/bash

# Security Script: Move credentials to secure location
# Run this script to secure your credentials

echo "🔒 Pickit Security Setup Script"
echo "================================"
echo ""

# Define paths
PROJECT_DIR="/Users/chuisiufai/Desktop/Pickit"
CREDENTIALS_FILE="$PROJECT_DIR/LightroomAISelector/node-bridge/credentials.json"
SECURE_DIR="$HOME/.pickit-secure"
SECURE_CREDENTIALS="$SECURE_DIR/credentials.json"
ENV_FILE="$PROJECT_DIR/LightroomAISelector/node-bridge/.env"

# Check if credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "✅ No credentials.json found in project directory (already secure)"
    exit 0
fi

echo "⚠️  Found credentials.json in project directory"
echo ""

# Create secure directory
echo "Creating secure directory at $SECURE_DIR..."
mkdir -p "$SECURE_DIR"
chmod 700 "$SECURE_DIR"

# Move credentials
echo "Moving credentials to secure location..."
mv "$CREDENTIALS_FILE" "$SECURE_CREDENTIALS"
chmod 600 "$SECURE_CREDENTIALS"

echo "✅ Credentials moved to: $SECURE_CREDENTIALS"
echo ""

# Create .env file
echo "Creating .env file with secure path..."
cat > "$ENV_FILE" << EOF
# Google Cloud Credentials Path
GOOGLE_APPLICATION_CREDENTIALS=$SECURE_CREDENTIALS

# Node Environment
NODE_ENV=development

# Server Port
PORT=3001
EOF

echo "✅ Created .env file"
echo ""

# Update the Node.js server to use environment variable
echo "Updating server configuration..."
cat > "$PROJECT_DIR/LightroomAISelector/node-bridge/src/auth-config.js" << 'EOF'
// Authentication Configuration
const path = require('path');

// Use environment variable or fallback to local file for development
const getCredentialsPath = () => {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return process.env.GOOGLE_APPLICATION_CREDENTIALS;
  }
  
  // Fallback for development (credentials.json in project)
  const localPath = path.join(__dirname, '..', 'credentials.json');
  if (require('fs').existsSync(localPath)) {
    console.warn('⚠️  Using local credentials.json - not recommended for production');
    return localPath;
  }
  
  throw new Error('No Google Cloud credentials found. Please set GOOGLE_APPLICATION_CREDENTIALS environment variable.');
};

module.exports = {
  credentialsPath: getCredentialsPath()
};
EOF

echo "✅ Server configuration updated"
echo ""

# Final instructions
echo "🎉 Security setup complete!"
echo ""
echo "IMPORTANT NOTES:"
echo "1. Your credentials are now stored securely at: $SECURE_CREDENTIALS"
echo "2. The .env file points to this secure location"
echo "3. The original credentials.json has been removed from the project"
echo ""
echo "⚠️  RECOMMENDED ACTIONS:"
echo "1. Go to Google Cloud Console and rotate your service account keys"
echo "2. Delete the old key that might have been exposed"
echo "3. Download new key and place at: $SECURE_CREDENTIALS"
echo ""
echo "To start the server:"
echo "  cd $PROJECT_DIR/LightroomAISelector/node-bridge"
echo "  npm start"
echo ""
echo "The server will automatically load credentials from the secure location."