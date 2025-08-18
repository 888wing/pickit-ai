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
