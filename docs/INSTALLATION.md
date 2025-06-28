# Installation Guide - 3D Spatial Audio Mixer

This guide provides step-by-step instructions for setting up the 3D Spatial Audio Mixer on your system.

## Table of Contents
- [System Requirements](#system-requirements)
- [Software Installation](#software-installation)
- [Hardware Setup](#hardware-setup)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting Installation](#troubleshooting-installation)



### Hardware Compatibility
- **MIDI Controllers**: Any USB/MIDI compatible controller
- **Optimized for**: Yamaha 02R96-1 mixing console
- **Head Trackers**: OSC-compatible head tracking systems
- **Audio Engines**: Any software supporting OSC input

## Software Installation

### Step 1: Install Processing

#### Windows
1. **Download Processing**:
   - Visit [processing.org](https://processing.org/download)
   - Download Processing 4.x for Windows
   - Choose 64-bit version if available

2. **Install Processing**:
   - Run the downloaded installer
   - Follow the installation wizard
   - Choose installation directory (default recommended)
   - Allow firewall exceptions when prompted

3. **Verify Installation**:
   - Launch Processing from Start menu
   - Confirm version is 4.x or newer
   - Test with a simple sketch (File → Examples → Basics → Hello)

#### macOS
1. **Download Processing**:
   - Visit [processing.org](https://processing.org/download)
   - Download Processing 4.x for macOS
   - Choose appropriate version (Intel or Apple Silicon)

2. **Install Processing**:
   - Open the downloaded .dmg file
   - Drag Processing to Applications folder
   - Launch from Applications (may require security approval)

3. **Security Setup**:
   - If blocked, go to System Preferences → Security & Privacy
   - Click "Open Anyway" for Processing
   - Confirm you want to open the application

#### Linux (Ubuntu/Debian)
1. **Download Processing**:
   - Visit [processing.org](https://processing.org/download)
   - Download Processing 4.x for Linux 64-bit

2. **Install Processing**:
   ```bash
   cd ~/Downloads
   tar -xzf processing-4.x.x-linux-x64.tgz
   sudo mv processing-4.x.x /opt/processing
   sudo ln -s /opt/processing/processing /usr/local/bin/processing
   ```

3. **Install Dependencies**:
   ```bash
   sudo apt update
   sudo apt install openjdk-11-jdk
   sudo apt install mesa-utils
   ```

### Step 2: Install Required Libraries

#### Method 1: Using Processing Library Manager (Recommended)
1. **Open Processing**
2. **Access Library Manager**:
   - Go to Tools → Manage Tools...
   - Click on "Libraries" tab

3. **Install Required Libraries**:
   - Search for "ControlP5" → Install latest version
   - Search for "oscP5" → Install latest version  
   - Search for "The MidiBus" → Install latest version

4. **Verify Installation**:
   - Libraries should appear in Sketch → Import Library menu
   - Restart Processing if libraries don't appear

#### Method 2: Manual Installation
If automatic installation fails:

1. **Download Libraries Manually**:
   - oscP5: [sojamo.de/oscP5](http://www.sojamo.de/oscP5/)
   - MidiBus: [github.com/sparks/themidibus](https://github.com/sparks/themidibus)

2. **Install Libraries**:
   - Extract each library to Processing's libraries folder:
   - **Windows**: `Documents\Processing\libraries\`
   - **macOS**: `~/Documents/Processing/libraries/`
   - **Linux**: `~/sketchbook/libraries/`

3. **Verify Structure**:
   ```
   libraries/
   ├── oscP5/
   │   ├── library/
   │   └── examples/
   └── themidibus/
       ├── library/
       └── examples/
   ```

### Step 3: Download Project Files

#### Option 1: Download ZIP
1. **Download from repository** (if hosted on GitHub/similar)
2. **Extract to desired location**:
   - Recommended: `Documents/Processing/spatial_mixer/`
3. **Verify all files are present** (see file list below)

#### Option 2: Git Clone (if using version control)
```bash
cd ~/Documents/Processing/
git clone [repository-url] spatial_mixer
cd spatial_mixer
```

### Required Project Files
Verify these files are present:
```
spatial_mixer/
├── spatial_mixer.pde          # Main application file
├── VisualizationManager.pde   # 3D/2D rendering
├── UIManager.pde             # User interface
├── TrackManager.pde          # Track controls
├── SourceManager.pde         # Source management
├── SoundSource.pde           # Source objects
├── MidiMappingManager.pde    # MIDI integration
├── OscHelper.pde             # OSC communication
├── CubeRenderer.pde          # 3D cube rendering
├── CentralHead.pde           # Head visualization
├── CustomSlider.pde          # UI slider component
├── SliderManager.pde         # Slider management
├── LayoutManager.pde         # Layout management
├── Rectangle.pde             # Utility class
├── data/
│   └── midi_mapping.json     # MIDI mappings
└── simulators/               # Hardware simulators
    ├── yamaha_02r96_sim/
    └── bridgehead_headtracker_sim/
```

## Hardware Setup

### MIDI Controller Setup

#### For Yamaha 02R96-1 Users

**Physical Setup**:
1. **Connect MIDI cables**:
   - MIDI OUT from mixer → MIDI IN on computer interface
   - Use USB-MIDI interface if computer lacks MIDI ports

2. **Power on equipment**:
   - Turn on mixer first
   - Connect and power on MIDI interface
   - Verify MIDI activity LEDs when moving controls

**Software Setup (No Physical Hardware)**:
1. **Install Python** (3.7 or newer)
2. **Install simulator dependencies**:
   ```bash
   cd spatial_mixer/simulators/yamaha_02r96_sim/
   pip install -r requirements.txt
   ```

3. **Setup virtual MIDI** (Windows):
   - Download and install [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html)
   - Create virtual port named "Yamaha 02R96-1"
   - Start the port in loopMIDI

4. **Run simulator**:
   ```bash
   python yamaha_02r96_simulator_gui_v2.py
   ```

#### For Generic MIDI Controllers
1. **Connect controller** via USB or MIDI interface
2. **Verify system recognition**:
   - **Windows**: Check Device Manager → Sound, video and game controllers
   - **macOS**: Check Audio MIDI Setup → MIDI Studio
   - **Linux**: Use `aconnect -l` to list MIDI devices

3. **Note device name** for configuration later

### Network Setup for OSC

#### Basic Network Configuration
1. **Ensure all devices on same network**:
   - Computer running spatial mixer
   - Audio engine computer
   - Head tracking system (if used)

2. **Configure static IP addresses** (recommended):
   - Spatial mixer computer: 192.168.1.100
   - Audio engine: 192.168.1.50
   - Head tracker: 192.168.1.60

3. **Test network connectivity**:
   ```bash
   ping 192.168.1.50  # Test audio engine
   ping 192.168.1.60  # Test head tracker
   ```

#### Firewall Configuration

**Windows**:
1. Open Windows Firewall settings
2. Allow Processing.exe through firewall
3. Allow OSC ports: 8000, 8100, 9000, 9101, 9200, 9201

**macOS**:
1. System Preferences → Security & Privacy → Firewall
2. Add Processing to allowed applications
3. Allow incoming connections for Processing

**Linux**:
```bash
sudo ufw allow 8000:9300/udp
sudo ufw allow processing
```

## Configuration

### Initial Configuration

1. **Open Project in Processing**:
   - Launch Processing
   - File → Open → Navigate to spatial_mixer.pde
   - Verify all tabs load correctly

2. **Configure Network Settings** (if needed):
   - Edit IP addresses in spatial_mixer.pde:
   ```java
   // Line ~103: Main OSC helper
   oscHelper = new OscHelper(this, 8000, "192.168.1.50", 8100, ...);
   
   // Line ~109: Head tracker
   headTrackerOscHelperRec = new OscHelper(this, 9000, "127.0.0.1", 9101, ...);
   ```

3. **Test Basic Functionality**:
   - Click Run button (►) in Processing
   - Application should start without errors
   - Try selecting sources with number keys 1-7

### MIDI Configuration

#### Using Pre-configured Yamaha 02R96-1
1. **Verify MIDI mapping file**:
   - Check `data/midi_mapping.json` exists
   - Contains Yamaha-specific mappings

2. **Select MIDI device**:
   - In application, click MIDI device dropdown
   - Select "Yamaha 02R96-1" or your device
   - Green status should appear in message log

#### Custom MIDI Controller
1. **Edit MIDI mapping file**:
   ```json
   {
     "device_name": "Your Controller Name",
     "mappings": [
       {
         "type": "CC",
         "channel": 1,
         "controller": 7,
         "action": "setTrackVolume",
         "track": 1,
         "min": 0,
         "max": 127
       }
     ]
   }
   ```

2. **Test MIDI communication**:
   - Move a control on your MIDI device
   - Check message log for MIDI activity
   - Verify parameter changes in application

### Head Tracker Setup (Optional)

#### Python-based Head Tracker Simulator
1. **Navigate to simulator**:
   ```bash
   cd spatial_mixer/simulators/bridgehead_headtracker_sim/
   ```

2. **Install dependencies**:
   ```bash
   pip install -r head_tracker_requirements.txt
   ```

3. **Run simulator**:
   ```bash
   python head_tracker_simulator.py
   ```

4. **Verify OSC communication**:
   - Move virtual head in simulator
   - Check spatial mixer responds to head movements
   - Head orientation axes should update in 3D view

## Verification

### Basic Functionality Test

1. **Application Startup**:
   - [ ] Application loads without errors
   - [ ] All UI elements visible and properly positioned
   - [ ] 3D view shows cube and default sources

2. **User Interface**:
   - [ ] Number keys 1-7 select different sources
   - [ ] Selected source highlighted in yellow
   - [ ] Sliders respond to mouse input
   - [ ] V key toggles between 3D and 2D views

3. **Source Control**:
   - [ ] Radius slider moves sources toward/away from center
   - [ ] Azimuth slider rotates sources horizontally
   - [ ] Zenith slider moves sources up/down
   - [ ] Position changes visible in real-time

4. **Advanced Features**:
   - [ ] R key resets all rotations
   - [ ] M/A/S keys change source types
   - [ ] Track volume faders respond to mouse
   - [ ] Mute/solo buttons toggle properly

### MIDI Integration Test

1. **Device Recognition**:
   - [ ] MIDI device appears in dropdown list
   - [ ] Can select device from dropdown
   - [ ] Status message confirms connection

2. **Control Response**:
   - [ ] Moving MIDI faders changes track volumes
   - [ ] MIDI buttons toggle mute/solo states
   - [ ] Position controls update source locations
   - [ ] Message log shows MIDI activity

### OSC Communication Test

1. **Network Connectivity**:
   - [ ] Can ping target IP addresses
   - [ ] No firewall blocking OSC ports
   - [ ] External applications running and listening

2. **Message Exchange**:
   - [ ] Position changes send OSC messages
   - [ ] Volume changes send OSC messages
   - [ ] Incoming OSC messages update interface
   - [ ] Head tracker messages move head visualization

### Performance Test

1. **System Performance**:
   - [ ] Frame rate maintains 30+ FPS in 3D mode
   - [ ] Smooth source movement with slider changes
   - [ ] No lag between input and visual response
   - [ ] Memory usage remains stable over time

2. **Stress Testing**:
   - [ ] Multiple simultaneous source movements
   - [ ] Rapid view mode switching
   - [ ] Continuous MIDI/OSC message flow
   - [ ] Extended operation periods

## Troubleshooting Installation

### Common Installation Problems

#### Processing Won't Start
**Symptoms**: Application crashes, error messages, won't launch
**Solutions**:
- Verify Processing version is 4.x or newer
- Update Java Runtime Environment
- Check system compatibility requirements
- Try running as administrator (Windows)

#### Libraries Not Loading
**Symptoms**: "Cannot find a class or type" errors
**Solutions**:
- Reinstall libraries through Library Manager
- Verify library folder structure is correct
- Check Processing sketchbook location
- Restart Processing IDE

#### Project Files Missing
**Symptoms**: "No such file or directory" errors
**Solutions**:
- Re-download complete project archive
- Verify all .pde files are in same folder
- Check data folder contains midi_mapping.json
- Ensure folder name matches main .pde file

#### MIDI Device Not Recognized
**Symptoms**: Device doesn't appear in dropdown
**Solutions**:
- Verify device connection and power
- Check device drivers are installed
- Test with other MIDI software
- Try different USB ports/cables
- Restart computer and application

#### Network/OSC Issues
**Symptoms**: No OSC communication, connection timeouts
**Solutions**:
- Verify network connectivity with ping
- Check firewall settings allow OSC ports
- Confirm IP addresses are correct
- Test with OSC debugging tools
- Verify external applications are running

#### Performance Problems
**Symptoms**: Low frame rate, stuttering, lag
**Solutions**:
- Update graphics drivers
- Close unnecessary applications
- Switch to 2D view mode
- Reduce window size
- Check system resource usage

### Getting Help

#### Documentation Resources
- **README.md**: Project overview and quick start
- **USER_GUIDE.md**: Detailed usage instructions
- **API.md**: Technical reference for developers

#### Debug Information
- **Console output**: Check Processing IDE console for error messages
- **Message log**: Monitor in-application message log for system feedback
- **System requirements**: Verify your system meets minimum requirements

#### Support Channels
- Check project repository for known issues
- Consult Processing community forums
- Review library documentation for ControlP5, oscP5, MidiBus
- Contact project maintainers for specific issues

---

