# 3D Spatial Audio Mixer

A real-time 3D spatial audio visualization and control system built in Processing, designed for MAE Capstone project. This application provides an intuitive interface for positioning and controlling multiple audio sources in 3D space with support for MIDI control surfaces and OSC communication.

## Features

### Core Functionality
- **3D/2D Visualization**: Toggle between immersive 3D view and multiple 2D projection views (Front, Top, Side)
- **Real-time Audio Source Control**: Position up to 7 audio sources in 3D space using spherical coordinates
- **Multiple Source Types**: 
  - Mono/Stereo sources (visualized in 3D space)
  - Ambisonic sources (for spatial audio recording)
  - Send sources (for effects routing)
- **Interactive UI**: Custom sliders for precise control of radius, azimuth, zenith, and rotation parameters

### Control Interfaces
- **MIDI Integration**: Full support for Yamaha 02R96-1 mixing console with comprehensive MIDI mapping
- **OSC Communication**: Multi-endpoint OSC support for:
  - Main audio engine communication
  - Head tracker integration
  - Ambisonic microphone rotator control
- **Mouse & Keyboard Control**: Intuitive mouse dragging for camera control and keyboard shortcuts

### Advanced Features
- **Head Tracking**: Real-time head position tracking integration for immersive audio experiences
- **Cube Rotation**: Independent rotation control for the 3D boundary frame
- **Source Rotation**: Individual rotation parameters (roll, yaw, pitch) for each audio source
- **Real-time Feedback**: Live VU meters and volume visualization
- **Responsive Layout**: Adaptive UI that scales with window resizing

## System Architecture

### Main Components

| Component | File | Purpose |
|-----------|------|---------|
| **Main Application** | `spatial_mixer.pde` | Core application logic and setup |
| **Visualization Manager** | `VisualizationManager.pde` | Handles 3D/2D rendering and view switching |
| **UI Manager** | `UIManager.pde` | Custom slider controls and user interface |
| **Track Manager** | `TrackManager.pde` | Audio track controls (volume, mute, solo) |
| **Source Manager** | `SourceManager.pde` | Audio source type management |
| **Sound Source** | `SoundSource.pde` | Individual audio source objects and positioning |
| **MIDI Integration** | `MidiMappingManager.pde` | MIDI device communication and mapping |
| **OSC Communication** | `OscHelper.pde` | OSC message handling for external communication |

### Data Flow
```
MIDI Controller → MIDI Mapping → Source Position Updates → 3D Visualization
                                                        ↓
Head Tracker → OSC Messages → Camera/Head Rotation → Updated View
                                                   ↓
Audio Engine ← OSC Output ← Position Calculations ← User Input
```

## Installation & Setup

### Prerequisites
- **Processing 4.x** or newer
- **Required Libraries**:
  - ControlP5 (for UI controls)
  - oscP5 (for OSC communication)
  - MidiBus (for MIDI integration)

### Installation Steps

1. **Clone or download** this repository to your local machine
2. **Install Processing** from [processing.org](https://processing.org/)
3. **Install required libraries** through Processing's Library Manager:
   - Tools → Manage Tools → Libraries → Search and install each library
4. **Open** `spatial_mixer.pde` in Processing
5. **Configure MIDI** (optional): 
   - For Yamaha 02R96-1: Use the provided simulator in `simulators/yamaha_02r96_sim/`
   - For other devices: Modify `data/midi_mapping.json`

### Quick Start
1. Run the application in Processing (Ctrl+R or Cmd+R)
2. Use keyboard keys 1-7 to select different audio sources
3. Adjust position using the sliders on the right panel
4. Press 'V' to toggle between 3D and 2D views
5. Press 'R' to reset all rotations

## Usage Guide

### Keyboard Shortcuts
- **1-7**: Select audio source
- **V**: Toggle 3D/2D view mode
- **R**: Reset all rotations (camera + cube + head)
- **C**: Reset head rotation only
- **B**: Reset cube rotation only
- **M**: Set selected source to Mono/Stereo mode
- **A**: Set selected source to Ambisonic mode (only one allowed)
- **S**: Set selected source to Send mode
- **↑/↓**: Scroll message log

### Mouse Controls
- **Drag in 3D view**: Rotate camera around the scene
- **Slider interaction**: Click and drag custom sliders for precise control

### Understanding the Interface

#### Main View (Left)
- **3D Mode**: Interactive 3D cube with positioned audio sources
- **2D Mode**: Four-panel view showing Front, Top, Side projections and info panel

#### Control Panel (Right)
- **Position Sliders**: Radius, Azimuth, Zenith for spherical positioning
- **Rotation Sliders**: Roll, Yaw, Pitch for camera and cube rotation
- **MIDI Device**: Dropdown for MIDI controller selection
- **Message Log**: Real-time feedback and system messages

#### Track Controls (Bottom)
- **Volume Faders**: Individual track volume control
- **Mute/Solo**: Track isolation controls
- **VU Meters**: Real-time audio level indicators
- **Source Type Indicators**: Color-coded source type identification

#### Source Manager (Bottom)
- **Track Selection**: Visual source selection interface
- **Source Type Control**: Switch between Mono/Stereo, Ambi, and Send modes

## Configuration

### OSC Endpoints
The system communicates via OSC on multiple ports:

| Purpose | Local Port | Remote Host | Remote Port |
|---------|------------|-------------|-------------|
| Main Audio Engine | 8000 | 192.168.1.50 | 8100 |
| Head Tracker (Receive) | 9000 | 127.0.0.1 | 9101 |
| Head Tracker (Send) | 9000 | 192.168.1.50 | 9000 |
| Ambi Mic Rotator | 9200 | 192.168.1.60 | 9201 |

### MIDI Mapping
MIDI mappings are defined in `data/midi_mapping.json`. The system supports:
- **CC Messages**: Continuous controllers for smooth parameter changes
- **SysEx Messages**: System exclusive messages for complex position data
- **Multiple Parameters**: Volume, pan, positioning, mute, solo controls

### Coordinate System
- **Spherical Coordinates**: 
  - Radius: 50-400 units from center
  - Azimuth: 0-2π (horizontal rotation)
  - Zenith: -π/2 to π/2 (vertical angle, 0=horizontal)
- **3D Cartesian**: Automatically calculated from spherical coordinates
- **Coordinate Mapping**: Right-handed coordinate system with Y-up orientation

## Development

### Project Structure
```
spatial_mixer/
├── spatial_mixer.pde          # Main application file
├── VisualizationManager.pde   # 3D/2D rendering system
├── UIManager.pde              # User interface controls
├── TrackManager.pde           # Audio track management
├── SourceManager.pde          # Source type management
├── SoundSource.pde            # Audio source class
├── MidiMappingManager.pde     # MIDI integration
├── OscHelper.pde              # OSC communication
├── CubeRenderer.pde           # 3D cube rendering
├── CentralHead.pde            # Head tracking visualization
├── CustomSlider.pde           # Custom UI slider component
├── SliderManager.pde          # Slider management system
├── LayoutManager.pde          # Responsive layout management
├── Rectangle.pde              # Utility rectangle class
├── data/
│   └── midi_mapping.json      # MIDI controller mappings
└── simulators/                # Hardware simulators
    ├── yamaha_02r96_sim/      # Yamaha mixer simulator
    └── bridgehead_headtracker_sim/ # Head tracker simulator
```

### Key Classes

#### SoundSource
Represents an individual audio source with:
- Spherical positioning (radius, azimuth, zenith)
- Individual rotation parameters
- Source type (Mono/Stereo, Ambi, Send)
- Volume and VU level tracking
- Real-time position updates

#### VisualizationManager
Manages the visual representation:
- Switches between 3D and 2D view modes
- Handles mouse interaction for camera control
- Coordinates multiple view classes (View3D, View2D)
- Manages camera and cube rotation

#### UIManager
Custom UI system with:
- Responsive slider controls
- Real-time value updates
- MIDI device selection
- Message logging system
- Adaptive layout management

## Hardware Integration

### Supported MIDI Controllers
- **Yamaha 02R96-1**: Full integration with provided simulator
- **Generic MIDI**: Customizable through MIDI mapping configuration

### Head Tracking
Compatible with OSC-enabled head tracking systems for immersive audio control.

### External Audio Engines
Communicates with professional audio engines via OSC protocol for real-time spatial audio processing.

## Troubleshooting

### Common Issues

**MIDI Not Working**
- Ensure MIDI device is connected and recognized by system
- Check MIDI device selection in dropdown menu
- Verify MIDI mapping configuration in `data/midi_mapping.json`

**OSC Communication Problems**
- Check network connectivity and IP addresses in code
- Verify OSC ports are not blocked by firewall
- Ensure external applications are listening on correct ports

**Performance Issues**
- Reduce number of active sources
- Disable 3D visualization if running on slower hardware
- Close other applications using audio/MIDI resources

### Debug Features
- Real-time message logging in UI
- Console output for detailed system information
- Visual feedback for all user interactions

## Contributing

This project is part of an MAE Capstone project. For modifications or improvements:

1. Follow Processing coding conventions
2. Maintain compatibility with existing MIDI mappings
3. Test with hardware simulators before hardware integration
4. Document any new OSC message formats
5. Update this README for significant changes



## Credits

Developed for MAE Capstone Project by Riccardo Corà, Riccardo Moschen, Giuseppe Longo.


---

*For detailed API documentation, see the inline comments in each .pde file.*
