# Contributing Guidelines

Thank you for your interest in contributing to the 3D Spatial Audio Mixer project! This document provides guidelines for contributing to the project effectively.

## Table of Contents
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Contribution Workflow](#contribution-workflow)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Issue Reporting](#issue-reporting)

## Getting Started

### Prerequisites for Contributors
- **Processing 4.x** development environment
- **Basic understanding** of Java/Processing syntax
- **Familiarity** with object-oriented programming
- **Knowledge** of audio concepts (helpful but not required)
- **Git** version control system (if using version control)

### Development Environment Setup
1. **Follow the installation guide** to set up the basic system
2. **Install additional development tools**:
   - Text editor with syntax highlighting (VS Code, Sublime, etc.)
   - OSC debugging tools (OSCeleton, OSC Monitor)
   - MIDI monitoring software (MIDI-OX for Windows, MIDI Monitor for macOS)

3. **Set up testing environment**:
   - Configure hardware simulators
   - Set up network testing environment
   - Install audio testing applications

## Development Setup

### Project Structure Understanding

Before contributing, familiarize yourself with the project architecture:

```
spatial_mixer/
├── spatial_mixer.pde          # Main application - handles setup, events, OSC
├── VisualizationManager.pde   # 3D/2D rendering system
├── UIManager.pde              # Custom UI controls and layout
├── TrackManager.pde           # Audio track controls
├── SourceManager.pde          # Source type management
├── SoundSource.pde            # Core audio source class
├── MidiMappingManager.pde     # MIDI integration layer
├── OscHelper.pde              # OSC communication wrapper
├── CubeRenderer.pde           # 3D cube visualization
├── CentralHead.pde            # Head tracking visualization
├── CustomSlider.pde           # UI slider component
├── SliderManager.pde          # Slider collection management
├── LayoutManager.pde          # Responsive layout system
├── Rectangle.pde              # Utility geometry class
├── data/
│   └── midi_mapping.json      # MIDI controller configuration
└── simulators/                # Hardware simulation scripts
```

### Key Design Principles

1. **Modular Architecture**: Each component has a specific responsibility
2. **Event-Driven Design**: User input, MIDI, and OSC events drive state changes
3. **Real-time Performance**: All operations must maintain smooth frame rates
4. **Hardware Abstraction**: Support multiple MIDI controllers and OSC endpoints
5. **Responsive UI**: Interface adapts to different screen sizes and modes

## Coding Standards

### Processing/Java Conventions

#### Naming Conventions
```java
// Classes: PascalCase
class VisualizationManager {
    
// Methods and variables: camelCase
void updatePosition() {
    float sourceRadius = 150.0;
    
// Constants: UPPER_SNAKE_CASE
final int MAX_SOURCES = 7;
final float DEFAULT_RADIUS = 150.0;

// Private members: prefix with underscore (optional)
private Rectangle _container;
```

#### Code Organization
```java
class ExampleClass {
    // 1. Constants
    final int MAX_VALUE = 100;
    
    // 2. Public properties
    float publicValue;
    
    // 3. Private properties
    private float _privateValue;
    
    // 4. Constructor
    ExampleClass(float value) {
        this.publicValue = value;
    }
    
    // 5. Public methods
    void publicMethod() {
        // Implementation
    }
    
    // 6. Private methods
    private void privateMethod() {
        // Implementation
    }
}
```

#### Documentation Standards
```java
/**
 * Brief description of the class or method
 * 
 * Longer description if needed, explaining purpose,
 * usage patterns, or important implementation details.
 * 
 * @param paramName Description of parameter
 * @return Description of return value
 */
void exampleMethod(float paramName) {
    // Implementation with inline comments for complex logic
    float calculatedValue = complexCalculation(paramName); // Explain why this calculation
}
```

### Specific Conventions for This Project

#### Coordinate System Documentation
Always document coordinate systems used:
```java
/**
 * Convert spherical to cartesian coordinates
 * Coordinate system: Y-up, right-handed
 * Azimuth: 0° = +Z (into screen), 90° = +X (right)
 * Zenith: -90° = down, 0° = horizontal, +90° = up
 */
void updatePosition() {
    x = radius * cos(zenith) * sin(azimuth);
    y = radius * sin(zenith);
    z = radius * cos(zenith) * cos(azimuth);
}
```

#### OSC Message Documentation
Document OSC message formats:
```java
/**
 * Send position update via OSC
 * Message format: /track/{trackNum}/radius {float 0-1}
 * Value range: 0-1 (mapped from radius 50-400)
 */
void sendPositionUpdate(int trackNum, float radius) {
    float normalizedRadius = map(radius, 50, 400, 0, 1);
    oscHelper.sendOscMessage("/track/" + trackNum + "/radius", normalizedRadius);
}
```

#### Error Handling
Use defensive programming practices:
```java
void updateSource(int sourceIndex, float value) {
    // Always validate array bounds
    if (sourceIndex < 0 || sourceIndex >= soundSources.size()) {
        println("ERROR: Invalid source index: " + sourceIndex);
        return;
    }
    
    // Validate input ranges
    float constrainedValue = constrain(value, 0, 1);
    if (value != constrainedValue) {
        println("WARNING: Value " + value + " constrained to " + constrainedValue);
    }
    
    soundSources.get(sourceIndex).setVolume(constrainedValue);
}
```

## Contribution Workflow

### Types of Contributions

#### Bug Fixes
- **Small fixes**: Typos, minor logic errors, UI glitches
- **Medium fixes**: Incorrect calculations, performance issues
- **Large fixes**: Architecture problems, major functionality issues

#### Feature Additions
- **UI improvements**: New controls, better layouts, visual enhancements
- **Hardware support**: New MIDI controllers, OSC endpoints
- **Audio features**: New source types, positioning algorithms
- **Integration**: External software connections, file format support

#### Documentation
- **Code comments**: Inline documentation for complex algorithms
- **User guides**: Tutorial content, usage examples
- **API documentation**: Reference material for developers
- **Setup guides**: Installation, configuration instructions

### Contribution Process

1. **Identify the change needed**:
   - Review existing issues or create new issue
   - Discuss approach with maintainers if significant change
   - Ensure change aligns with project goals

2. **Plan the implementation**:
   - Break down into smaller, testable components
   - Consider impact on existing functionality
   - Plan testing approach

3. **Implement the changes**:
   - Follow coding standards outlined above
   - Write clear, well-commented code
   - Test thoroughly during development

4. **Test the implementation**:
   - Verify core functionality still works
   - Test new features with various inputs
   - Test on different platforms if possible
   - Use hardware simulators for testing

5. **Document the changes**:
   - Update inline code comments
   - Update user documentation if needed
   - Update API documentation for interface changes
   - Add examples for new features

6. **Submit the contribution**:
   - Create clear description of changes
   - Include testing notes
   - Reference any related issues
   - Be prepared to address feedback

## Testing Guidelines

### Manual Testing Requirements

#### Core Functionality Tests
Before submitting contributions, verify:

1. **Application Startup**:
   - [ ] Loads without errors
   - [ ] All UI elements render correctly
   - [ ] Default sources appear in expected positions

2. **Basic Interaction**:
   - [ ] Source selection with number keys works
   - [ ] Sliders respond to mouse input
   - [ ] View mode toggle (V key) functions
   - [ ] Rotation reset (R key) works

3. **Advanced Features**:
   - [ ] MIDI integration (if modified)
   - [ ] OSC communication (if modified)
   - [ ] Source type changes (M/A/S keys)
   - [ ] Performance maintains acceptable frame rate

#### Platform Testing
Test on multiple platforms when possible:
- **Windows 10/11**
- **macOS** (Intel and Apple Silicon if available)
- **Linux** (Ubuntu or similar)

#### Hardware Testing
If modifying hardware integration:
- **Test with simulators** first
- **Test with actual hardware** if available
- **Verify backward compatibility** with existing configurations

### Automated Testing Considerations

While this Processing project doesn't have formal unit tests, consider:

#### Validation Functions
Create validation functions for critical calculations:
```java
/**
 * Validate spherical to cartesian conversion
 * Returns true if conversion is mathematically correct
 */
boolean validateSphericalConversion(float radius, float azimuth, float zenith) {
    SoundSource testSource = new SoundSource(radius, azimuth, zenith);
    float calculatedRadius = sqrt(testSource.x*testSource.x + 
                                 testSource.y*testSource.y + 
                                 testSource.z*testSource.z);
    return abs(calculatedRadius - radius) < 0.001;
}
```

#### Test Data
Include test data for verification:
```java
// Test cases for boundary conditions
void testBoundaryConditions() {
    // Test minimum radius
    SoundSource minSource = new SoundSource(50, 0, 0);
    assert(minSource.radius == 50);
    
    // Test maximum radius
    SoundSource maxSource = new SoundSource(400, 0, 0);
    assert(maxSource.radius == 400);
    
    // Test angle ranges
    SoundSource angleSource = new SoundSource(150, TWO_PI, PI/2);
    assert(angleSource.azimuth <= TWO_PI);
    assert(angleSource.zenith <= PI/2);
}
```

## Documentation Standards

### Code Documentation

#### Class Documentation
```java
/**
 * Manages 3D and 2D visualization modes for spatial audio sources
 * 
 * This class coordinates between View3D and View2D to provide seamless
 * switching between visualization modes. It handles mouse interaction,
 * camera control, and rendering coordination.
 * 
 * Key responsibilities:
 * - Mode switching between 3D and 2D views
 * - Mouse-based camera control in 3D mode
 * - Rendering coordination and viewport management
 * - Background rendering and container management
 * 
 * Usage:
 *   VisualizationManager vm = new VisualizationManager(800, 30);
 *   vm.setContainer(layoutManager.mainViewArea);
 *   vm.draw(soundSources, selectedSource);
 */
class VisualizationManager {
```

#### Method Documentation
```java
/**
 * Updates source position from cartesian coordinates
 * 
 * This method converts cartesian coordinates back to spherical
 * coordinates, which are used internally for position control.
 * The conversion handles the coordinate system mapping where
 * Y is up, and the azimuth angle follows audio conventions.
 * 
 * @param xCoord X position in 3D space (-boundarySize/2 to +boundarySize/2)
 * @param yCoord Y position in 3D space (-boundarySize/2 to +boundarySize/2)
 * @param zCoord Z position in 3D space (-boundarySize/2 to +boundarySize/2)
 */
void updateFromCartesian(float xCoord, float yCoord, float zCoord) {
```

### User Documentation

#### Feature Documentation
When adding new features, include:
- **Purpose**: Why the feature exists
- **Usage**: How to use the feature
- **Limitations**: What the feature doesn't do
- **Examples**: Practical usage examples

#### Configuration Documentation
Document new configuration options:
```markdown
### New Configuration Option

**Parameter**: `maxSources`
**Type**: Integer
**Range**: 1-16
**Default**: 7
**Purpose**: Maximum number of audio sources supported
**Location**: Line 42 in spatial_mixer.pde

```java
final int MAX_SOURCES = 7; // Change this value to support more sources
```

**Note**: Increasing this value may impact performance on slower systems.
```

## Issue Reporting

### Bug Reports

When reporting bugs, include:

1. **System Information**:
   - Operating system and version
   - Processing version
   - Library versions (ControlP5, oscP5, MidiBus)

2. **Steps to Reproduce**:
   - Exact sequence of actions
   - Input values used
   - Expected vs. actual behavior

3. **Additional Information**:
   - Console error messages
   - Screenshot or video if visual issue
   - Hardware configuration (if relevant)

### Feature Requests

When requesting features, include:

1. **Use Case**: Why is this feature needed?
2. **Description**: What should the feature do?
3. **Implementation Ideas**: Suggestions for how it could work
4. **Priority**: How important is this feature?

### Example Bug Report
```markdown
**Bug**: Source disappears when radius set to maximum

**System**: Windows 11, Processing 4.2, ControlP5 2.2.6

**Steps to Reproduce**:
1. Start application
2. Select source 1 (press '1' key)
3. Move radius slider to maximum value (400)
4. Source disappears from 3D view

**Expected**: Source should be visible at edge of boundary cube
**Actual**: Source is not visible in any view mode

**Console Output**:
```
Updating position for source with radius: 400.0, azimuth: 0.0, zenith: 0.0
Updated from spherical - X: 0.0, Y: 0.0, Z: 400.0
```

**Additional Notes**: Issue occurs in both 3D and 2D views
```

## Best Practices for Contributors

### Development Workflow

1. **Start small**: Begin with minor improvements to understand the codebase
2. **Test thoroughly**: Always test your changes across different scenarios
3. **Document as you go**: Write documentation while the code is fresh in your mind
4. **Ask questions**: Don't hesitate to ask for clarification on design decisions
5. **Be patient**: Code review and discussion may take time

### Communication

1. **Be descriptive**: Clearly explain what you're trying to achieve
2. **Provide context**: Help others understand the motivation for changes
3. **Be open to feedback**: Code review helps improve the project
4. **Share knowledge**: Help others understand complex parts of the system

### Long-term Considerations

1. **Maintainability**: Write code that others can understand and modify
2. **Performance**: Consider the impact on real-time performance
3. **Compatibility**: Maintain compatibility with existing hardware and software
4. **Extensibility**: Design changes that allow for future expansion

---

*Thank you for contributing to the 3D Spatial Audio Mixer! Your contributions help make this tool better for everyone.*
