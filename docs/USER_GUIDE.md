# User Guide - 3D Spatial Audio Mixer

This guide will help you get started with the 3D Spatial Audio Mixer and make the most of its features.

## Table of Contents
- [Getting Started](#getting-started)
- [Understanding the Interface](#understanding-the-interface)
- [Basic Operations](#basic-operations)
- [Advanced Features](#advanced-features)
- [Hardware Setup](#hardware-setup)
- [Troubleshooting](#troubleshooting)
- [Tips & Best Practices](#tips--best-practices)

## Getting Started

### First Launch

1. **Start the application** by running `spatial_mixer.pde` in Processing
2. **Familiarize yourself with the layout**:
   - Large visualization area on the left
   - Control sliders on the right
   - Track controls at the bottom
   - Source selection at the bottom

3. **Test basic functionality**:
   - Press keys **1-7** to select different audio sources
   - Move the **radius slider** to see the source move in 3D space
   - Press **V** to toggle between 3D and 2D views

### Quick Setup Checklist

- [ ] Processing 4.x installed with required libraries
- [ ] Application starts without errors
- [ ] Can select sources with number keys (1-7)
- [ ] Sliders respond to mouse input
- [ ] 3D view shows sources and cube boundary
- [ ] 2D view shows multiple projection views

## Understanding the Interface

### Main Visualization Area (Left Side)

#### 3D View Mode
- **Wireframe cube**: Represents the 3D audio space boundary
- **Colored spheres**: Individual audio sources positioned in 3D space
- **Yellow contoured sphere**: Selected audio source (highlighted)
- **Numbers**: Source identification (1-7)
- **Central sphere**: Represents the listener's head position
- **Connecting lines**: Show relationship between sources and listener

**Mouse Controls in 3D:**
- **Click and drag**: Rotate the camera around the scene

#### 2D View Mode (Four Panels)
- **Front View (top-left)**: X-Y plane projection
- **Top View (bottom-left)**: X-Z plane projection  
- **Side View (top-right)**: Z-Y plane projection
- **Info Panel (bottom-right)**: Legend and rotation information

### Control Panel (Right Side)

#### Position Controls
| Slider | Range | Description |
|--------|-------|-------------|
| **Radius** | 50-400 | Distance from center |
| **Azimuth** | -180° to 180° | Horizontal rotation |
| **Zenith** | -90° to 90° | Vertical angle (elevation) |

#### Rotation Controls
| Slider | Purpose | Effect |
|--------|---------|--------|
| **Roll** | Cube Z-axis rotation | Tilts view left/right |
| **Yaw** | Cube Y-axis rotation | Rotates view horizontally |
| **Pitch** | Cube X-axis rotation | Tilts view up/down |

#### Additional Controls
- **MIDI Device Dropdown**: Select connected MIDI controller
- **Message Log**: Shows real-time system feedback
- **Instructions**: Quick reference for keyboard shortcuts

### Track Controls (Bottom)

#### Individual Track Strips
Each track has:
- **Track name/number**: Identification
- **Volume fader**: Vertical slider for volume control
- **Mute button**: Toggle audio mute (M)
- **Solo button**: Isolate track audio (S)
- **VU meter**: Real-time audio level display
- **Source type indicator**: Color-coded background

#### Master Track (Leftmost)
- Controls overall mix volume
- Master mute function
- Overall level monitoring

### Source Manager (Bottom)

#### Source Selection Grid
- **Visual source buttons**: Click to select sources
- **Color coding**: 
  - Green: Mono/Stereo sources (default)
  - Blue: Ambisonic source (only one allowed)
  - Red: Send track
- **Active source highlighting**: Shows currently selected source

## Basic Operations

### Selecting and Positioning Sources

1. **Select a source**:
   - Press number keys **1-7**, or
   - Click on source in the visualization, or
   - Click on source button in source manager

2. **Position the source**:
   - Use **Radius** slider to move closer/farther from center
   - Use **Azimuth** slider to rotate horizontally around the listener
   - Use **Zenith** slider to move up/down vertically

3. **Fine-tune position**:
   - Watch the 3D visualization for real-time feedback
   - Switch to 2D view (**V** key) to see precise positioning
   - Use multiple 2D views to understand spatial relationships

### Volume and Audio Controls

1. **Adjust volume**:
   - Click and drag track volume faders
   - Use master volume for overall level control

2. **Mute/Solo operations**:
   - Click **M** button to mute individual tracks
   - Click **S** button to solo (isolate) tracks
   - Multiple tracks can be soloed simultaneously

3. **Monitor levels**:
   - Watch VU meters for real-time audio levels
   - Meter colors indicate signal level (green/yellow/red)

### View Controls

1. **Switch view modes**:
   - Press **V** to toggle between 3D and 2D views
   - 3D view: Interactive perspective view
   - 2D view: Four orthographic projections

2. **Navigate 3D view**:
   - **Mouse drag**: Rotate camera around the scene
   - **Roll/Yaw/Pitch sliders**: Precise camera control
   - **R key**: Reset camera rotation to default

3. **Understanding 2D views**:
   - **Front view**: Look at sources from the front (X-Y plane)
   - **Top view**: Bird's eye view from above (X-Z plane)
   - **Side view**: Profile view from the side (Z-Y plane)

## Advanced Features

### Source Types

#### Mono/Stereo Sources (Green)
- **Default type** for most audio sources
- **Visualized** in 3D/2D views as colored spheres
- **Full positioning control** with radius, azimuth, zenith
- **Individual rotation** capability (roll, yaw, pitch)

#### Ambisonic Source (Blue)
- **Special recording source** for ambisonic microphones
- **Only one allowed** at a time in the system
- **Controls environmental audio** capture rotation
- **Not visualized** as a positioned source
- **Rotation controls** affect microphone orientation

#### Send Sources (Red)
- **Effects routing** or auxiliary sends
- **Not visualized** in spatial views
- **Volume and mute controls** available
- **Used for reverb, delay,** or other processing

### Source Type Management

1. **Change source type**:
   - Select source with number keys (1-7)
   - Press **M** for Mono/Stereo mode
   - Press **A** for Ambisonic mode (if available)
   - Press **S** for Send mode

2. **Ambisonic mode restrictions**:
   - Only one source can be in Ambisonic mode
   - Switching to Ambisonic mode will reset previous Ambisonic source
   - Ambisonic sources control microphone rotation instead of position

### Rotation Systems

The system has three independent rotation systems:

#### 1. Camera Rotation (View Only)
- **Purpose**: Change viewing angle without affecting audio
- **Controls**: Mouse drag or Roll/Yaw/Pitch sliders
- **Effect**: Rotates your view of the 3D scene
- **Audio impact**: None - purely visual

#### 2. Cube Rotation
- **Purpose**: Rotate the reference frame
- **Controls**: CubeRoll/CubeYaw/CubePitch sliders
- **Effect**: Rotates the boundary cube visualization
- **Audio impact**: Can affect spatial reference

#### 3. Individual Source Rotation
- **Purpose**: Rotate individual sources around their position
- **Controls**: Source-specific roll/yaw/pitch
- **Effect**: Rotates source orientation
- **Audio impact**: Affects source directivity (if supported)

### Head Tracking Integration

When connected to a head tracking system:

1. **Real-time head movement** updates the listener position
2. **OSC messages** control head orientation:
   - `/head/roll` - Head tilt left/right
   - `/head/pitch` - Head nod up/down
   - `/head/yaw` - Head turn left/right

3. **Visual feedback** shows head orientation with colored axes
4. **Independent control** from camera and cube rotations

## Hardware Setup

### MIDI Controller Integration

#### Yamaha 02R96-1 Setup
1. **Physical connection**:
   - Connect MIDI OUT from mixer to computer MIDI IN
   - Use USB-MIDI interface if needed

2. **Software setup**:
   - Run provided simulator if no physical hardware
   - Launch `yamaha_02r96_simulator_gui_v2.py`
   - Create virtual MIDI port "Yamaha 02R96-1"

3. **Configuration**:
   - Select "Yamaha 02R96-1" from MIDI device dropdown
   - Mappings are pre-configured in `data/midi_mapping.json`
   - Test with faders and buttons on mixer

#### Generic MIDI Controller
1. **Identify your controller**:
   - Note the device name as shown in system
   - Determine CC numbers for controls you want to use

2. **Create custom mapping**:
   - Edit `data/midi_mapping.json`
   - Add entries for your controller
   - Map CC numbers to actions like "setTrackVolume"

3. **Test and refine**:
   - Start with basic volume controls
   - Add positioning controls gradually
   - Use message log to debug issues

### OSC Integration

#### External Audio Engine
1. **Network setup**:
   - Ensure computers are on same network
   - Configure IP addresses in code (currently 192.168.1.50)
   - Test network connectivity

2. **OSC configuration**:
   - Audio engine should listen on port 8100
   - Spatial mixer sends on port 8000
   - Verify OSC message formats match

#### Head Tracking System
1. **OSC endpoints**:
   - Head tracker sends to port 9000
   - Configure head tracker IP (currently 127.0.0.1 for local)

2. **Message format**:
   - `/head/roll`, `/head/pitch`, `/head/yaw`
   - Values typically -1 to +1 range
   - System will map to appropriate rotation range

## Troubleshooting

### Common Issues and Solutions

#### Application Won't Start
**Symptoms**: Error messages, blank screen, crashes
**Solutions**:
- Check Processing version (4.x required)
- Install missing libraries (ControlP5, oscP5, MidiBus)
- Verify all .pde files are in same folder
- Check console for specific error messages

#### MIDI Not Working
**Symptoms**: Sliders don't respond to MIDI controller
**Solutions**:
- Verify MIDI device connection
- Check device appears in MIDI dropdown
- Confirm device name matches mapping file
- Test with MIDI monitor software
- Try restarting application

#### OSC Communication Problems
**Symptoms**: No response from external applications
**Solutions**:
- Check network connectivity with ping
- Verify IP addresses in code match target systems
- Confirm OSC ports are not blocked by firewall
- Use OSC debugging tools to monitor messages
- Check that external applications are running and listening

#### Performance Issues
**Symptoms**: Low frame rate, stuttering, lag
**Solutions**:
- Switch to 2D view mode (press V)
- Reduce number of active sources
- Close other applications using graphics/audio
- Check system resources (CPU, memory)
- Lower Processing sketch window size

#### Sources Not Visible
**Symptoms**: Can't see audio sources in visualization
**Solutions**:
- Check source type (only Mono/Stereo are visualized)
- Verify source is not at origin (radius > 50)
- Try different azimuth/zenith values
- Switch between 3D and 2D views
- Reset view with R key

#### Incorrect Positioning
**Symptoms**: Sources appear in wrong locations
**Solutions**:
- Understand coordinate system (see API documentation)
- Check azimuth range (0-360° or -180°-180°)
- Verify zenith range (-90° to +90°)
- Reset source position with known values
- Compare with 2D views for verification

### Debug Information

#### Message Log
- **Location**: Right panel, bottom section
- **Contents**: Real-time system messages
- **Scrolling**: Use up/down arrow keys
- **Information**: OSC messages, MIDI events, system status

#### Console Output
- **Access**: Processing IDE console window
- **Contents**: Detailed technical information
- **Error messages**: Stack traces and error details
- **Debug output**: Position calculations, message parsing

## Tips & Best Practices

### Workflow Recommendations

#### Starting a Session
1. **Launch application** and verify basic functionality
2. **Select MIDI controller** if using hardware
3. **Test source selection** with number keys
4. **Verify audio routing** if connected to audio engine
5. **Set up basic source positions** before detailed work

#### Positioning Sources
1. **Start with radius** to establish distance
2. **Use azimuth** for left/right positioning  
3. **Adjust zenith** for height placement
4. **Fine-tune** with small adjustments
5. **Verify position** in both 3D and 2D views

#### Working with Multiple Sources
1. **Position one source at a time** completely
2. **Use source selection** frequently
3. **Monitor VU levels** to ensure sources are active
4. **Solo tracks** to isolate positioning effects
5. **Save/document** positions for recall

### Performance Optimization

#### For Slower Systems
- **Use 2D view mode** primarily
- **Limit simultaneous source movement**
- **Close unnecessary applications**
- **Reduce window size** if needed
- **Disable visual effects** if available

#### For Live Performance
- **Pre-configure source positions**
- **Use MIDI controller** for real-time control
- **Practice transitions** between scenes
- **Have backup positions** ready
- **Monitor system performance** during use

### Best Practices

#### Source Management
- **Use descriptive source types** appropriately
- **Keep Ambisonic source** for environmental capture
- **Reserve Send sources** for effects
- **Maintain consistent** volume levels

#### Spatial Design
- **Consider listener perspective** when positioning
- **Use full 3D space** - don't just work in horizontal plane
- **Create realistic** source distances with radius
- **Test positions** from multiple viewpoints

#### System Integration
- **Document OSC message formats** for external systems
- **Back up MIDI mappings** before modification  
- **Test hardware connections** before live use
- **Have contingency plans** for system failures

#### Collaboration
- **Share position coordinates** with team members
- **Document source assignments** and purposes
- **Use consistent** naming conventions
- **Communicate changes** to connected systems

---
