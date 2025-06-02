#!/usr/bin/env python3
"""
Yamaha 02R96-1 MIDI Device Simulator

This script simulates the Yamaha 02R96-1 mixing console by creating a virtual MIDI output
and sending MIDI messages that match the mappings defined in midi_mapping.json.

Requirements:
- python-rtmidi: pip install python-rtmidi
- pygame (optional, for GUI): pip install pygame

Usage:
1. Run the script: python yamaha_02r96_simulator.py
2. The script will create a virtual MIDI port named "Yamaha 02R96-1 Simulator"
3. Use the command-line interface or GUI to send MIDI messages
4. Your Processing sketch should receive these messages as if from a real device
"""

import rtmidi
import time
import threading
import json
import sys
from typing import List, Dict, Any, Optional

class YamahaSimulator:
    def __init__(self):
        self.midiout = rtmidi.MidiOut()
        self.port_name = "Yamaha 02R96-1"
        self.is_running = False
        self.connected = False
        self.mappings = self.load_mappings()
        
        # Connect to MIDI port with Windows compatibility
        self.connect_to_midi_port()
    
    def load_mappings(self) -> Dict[str, Any]:
        """Load MIDI mappings from the JSON file"""
        try:
            with open('data/midi_mapping.json', 'r') as f:
                data = json.load(f)
            return data["devices"]["Yamaha 02R96-1"]["midiMappings"]
        except Exception as e:
            print(f"✗ Failed to load MIDI mappings: {e}")
            return []
    def send_cc_message(self, channel: int, controller: int, value: int):
        """Send a Control Change message"""
        if not self.connected:
            print("✗ Error: Not connected to MIDI port")
            return
            
        # MIDI CC: Status byte (0xB0 + channel), Controller, Value
        message = [0xB0 + channel, controller, value]
        self.midiout.send_message(message)
        print(f"→ CC: Ch={channel}, CC={controller}, Val={value}")
    
    def send_sysex_message(self, data: List[int]):
        """Send a System Exclusive message"""
        if not self.connected:
            print("✗ Error: Not connected to MIDI port")
            return
            
        self.midiout.send_message(data)
        data_hex = ' '.join([f'{b:02X}' for b in data])
        print(f"→ SysEx: {data_hex}")
    
    def send_track_volume(self, track: int, value: int):
        """Send volume control for a specific track (1-48)"""
        if 1 <= track <= 24:
            # Tracks 1-24 on channel 0, controllers 1-24
            self.send_cc_message(0, track, value)
        elif 25 <= track <= 48:
            # Tracks 25-48 on channel 1, controllers 1-24
            self.send_cc_message(1, track - 24, value)
        else:
            print(f"✗ Invalid track number: {track} (must be 1-48)")
    
    def send_master_volume(self, value: int):
        """Send master volume control"""
        # Master fader on channel 1, controller 30
        self.send_cc_message(1, 30, value)
    
    def send_track_mute(self, track: int, muted: bool):
        """Send mute control for a specific track (1-48)"""
        value = 127 if muted else 0
        
        if 1 <= track <= 24:
            # Tracks 1-24 on channel 1, controllers 40-63
            controller = 39 + track  # 40-63
            self.send_cc_message(1, controller, value)
        elif 25 <= track <= 48:
            # Tracks 25-48 on channel 2, controllers 40-63
            controller = 39 + (track - 24)  # 40-63
            self.send_cc_message(2, controller, value)
        else:
            print(f"✗ Invalid track number: {track} (must be 1-48)")
    
    def send_track_solo(self, track: int, solo: bool):
        """Send solo control for a specific track (1-48)"""
        if not (1 <= track <= 48):
            print(f"✗ Invalid track number: {track} (must be 1-48)")
            return
        
        # SysEx pattern: F0 43 10 3E 0B 03 2E 00 [track] 00 00 00 [value] F7
        track_byte = track - 1  # Convert to 0-based (00-2F)
        value_byte = 1 if solo else 0
        
        sysex_data = [
            0xF0, 0x43, 0x10, 0x3E, 0x0B, 0x03, 0x2E, 0x00,
            track_byte, 0x00, 0x00, 0x00, value_byte, 0xF7
        ]
        self.send_sysex_message(sysex_data)
    
    def send_track_pan(self, track: int, value: int):
        """Send pan control for a specific track (1-48)"""
        if 1 <= track <= 24:
            # Tracks 1-24 on channel 0, controllers 89-118
            controller = 88 + track  # 89-112
            self.send_cc_message(0, controller, value)
        elif 25 <= track <= 48:
            # Tracks 25-48 on channel 1, controllers 89-118
            controller = 88 + (track - 24)  # 89-112
            self.send_cc_message(1, controller, value)
        else:
            print(f"✗ Invalid track number: {track} (must be 1-48)")
    def send_position_x(self, track: int, value: int):
        """Send X position control for a specific track (1-48)"""
        if not (1 <= track <= 48):
            print(f"✗ Invalid track number: {track} (must be 1-48)")
            return
        
        # Convert value to 4-byte format
        # Format: 00 00 00 00 = origin, 00 00 00 3F = +63, 7F 7F 7F 7F = -1, 7F 7F 7F 41 = -63
        track_byte = track - 1  # Convert to 0-based (00-2F)
        
        # Convert position value (-63 to +63) to the special 4-byte format
        if value >= 0:
            # Positive values: 00 00 00 XX (where XX = 0 to 63)
            b1, b2, b3, b4 = 0x00, 0x00, 0x00, min(value, 63)
        else:
            # Negative values: 7F 7F 7F XX (where XX descends from 7F for -1 to 41 for -63)
            # -1 = 7F 7F 7F 7F, -2 = 7F 7F 7F 7E, ..., -63 = 7F 7F 7F 41
            abs_value = min(abs(value), 63)  # Clamp to valid range
            b4 = 0x7F - abs_value + 1  # Calculate: -1->7F, -2->7E, ..., -63->41
            b1, b2, b3 = 0x7F, 0x7F, 0x7F
        
        # SysEx pattern: F0 43 10 3E 7F 01 25 05 [track] [b1] [b2] [b3] [b4] F7
        sysex_data = [
            0xF0, 0x43, 0x10, 0x3E, 0x7F, 0x01, 0x25, 0x05,
            track_byte, b1, b2, b3, b4, 0xF7
        ]
        self.send_sysex_message(sysex_data)
    def send_position_y(self, track: int, value: int):
        """Send Y position control for a specific track (1-48)"""
        if not (1 <= track <= 48):
            print(f"✗ Invalid track number: {track} (must be 1-48)")
            return
        
        # Convert value to 4-byte format (same format as X position)
        # Format: 00 00 00 00 = origin, 00 00 00 3F = +63, 7F 7F 7F 7F = -1, 7F 7F 7F 41 = -63
        track_byte = track - 1  # Convert to 0-based (00-2F)
        
        if value >= 0:
            # Positive values: 00 00 00 XX (where XX = 0 to 63)
            b1, b2, b3, b4 = 0x00, 0x00, 0x00, min(value, 63)
        else:
            # Negative values: 7F 7F 7F XX (where XX descends from 7F for -1 to 41 for -63)
            # -1 = 7F 7F 7F 7F, -2 = 7F 7F 7F 7E, ..., -63 = 7F 7F 7F 41
            abs_value = min(abs(value), 63)  # Clamp to valid range
            b4 = 0x7F - abs_value + 1  # Calculate: -1->7F, -2->7E, ..., -63->41
            b1, b2, b3 = 0x7F, 0x7F, 0x7F
        
        # SysEx pattern: F0 43 10 3E 7F 01 25 06 [track] [b1] [b2] [b3] [b4] F7
        sysex_data = [
            0xF0, 0x43, 0x10, 0x3E, 0x7F, 0x01, 0x25, 0x06,
            track_byte, b1, b2, b3, b4, 0xF7
        ]
        self.send_sysex_message(sysex_data)
    
    def demo_sequence(self):
        """Run a demonstration sequence of MIDI messages"""
        print("\n🎹 Starting demo sequence...")
        
        # Demo track volumes
        print("\n📊 Demo: Track Volumes")
        for track in range(1, 8):  # Test first 7 tracks
            volume = int(127 * (track / 7))  # Gradual increase
            self.send_track_volume(track, volume)
            time.sleep(0.1)
        
        time.sleep(1)
        
        # Demo master volume
        print("\n🎚️ Demo: Master Volume")
        for value in [0, 64, 127, 100]:
            self.send_master_volume(value)
            time.sleep(0.5)
        
        # Demo mute toggles
        print("\n🔇 Demo: Mute Toggles")
        for track in range(1, 4):
            self.send_track_mute(track, True)   # Mute
            time.sleep(0.3)
            self.send_track_mute(track, False)  # Unmute
            time.sleep(0.3)
        
        # Demo solo toggles
        print("\n🎯 Demo: Solo Toggles")
        for track in range(1, 4):
            self.send_track_solo(track, True)   # Solo on
            time.sleep(0.3)
            self.send_track_solo(track, False)  # Solo off
            time.sleep(0.3)
        
        # Demo pan controls
        print("\n⬅️➡️ Demo: Pan Controls")
        for track in range(1, 4):
            for pan_value in [0, 64, 127, 64]:  # Left, Center, Right, Center
                self.send_track_pan(track, pan_value)
                time.sleep(0.2)
        
        # Demo position controls
        print("\n🎯 Demo: Position Controls")
        for track in range(1, 3):
            # Test X position
            for x_pos in [-30, 0, 30, 0]:
                self.send_position_x(track, x_pos)
                time.sleep(0.3)
            
            # Test Y position  
            for y_pos in [-20, 0, 20, 0]:
                self.send_position_y(track, y_pos)
                time.sleep(0.3)
        
        print("\n✅ Demo sequence completed!")
    
    def interactive_mode(self):
        """Interactive command-line interface"""
        print("\n🎮 Interactive Mode - Available Commands:")
        print("  vol <track> <value>     - Set track volume (track: 1-48, value: 0-127)")
        print("  master <value>          - Set master volume (value: 0-127)")
        print("  mute <track> <on/off>   - Toggle track mute")
        print("  solo <track> <on/off>   - Toggle track solo")
        print("  pan <track> <value>     - Set track pan (value: 0-127)")
        print("  posx <track> <value>    - Set X position (value: -63 to 63)")
        print("  posy <track> <value>    - Set Y position (value: -63 to 63)")
        print("  demo                    - Run demo sequence")
        print("  help                    - Show this help")
        print("  quit                    - Exit simulator")
        print()
        
        while True:
            try:
                cmd = input("🎹 > ").strip().lower().split()
                
                if not cmd:
                    continue
                elif cmd[0] == 'quit':
                    break
                elif cmd[0] == 'help':
                    print("📋 Commands: vol, master, mute, solo, pan, posx, posy, demo, help, quit")
                elif cmd[0] == 'demo':
                    self.demo_sequence()
                elif cmd[0] == 'vol' and len(cmd) == 3:
                    track, value = int(cmd[1]), int(cmd[2])
                    self.send_track_volume(track, value)
                elif cmd[0] == 'master' and len(cmd) == 2:
                    value = int(cmd[1])
                    self.send_master_volume(value)
                elif cmd[0] == 'mute' and len(cmd) == 3:
                    track, state = int(cmd[1]), cmd[2] == 'on'
                    self.send_track_mute(track, state)
                elif cmd[0] == 'solo' and len(cmd) == 3:
                    track, state = int(cmd[1]), cmd[2] == 'on'
                    self.send_track_solo(track, state)
                elif cmd[0] == 'pan' and len(cmd) == 3:
                    track, value = int(cmd[1]), int(cmd[2])
                    self.send_track_pan(track, value)
                elif cmd[0] == 'posx' and len(cmd) == 3:
                    track, value = int(cmd[1]), int(cmd[2])
                    self.send_position_x(track, value)
                elif cmd[0] == 'posy' and len(cmd) == 3:
                    track, value = int(cmd[1]), int(cmd[2])
                    self.send_position_y(track, value)
                else:
                    print("❌ Invalid command. Type 'help' for available commands.")
                    
            except (ValueError, IndexError):
                print("❌ Invalid parameters. Type 'help' for command syntax.")
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"❌ Error: {e}")
    
    def connect_to_midi_port(self):
        """Connect to MIDI port with Windows compatibility"""
        try:
            # First, try to open a virtual port (works on macOS/Linux)
            self.midiout.open_virtual_port(self.port_name)
            self.connected = True
            print(f"✓ Virtual port created: {self.port_name}")
            return
        except Exception as virtual_error:
            print(f"Virtual port creation failed: {virtual_error}")
            
        # Virtual ports failed, try to find existing port (Windows with loopMIDI)
        try:
            available_ports = self.midiout.get_ports()
            print(f"Available MIDI ports: {available_ports}")
            
            # Look for exact match first
            for i, port in enumerate(available_ports):
                if self.port_name in port:
                    self.midiout.open_port(i)
                    self.connected = True
                    print(f"✓ Connected to existing port: {port}")
                    return
            
            # If no exact match, try loopMIDI pattern
            for i, port in enumerate(available_ports):
                if "Yamaha" in port or "02R96" in port or "loopMIDI" in port:
                    self.midiout.open_port(i)
                    self.connected = True
                    print(f"✓ Connected to: {port}")
                    return
            
            # No suitable port found
            print(f"✗ No suitable MIDI port found.")
            print(f"Available ports: {available_ports}")
            print("\nFor Windows users:")
            print("1. Install loopMIDI from https://www.tobias-erichsen.de/software/loopmidi.html")
            print(f"2. Create a port named '{self.port_name}'")
            print("3. Restart this application")
            sys.exit(1)
            
        except Exception as port_error:
            print(f"✗ MIDI connection failed: {port_error}")
            sys.exit(1)

    def close(self):
        """Clean up MIDI connection"""
        if self.midiout:
            del self.midiout
        print("🔌 MIDI connection closed")

def main():
    print("🎹 Yamaha 02R96-1 MIDI Simulator")
    print("=" * 40)
    
    simulator = YamahaSimulator()
    
    try:
        print("\nChoose mode:")
        print("1. Interactive mode (manual control)")
        print("2. Demo sequence (automated)")
        print("3. Both (demo first, then interactive)")
        
        choice = input("\nEnter choice (1-3): ").strip()
        
        if choice == '1':
            simulator.interactive_mode()
        elif choice == '2':
            simulator.demo_sequence()
        elif choice == '3':
            simulator.demo_sequence()
            simulator.interactive_mode()
        else:
            print("Invalid choice, starting interactive mode...")
            simulator.interactive_mode()
            
    except KeyboardInterrupt:
        print("\n\n⏹️ Stopping simulator...")
    finally:
        simulator.close()

if __name__ == "__main__":
    main()
