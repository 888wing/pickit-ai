# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Pickit project - a Lightroom Classic plugin for intelligent photo selection using AI. The plugin helps photographers automatically identify and select high-quality photos from large batches using AI models and traditional computer vision algorithms.

## Critical Development Guidelines

### 1. TODO.md Compliance
**MANDATORY**: Always check and follow `/Users/chuisiufai/Desktop/Pickit/TODO.md` for the current development tasks and priorities. The TODO.md contains a detailed work breakdown structure with specific task codes (e.g., WK1-001, WK3-005) that must be followed sequentially.

**Task Tracking Requirements**:
- Before starting any development, review the current week's tasks in TODO.md
- Update task status after completion
- Never skip tasks unless explicitly marked as optional (P2)
- Follow the milestone checkpoints defined in the TODO.md

### 2. CODEGuide.md Compliance  
**MANDATORY**: All code must strictly follow `/Users/chuisiufai/Desktop/Pickit/CODEGuide.md` for:
- File naming conventions (PascalCase for Lua files)
- Variable naming (camelCase for local, UPPER_CASE for constants)
- Module structure templates
- Error handling patterns with specific error codes
- UI/UX flow specifications

### 3. Recurring Error Prevention

**Error Tracking System**: When encountering errors during development:
1. Document the error in a dedicated error log section
2. Create a prevention strategy before attempting fixes
3. Test the fix against the documented error pattern
4. Update the error prevention checklist

**Common Error Patterns to Monitor**:
- Model loading failures → Check ONNX Runtime configuration
- Memory issues → Implement cache cleanup as per CODEGuide.md section 7.2
- API rate limits → Use retry mechanism with exponential backoff (CODEGuide.md section 2.2)
- UI freezing → Follow async patterns for batch processing

## Development Environment Setup

### Prerequisites
- Lightroom Classic 12.0+
- Lua development environment (VS Code with Lua plugin)
- ONNX Runtime for AI model inference
- Node.js for bridge layer between Lua and ONNX

### Project Structure
```
LightroomAISelector/
├── src/
│   ├── core/               # Core functionality (AIEngine.lua, PhotoScorer.lua)
│   ├── models/             # AI model integration (ONNXBridge.lua)
│   ├── ui/                 # User interface (MainDialog.lua)
│   ├── utils/              # Utilities (Logger.lua, FileHelper.lua)
│   ├── api/                # Cloud API integration
│   └── analytics/          # Data analysis and tracking
```

## Key Development Tasks

### Phase 1: MVP Development (Weeks 1-8)
Focus on local AI processing with NIMA model integration, basic UI, and batch processing capabilities.

### Phase 2: Advanced API Version (Weeks 9-14)
Add cloud services, personalized learning, and enterprise features.

## Core Commands

### Development
```bash
# Initialize project structure (as per WK1-004)
mkdir -p src/{core,models,ui,utils,api,analytics}

# Run tests (when implemented as per WK2-007)
lua test/run_tests.lua

# Build plugin package (as per WK8-014)
./scripts/build_plugin.sh

# Deploy to Lightroom (development)
./scripts/deploy_dev.sh
```

### Testing
```bash
# Unit tests
lua test/unit/run_all.lua

# Integration tests  
lua test/integration/run_all.lua

# Performance benchmarks (as per WK4-009)
lua test/performance/benchmark.lua
```

## Architecture Overview

### Core Components

1. **AI Engine**: Manages model loading and inference using ONNX Runtime
   - Local models: NIMA for quality assessment, MediaPipe for face detection
   - Cloud models: CLIP for aesthetic analysis (Phase 2)

2. **Photo Scorer**: Implements scoring algorithms combining technical and aesthetic metrics
   - Technical: Blur detection, exposure analysis, color saturation
   - Aesthetic: Composition, emotional impact (Phase 2)

3. **Batch Processor**: Handles parallel processing of photo collections
   - Queue management with configurable batch sizes
   - Progress tracking and cancellation support

4. **UI System**: Lightroom SDK dialog components
   - Main dialog for batch operations
   - Settings panel for threshold adjustments
   - Results viewer with filtering capabilities

### Data Flow
1. User selects photos in Lightroom
2. Plugin performs quick technical filtering (blur, exposure)
3. AI models evaluate remaining photos
4. Results are grouped to remove duplicates
5. Final selections are marked in Lightroom catalog

## Error Handling Strategy

### Prevention First Approach
1. **Input Validation**: All photo inputs validated before processing
2. **Resource Monitoring**: Memory usage tracked with automatic cleanup triggers
3. **Graceful Degradation**: Falls back to local processing if cloud unavailable
4. **Recovery Mechanisms**: Auto-save progress for crash recovery

### Error Code System (from CODEGuide.md)
- 1xxx: System errors
- 2xxx: Model errors  
- 3xxx: API errors
- 4xxx: User input errors

## Performance Targets

- Batch processing: >100 photos/minute on standard laptop
- Memory usage: <500MB
- Plugin size: <50MB
- Model inference: <100ms per photo (CPU)

## Quality Standards

### Code Quality
- Follow module structure template in CODEGuide.md section 2.1
- Implement comprehensive error handling for all external operations
- Add logging for debugging (using Logger.lua utility)
- Write unit tests for all core functions

### UI/UX Standards  
- Loading states must show progress percentage
- All long operations must be cancellable
- Error messages must provide actionable solutions
- Settings changes apply immediately with preview

## Testing Requirements

### Test Coverage Targets
- Core functionality: 90% coverage
- UI interactions: Manual testing checklist
- Performance: Must meet targets under stress (1000+ photos)
- Error scenarios: All error codes must have test cases

## Security Considerations

- API keys stored encrypted in preferences (never hardcoded)
- Local processing by default for privacy
- Cloud uploads only with explicit user consent
- Input sanitization for all user data

## Development Workflow

1. **Planning**: Check TODO.md for current sprint tasks
2. **Implementation**: Follow CODEGuide.md patterns
3. **Testing**: Run unit tests before committing
4. **Documentation**: Update inline comments and API docs
5. **Review**: Validate against PRD.md requirements
6. **Deployment**: Use build scripts for packaging

## Common Pitfalls to Avoid

1. **Don't skip error handling** - Every external operation needs try-catch
2. **Don't process all photos at once** - Use batching to prevent memory issues
3. **Don't block UI thread** - Use async patterns for long operations
4. **Don't ignore performance** - Profile regularly, especially with large batches
5. **Don't deviate from TODO.md** - Tasks are sequenced for dependencies

## Support and Resources

- Lightroom SDK Docs: [Adobe Developer Portal]
- ONNX Runtime: [Microsoft ONNX Documentation]
- MediaPipe: [Google MediaPipe Docs]
- Project PRD: See PRD.md for detailed requirements
- Coding Standards: See CODEGuide.md for detailed conventions
- Task List: See TODO.md for current development priorities