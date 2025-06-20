# API Documentation - Spatial Audio Mixer

This document provides detailed API reference for the Spatial Audio Mixer system components.

## Table of Contents
- [Core Classes](#core-classes)
- [OSC Message API](#osc-message-api)
- [MIDI Mapping API](#midi-mapping-api)
- [Event Handling](#event-handling)
- [Coordinate Systems](#coordinate-systems)
- [Extension Points](#extension-points)

## Core Classes

### SoundSource Class

Represents an individual audio source in 3D space.

#### Constructor
```java
SoundSource(float radius, float azimuth, float zenith)
```

#### Properties
| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `radius` | float | 50-400 | Distance from center |
| `azimuth` | float | 0-2π | Horizontal angle (radians) |
| `zenith` | float | -π/2-π/2 | Vertical angle (radians) |
| `x, y, z` | float | calculated | Cartesian coordinates |
| `volume` | float | 0-1 | Audio volume level |
| `vuLevel` | float | 0-1 | Real-time VU meter level |
| `type` | SourceType | enum | Source type (MONO_STEREO, AMBI, SEND) |
| `roll, yaw, pitch` | float | -π-π | Individual rotation parameters |

#### Key Methods
```java
void updatePosition()                           // Recalculate cartesian from spherical
void updateFromCartesian(float x, float y, float z)  // Update from cartesian coordinates
void setVolume(float volume)                    // Set audio volume (0-1)
void setSourceType(SourceType type)            // Change source type
void setRoll/Yaw/Pitch(float angle)           // Set rotation parameters
void display(boolean selected, int sourceNumber) // Render source in 3D
boolean isVisualizable()                        // Check if source should be rendered
```

#### Usage Example
```java
SoundSource source = new SoundSource(150, PI/4, 0);
source.setVolume(0.8);
source.setSourceType(SourceType.MONO_STEREO);
source.updatePosition();
```

### VisualizationManager Class

Manages 3D and 2D visualization modes.

#### Constructor
```java
VisualizationManager(float boundarySize, float headSize)
```

#### Key Methods
```java
void draw(ArrayList<SoundSource> sources, int selectedSource)  // Main rendering method
void toggleMode()                                              // Switch 3D/2D modes
void setRoll/Yaw/Pitch(float angle)                          // Set camera rotation
void resetRotation()                                          // Reset all rotations
void resetCubeRotation()                                      // Reset only cube rotation
boolean isMouseOverVisualization()                           // Check mouse interaction
void handleMousePressed/Dragged/Released()                   // Mouse event handling
```

#### View Mode Management
```java
String getCurrentMode()        // Returns "3D View" or "2D Views (Front/Top/Side)"
boolean is3DMode              // Current mode state
```

### UIManager Class

Handles custom UI controls and user interaction.

#### Constructor
```java
UIManager(ControlP5 cp5, int screenWidth, int screenHeight)
```

#### Slider Management
```java
void setupControls(float radius, float azimuth, float zenith, float boundarySize, String[] midiDevices)
void updateSliders(int selectedSource)                        // Update UI from source data
void updateSliderValue(String sliderName, float value)       // Update specific slider
void setSliderMode(int mode)                                  // Change slider visibility based on source type
```

#### Message Logging
```java
void logMessage(String message)                               // Add message to log
void scrollLog(int direction)                                 // Scroll log up/down
```

### TrackManager Class

Manages audio track controls and visualization.

#### Constructor
```java
TrackManager(ArrayList<Track> tracks, Track masterTrack)
```

#### Track Control
```java
void draw(int selectedSource)                                 // Render track controls
void updateTrackPositions()                                   // Update layout positions
Track getTrackAt(float x, float y)                          // Get track at screen position
void handleMousePressed/Dragged/Released()                   // Mouse interaction
```

## OSC Message API

### Incoming Messages (Received)

#### Track Control Messages
```
/track/{trackNum}/volume {float}     // Set track volume (0-1)
/track/{trackNum}/mute {int}         // Set mute state (0/1)
/track/{trackNum}/solo {int}         // Set solo state (0/1)
/track/{trackNum}/vu {float}         // Update VU meter (0-1)
```

#### Position Control Messages
```
/track/{trackNum}/radius {float}     // Set source radius (0-1, mapped to 50-400)
/track/{trackNum}/azimuth {float}    // Set azimuth (0-1, mapped to 0-2π)
/track/{trackNum}/zenith {float}     // Set zenith (0-1, mapped to -π/2-π/2)
```

#### Camera/Head Control Messages
```
/head/roll {float}                   // Set head roll rotation (-1 to 1, mapped to -π-π)
/head/pitch {float}                  // Set head pitch rotation
/head/yaw {float}                    // Set head yaw rotation
/cube/roll {float}                   // Set cube roll rotation
/cube/yaw {float}                    // Set cube yaw rotation  
/cube/pitch {float}                  // Set cube pitch rotation
```

### Outgoing Messages (Sent)

#### Position Updates
```
/track/{trackNum}/radius {float}     // Current radius (normalized 0-1)
/track/{trackNum}/azimuth {float}    // Current azimuth (normalized 0-1)
/track/{trackNum}/zenith {float}     // Current zenith (normalized 0-1)
```

#### Control Updates
```
/track/{trackNum}/volume {float}     // Current volume (0-1)
/track/{trackNum}/mute {int}         // Current mute state (0/1)
/track/{trackNum}/solo {int}         // Current solo state (0/1)
```

#### Ambisonic Control (for AMBI sources)
```
/track/{trackNum}/roll {float}       // Ambi mic roll rotation
/track/{trackNum}/yaw {float}        // Ambi mic yaw rotation
/track/{trackNum}/pitch {float}      // Ambi mic pitch rotation
```

### OSC Handler Registration

```java
// Register custom OSC handlers
oscHandlers.put("/custom/pattern", msg -> {
    // Handle custom OSC message
    float value = msg.get(0).floatValue();
    // Process message...
});
```

## MIDI Mapping API

### MIDI Mapping Structure

MIDI mappings are defined in `data/midi_mapping.json`:

```json
{
  "device_name": "Yamaha 02R96-1",
  "mappings": [
    {
      "type": "CC",
      "channel": 1,
      "controller": 7,
      "action": "setTrackVolume",
      "track": 1,
      "min": 0,
      "max": 127
    },
    {
      "type": "SysEx",
      "pattern": [240, 67, 16, 62, 18, 1, 0, 4],
      "action": "setPositionX",
      "description": "X Position Control"
    }
  ]
}
```

### MIDI Message Types

#### CC (Control Change) Messages
```java
class CCMapping {
    int channel;          // MIDI channel (1-16)
    int controller;       // CC number (0-127)
    String action;        // Action to perform
    int track;           // Target track number
    int min, max;        // Value range
}
```

#### SysEx (System Exclusive) Messages
```java
class SysExMapping {
    int[] pattern;       // SysEx pattern to match
    String action;       // Action to perform
    String description;  // Human-readable description
}
```

### Supported MIDI Actions

| Action | Description | Parameters |
|--------|-------------|------------|
| `setTrackVolume` | Set track volume | track, normalized value |
| `setMasterVolume` | Set master volume | normalized value |
| `toggleMute` | Toggle track mute | track, boolean state |
| `toggleSolo` | Toggle track solo | track, boolean state |
| `selectSource` | Select active source | source index |
| `setPositionX/Y/Z` | Set 3D position | coordinate value |
| `setZenith` | Set elevation angle | angle value |
| `updateSource` | Update source parameter | parameter, value |

### Custom MIDI Mapping

To add custom MIDI mappings:

1. **Edit** `data/midi_mapping.json`
2. **Add mapping entry** with appropriate type and parameters
3. **Implement handler** in `handleMidiMessage()` function
4. **Test** with MIDI controller or simulator

Example custom mapping:
```json
{
  "type": "CC",
  "channel": 1,
  "controller": 74,
  "action": "setCustomParameter",
  "track": 1,
  "min": 0,
  "max": 127
}
```

## Event Handling

### Mouse Events

```java
void mousePressed() {
    visualizationManager.handleMousePressed();
    uiManager.handleMousePressed();
    trackManager.handleMousePressed();
}

void mouseDragged() {
    visualizationManager.handleMouseDragged();
    trackManager.handleMouseDragged();
}

void mouseReleased() {
    visualizationManager.handleMouseReleased();
    trackManager.handleMouseReleased();
}
```

### Keyboard Events

```java
void keyPressed() {
    // Source selection (1-7)
    if (key >= '1' && key <= '9') {
        int sourceIndex = key - '1';
        selectSource(sourceIndex);
    }
    
    // View mode toggle (V)
    if (key == 'v' || key == 'V') {
        visualizationManager.toggleMode();
    }
    
    // Reset rotations (R)
    if (key == 'r' || key == 'R') {
        visualizationManager.resetRotation();
    }
    
    // Source type changes (M, A, S)
    if (key == 'm' || key == 'M') {
        sourceManager.changeSourceMode(selectedSource, 0); // Mono/Stereo
    }
}
```

### Window Events

```java
void windowResized() {
    layoutManager.updateLayout(width, height);
    uiManager.setContainer(layoutManager.uiControlsArea);
    visualizationManager.setContainer(layoutManager.mainViewArea);
    trackManager.setContainer(layoutManager.trackControlsArea);
}
```

## Coordinate Systems

### Spherical Coordinates
- **Radius**: Distance from origin (50-400 units)
- **Azimuth**: Horizontal angle, 0-2π radians
  - 0° = +Z direction (into screen)
  - 90° = +X direction (right)
  - 180° = -Z direction (out of screen)
  - 270° = -X direction (left)
- **Zenith**: Vertical angle, -π/2 to +π/2 radians
  - -π/2 = down
  - 0 = horizontal plane
  - +π/2 = up

### Cartesian Conversion
```java
// Spherical to Cartesian
x = radius * cos(zenith) * sin(azimuth)
y = radius * sin(zenith)
z = radius * cos(zenith) * cos(azimuth)

// Cartesian to Spherical
radius = sqrt(x² + y² + z²)
zenith = asin(y / radius)
azimuth = atan2(x, z)
```

### Coordinate System Orientation
- **X-axis**: Left (-) to Right (+)
- **Y-axis**: Down (-) to Up (+)
- **Z-axis**: Out of screen (-) to Into screen (+)
- **Right-handed coordinate system**

## Extension Points

### Adding New Source Types

1. **Extend SourceType enum** in `SoundSource.pde`:
```java
enum SourceType {
  MONO_STEREO,
  AMBI,
  SEND,
  CUSTOM_TYPE    // Add new type
}
```

2. **Update setSourceType method**:
```java
void setSourceType(int typeValue) {
    switch(typeValue) {
        case 3:
            this.type = SourceType.CUSTOM_TYPE;
            break;
    }
}
```

3. **Implement custom rendering** in `display()` method
4. **Add UI controls** in `UIManager`

### Adding Custom OSC Handlers

```java
// In setup() function
oscHandlers.put("/custom/message", msg -> {
    float value = msg.get(0).floatValue();
    // Custom handling logic
    processCustomMessage(value);
});

void processCustomMessage(float value) {
    // Implementation
}
```

### Custom MIDI Actions

1. **Add action to MIDI mapping JSON**
2. **Implement in handleMidiMessage()**:
```java
case "customAction":
    if (mapping instanceof CCMapping) {
        // Handle CC message
        processCustomAction(normalizedValue);
    }
    break;
```

### Custom UI Components

Extend the CustomSlider class or create new UI components:

```java
class CustomButton extends UIComponent {
    void draw() {
        // Custom rendering
    }
    
    boolean isMouseOver(float mouseX, float mouseY) {
        // Hit testing
    }
    
    void handleClick() {
        // Click handling
    }
}
```

### Layout Customization

Modify `LayoutManager` to add new UI areas:

```java
void updateLayout(int screenWidth, int screenHeight) {
    // Define custom layout areas
    customArea = new Rectangle(x, y, width, height);
}
```

## Performance Considerations

### Optimization Tips

1. **Limit position updates**: Only call `updatePosition()` when necessary
2. **Reduce rendering complexity**: Disable 3D mode for better performance
3. **Optimize OSC messages**: Batch messages where possible
4. **Memory management**: Reuse objects instead of creating new ones

### Profiling

Use Processing's built-in profiling:
```java
println("Frame rate: " + frameRate);
println("Memory usage: " + Runtime.getRuntime().totalMemory());
```

### Threading Considerations

- **Main thread**: All UI and rendering operations
- **OSC thread**: Message handling is thread-safe
- **MIDI thread**: MIDI callbacks run on separate thread

## Error Handling

### Common Error Patterns

```java
// Safe array access
if (index >= 0 && index < soundSources.size()) {
    SoundSource source = soundSources.get(index);
    // Use source safely
}

// Safe division
if (denominator != 0) {
    float result = numerator / denominator;
}

// Constraint values
float constrainedValue = constrain(inputValue, minValue, maxValue);
```

### Debug Output

Enable debug mode by setting global flags:
```java
boolean DEBUG_OSC = true;
boolean DEBUG_MIDI = true;
boolean DEBUG_POSITION = true;
```

---

*This API documentation corresponds to the current version of the Spatial Audio Mixer. For updates and changes, refer to the inline code comments and README.md.*
