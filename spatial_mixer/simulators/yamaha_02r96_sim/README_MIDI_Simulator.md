# Yamaha 02R96-1 MIDI Simulator

This project provides Python scripts to simulate the Yamaha 02R96-1 mixing console without requiring the physical hardware. The simulator creates a virtual MIDI device that sends the same types of MIDI messages your Processing sketch expects.

## Features

- **Virtual MIDI Port**: Creates "Yamaha 02R96-1 Simulator" MIDI device
- **Complete MIDI Mapping**: Supports all MIDI messages defined in `midi_mapping.json`:
  - Volume control (CC messages)
  - Mute/Solo toggles (CC and SysEx)
  - Pan controls (CC messages)
  - 3D positioning (SysEx messages)
- **Two Interfaces**:
  - Command-line interface for scripted testing
  - GUI interface for interactive testing
- **Demo Sequences**: Automated test sequences to verify all functions

## Installation

### Prerequisites
- Python 3.7 or newer
- **Windows users**: loopMIDI software (for virtual MIDI ports)

### Quick Windows Setup

1. **Check your current setup**:
```powershell
python windows_midi_setup.py
```

2. **Install loopMIDI** (if not already installed):
   - The setup script will offer to open the download page
   - Or visit: https://www.tobias-erichsen.de/software/loopmidi.html

3. **Create the MIDI port**:
   - Open loopMIDI from system tray
   - Add port name: `Yamaha 02R96-1`
   - Click '+' to create

4. **Test the simulator**:
```powershell
# New optimized GUI version (recommended)
python yamaha_02r96_simulator_gui_v2.py

# Or original GUI version
python yamaha_02r96_simulator_gui.py
```

### Install Dependencies

Install required Python packages:
```powershell
pip install -r requirements.txt
```

Or install manually:
```powershell
pip install python-rtmidi
```

## Usage

### Option 1: Command Line Interface

Run the command-line simulator:
```powershell
python yamaha_02r96_simulator.py
```

**Available Commands:**
- `vol <track> <value>` - Set track volume (track: 1-48, value: 0-127)
- `master <value>` - Set master volume (value: 0-127)
- `mute <track> <on/off>` - Toggle track mute
- `solo <track> <on/off>` - Toggle track solo
- `pan <track> <value>` - Set track pan (value: 0-127)
- `posx <track> <value>` - Set X position (value: -63 to 63)
- `posy <track> <value>` - Set Y position (value: -63 to 63)
- `demo` - Run demo sequence
- `help` - Show help
- `quit` - Exit

**Example Commands:**
```
vol 1 127        # Set track 1 volume to maximum
mute 2 on        # Mute track 2
solo 3 on        # Solo track 3
pan 1 0          # Pan track 1 fully left
posx 1 30        # Set track 1 X position to +30
demo             # Run automated demo
```

### Option 2: GUI Interface

#### New Optimized GUI (Recommended)
```powershell
python yamaha_02r96_simulator_gui_v2.py
```

#### Original GUI
```powershell
python yamaha_02r96_simulator_gui.py
```

The GUI provides a comprehensive tabbed interface:
- **Volume Tab**: Master volume and individual track volume sliders (1-48)
- **Mute/Solo Tab**: Toggle buttons for mute and solo controls
- **Pan Tab**: Horizontal sliders for panning controls
- **3D Position Tab**: X/Y position controls with quick-set buttons
- **Testing Tab**: Automated test functions and manual MIDI sending
- **MIDI Log**: Real-time display of sent MIDI messages
- **Connection Status**: Shows MIDI port connection status with reconnect option

## Processing Sketch Integration

### 1. Update Your Processing Sketch

Make sure your Processing sketch recognizes the simulator. In your `setup()` function, the MIDI device detection should find "Yamaha 02R96-1 Simulator":

```java
MidiBus.list(); // This should now show the simulator
String[] availableDevices = MidiBus.availableInputs();
if (availableDevices.length > 0) {
    midiBus = new MidiBus(this, "Yamaha 02R96-1 Simulator", -1);
    println("MIDI device initialized: Yamaha 02R96-1 Simulator");
}
```

### 2. Testing Workflow

1. **Start the simulator** (either CLI or GUI version)
2. **Launch your Processing sketch**
3. **Verify connection** - You should see "Yamaha 02R96-1 Simulator" in the available MIDI devices
4. **Test MIDI messages** using the simulator interface
5. **Monitor in Processing** - Check console output for received MIDI messages

## MIDI Message Types Supported

### Control Change (CC) Messages
- **Volume Control**: Tracks 1-24 (Ch 0, CC 1-24), Tracks 25-48 (Ch 1, CC 1-24)
- **Master Volume**: Channel 1, CC 30
- **Mute Control**: Tracks 1-24 (Ch 1, CC 40-63), Tracks 25-48 (Ch 2, CC 40-63)
- **Pan Control**: Tracks 1-24 (Ch 0, CC 89-118), Tracks 25-48 (Ch 1, CC 89-118)

### System Exclusive (SysEx) Messages
- **Solo Control**: `F0 43 10 3E 0B 03 2E 00 [track] 00 00 00 [value] F7`
- **X Position**: `F0 43 10 3E 7F 01 25 05 [track] [pos_bytes] F7`
- **Y Position**: `F0 43 10 3E 7F 01 25 06 [track] [pos_bytes] F7`

## Troubleshooting

### MIDI Port Issues
- **"Failed to create MIDI port"**: Another application might be using the port name
- **Processing can't find device**: Make sure the simulator is running before starting Processing
- **No MIDI messages received**: Check that the correct device name is selected

### Python Issues
- **ImportError**: Install python-rtmidi using pip
- **Virtual port not working**: Try running as administrator (Windows)

### Common Solutions
1. **Restart both applications** if connection issues occur
2. **Check firewall settings** if using networked MIDI
3. **Verify MIDI device names** match exactly between simulator and Processing

## Advanced Usage

### Custom Test Sequences
You can modify the demo sequences in the code to test specific scenarios:

```python
# Example: Test specific track volumes
for track in [1, 3, 5]:
    simulator.send_track_volume(track, 127)
    time.sleep(0.5)
```

### Automated Testing
Create scripts that send sequences of MIDI messages for automated testing:

```python
# Test all positioning values
for x in range(-63, 64, 10):
    for y in range(-63, 64, 10):
        simulator.send_position_x(1, x)
        simulator.send_position_y(1, y)
        time.sleep(0.1)
```

## File Structure

```
spatial_mixer/
├── yamaha_02r96_simulator.py      # Command-line simulator
├── yamaha_02r96_simulator_gui.py  # GUI simulator
├── requirements.txt               # Python dependencies
├── README_MIDI_Simulator.md       # This file
└── data/
    └── midi_mapping.json          # MIDI mapping definitions
```

## License

This simulator is designed specifically for testing the MAE Capstone spatial mixer project and uses the MIDI mapping definitions from your existing `midi_mapping.json` file.
