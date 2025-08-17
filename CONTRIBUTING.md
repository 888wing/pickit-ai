# Contributing to Pickit

First off, thank you for considering contributing to Pickit! It's people like you that make Pickit such a great tool for photographers worldwide.

## 🤝 Code of Conduct

This project and everyone participating in it is governed by the [Pickit Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [conduct@pickit.ai](mailto:conduct@pickit.ai).

## 🎯 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

**Bug Report Template:**
- **Environment:** OS, Lightroom version, Node.js version
- **Description:** Clear and concise description of the bug
- **Steps to Reproduce:** Step-by-step instructions to reproduce
- **Expected Behavior:** What you expected to happen
- **Actual Behavior:** What actually happened
- **Screenshots:** If applicable, add screenshots
- **Additional Context:** Any other relevant information

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use Case:** Explain the problem you're trying to solve
- **Proposed Solution:** Describe your ideal solution
- **Alternatives:** List any alternative solutions you've considered
- **Additional Context:** Add any mockups, examples, or references

### Your First Code Contribution

Unsure where to begin? You can start by looking through these beginner and help-wanted issues:

- `good first issue` - issues which should only require a few lines of code
- `help wanted` - issues which should be a bit more involved than beginner issues

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the existing code style
6. Issue that pull request!

## 📝 Development Process

### Setting Up Your Development Environment

```bash
# Clone your fork
git clone https://github.com/your-username/pickit-lightroom.git
cd pickit-lightroom

# Add upstream remote
git remote add upstream https://github.com/pickit-ai/pickit-lightroom.git

# Install dependencies
cd node-bridge
npm install

# Download AI models
npm run install-models

# Run tests
npm test

# Start development server
npm run dev
```

### Project Structure

```
pickit-lightroom/
├── LightroomPlugin.lrdevplugin/  # Lightroom plugin (Lua)
│   ├── Info.lua                  # Plugin metadata
│   ├── Main.lua                  # Entry point
│   ├── modules/                  # Plugin modules
│   │   ├── AISelector.lua        # AI selection logic
│   │   ├── PhotoAnalyzer.lua     # Photo analysis
│   │   └── UIManager.lua         # UI components
├── node-bridge/                  # Node.js bridge server
│   ├── server.js                 # Express server
│   ├── ai/                       # AI processing
│   │   ├── nima.js              # NIMA scoring
│   │   ├── face.js              # Face detection
│   │   └── similarity.js        # Photo grouping
│   └── models/                   # ONNX models
├── test/                         # Test suites
│   ├── unit/                     # Unit tests
│   ├── integration/              # Integration tests
│   └── fixtures/                 # Test data
└── docs/                         # Documentation
```

### Coding Standards

#### Lua (Lightroom Plugin)

```lua
-- Use descriptive variable names
local photoQualityThreshold = 0.75  -- Good
local pqt = 0.75                    -- Bad

-- Add comments for complex logic
-- Calculate weighted average of aesthetic and technical scores
local finalScore = (aestheticScore * 0.6) + (technicalScore * 0.4)

-- Use consistent indentation (2 spaces)
function processPhoto(photo)
  if photo then
    -- Process the photo
    return analyzePhoto(photo)
  end
  return nil
end
```

#### JavaScript (Node Bridge)

```javascript
// Use ES6+ features
const processPhotos = async (photos) => {
  const results = await Promise.all(
    photos.map(photo => analyzePhoto(photo))
  );
  return results;
};

// Use JSDoc comments
/**
 * Analyzes a photo using NIMA models
 * @param {string} photoPath - Path to the photo file
 * @returns {Promise<Object>} Analysis results
 */
async function analyzePhoto(photoPath) {
  // Implementation
}

// Handle errors properly
try {
  const result = await riskyOperation();
} catch (error) {
  logger.error('Operation failed:', error);
  throw new ProcessingError('Failed to process photo', { cause: error });
}
```

### Testing

#### Running Tests

```bash
# Run all tests
npm test

# Run unit tests only
npm run test:unit

# Run integration tests
npm run test:integration

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- --grep "PhotoAnalyzer"
```

#### Writing Tests

```javascript
// test/unit/photoAnalyzer.test.js
describe('PhotoAnalyzer', () => {
  describe('analyzePhoto', () => {
    it('should return scores for valid photo', async () => {
      const result = await analyzePhoto('test/fixtures/sample.jpg');
      expect(result).to.have.property('aesthetic');
      expect(result).to.have.property('technical');
      expect(result.aesthetic).to.be.within(0, 1);
    });

    it('should handle invalid photo path', async () => {
      await expect(analyzePhoto('invalid.jpg'))
        .to.be.rejectedWith('File not found');
    });
  });
});
```

### Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `test`: Adding missing tests
- `chore`: Changes to build process or auxiliary tools

**Examples:**
```
feat(ai): add support for RAW file analysis

fix(ui): correct score display rounding issue

docs(readme): update installation instructions for Windows

perf(batch): optimize batch processing for large collections
```

## 🔄 Release Process

1. **Version Bump:** Update version in `package.json` and `Info.lua`
2. **Changelog:** Update CHANGELOG.md with release notes
3. **Testing:** Run full test suite
4. **Tag:** Create git tag with version number
5. **Release:** GitHub Actions will automatically create release

## 📚 Documentation

### Code Documentation

- All public APIs must be documented
- Include examples for complex functionality
- Keep README.md up to date with any changes

### API Documentation

```lua
--- Analyzes a photo and returns quality scores
-- @param photo LrPhoto object to analyze
-- @param options table Optional configuration
-- @return table Contains aesthetic and technical scores
function AISelector.analyzePhoto(photo, options)
  -- Implementation
end
```

## 🌍 Translation

Help us make Pickit available in more languages:

1. Copy `locales/en.json` to `locales/[language-code].json`
2. Translate all strings
3. Update `LANGUAGES.md` with your language
4. Submit a pull request

## 💡 Community

### Getting Help

- **Discord:** [Join our community](https://discord.gg/pickit)
- **GitHub Discussions:** For general questions and discussions
- **Stack Overflow:** Tag your questions with `pickit-lightroom`

### Recognition

Contributors who make significant contributions will be:
- Added to the CONTRIBUTORS.md file
- Mentioned in release notes
- Given credit in the application

## 📜 License

By contributing to Pickit, you agree that your contributions will be licensed under its MIT license.

## 🙏 Thank You!

Your contributions to open source, no matter how small, make projects like this possible. Thank you for taking the time to contribute!