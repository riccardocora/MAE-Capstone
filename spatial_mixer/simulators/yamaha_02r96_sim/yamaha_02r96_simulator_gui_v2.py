#!/usr/bin/env python3
"""
Yamaha 02R96-1 MIDI Device Simulator - GUI Version

This script provides a graphical interface to simulate the Yamaha 02R96-1 mixing console
by sending MIDI messages that match the mappings defined in midi_mapping.json.

Requirements:
- python-rtmidi: pip install python-rtmidi
- tkinter (usually included with Python)

Usage:
1. Ensure loopMIDI is running with a port named "Yamaha 02R96-1 1"
2. Run: python yamaha_02r96_simulator_gui_v2.py
3. Use the GUI tabs to control different mixer functions
4. Your Processing sketch should receive these messages
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import rtmidi
import json
import time
import threading
from typing import List, Dict, Any, Optional

class MIDILogger:
    """Thread-safe MIDI message logger for the GUI"""
    def __init__(self, text_widget: scrolledtext.ScrolledText):
        self.text_widget = text_widget
        self.lock = threading.Lock()
    
    def log(self, message: str):
        """Add a timestamped log message"""
        timestamp = time.strftime("%H:%M:%S")
        with self.lock:
            self.text_widget.insert(tk.END, f"[{timestamp}] {message}\n")
            self.text_widget.see(tk.END)

class YamahaSimulatorGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Yamaha 02R96-1 MIDI Simulator")
        self.root.geometry("900x700")
        
        # MIDI setup
        self.midiout = rtmidi.MidiOut()
        self.port_name = "Yamaha 02R96-1"
        self.connected = False
        
        # Load MIDI mappings
        self.mappings = self.load_mappings()
        
        # Create GUI
        self.setup_gui()
        
        # Connect to MIDI port
        self.connect_to_midi_port()
        
        # Track states for toggle buttons
        self.mute_states = {}  # track_id -> bool
        self.solo_states = {}  # track_id -> bool
        
    def load_mappings(self) -> List[Dict[str, Any]]:
        """Load MIDI mappings from the JSON file"""
        try:
            with open('data/midi_mapping.json', 'r') as f:
                data = json.load(f)
            return data["devices"]["Yamaha 02R96-1"]["midiMappings"]
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load MIDI mappings: {e}")
            return []
    
    def connect_to_midi_port(self):
        """Connect to the MIDI output port with Windows loopMIDI compatibility"""
        try:
            # First, list all available ports
            available_ports = self.midiout.get_ports()
            self.logger.log(f"Available MIDI ports: {available_ports}")
            
            # Try to find exact port name first
            target_port = None
            for i, port in enumerate(available_ports):
                if self.port_name in port:
                    target_port = i
                    self.logger.log(f"Found target port: {port} at index {i}")
                    break
            
            if target_port is not None:
                self.midiout.open_port(target_port)
                self.connected = True
                self.logger.log(f"✓ Connected to MIDI port: {available_ports[target_port]}")
                self.connection_status.config(text="Connected", fg="green")
                return True
            else:
                # Try to create a virtual port (may not work on Windows)
                try:
                    self.midiout.open_virtual_port(f"{self.port_name} Simulator")
                    self.connected = True
                    self.logger.log(f"✓ Created virtual MIDI port: {self.port_name} Simulator")
                    self.connection_status.config(text="Virtual Port Created", fg="orange")
                    return True
                except Exception as ve:
                    self.logger.log(f"✗ Failed to create virtual port: {ve}")
                    
            # If we get here, connection failed
            self.connected = False
            self.connection_status.config(text="Not Connected", fg="red")
            self.logger.log("✗ No suitable MIDI port found")
            messagebox.showwarning(
                "MIDI Connection", 
                f"Could not find '{self.port_name}' port.\n"
                "Please ensure loopMIDI is running with a port named 'Yamaha 02R96-1 1'"
            )
            return False
            
        except Exception as e:
            self.connected = False
            self.connection_status.config(text="Error", fg="red")
            self.logger.log(f"✗ MIDI connection error: {e}")
            messagebox.showerror("MIDI Error", f"Failed to connect to MIDI: {e}")
            return False
    
    def setup_gui(self):
        """Create the main GUI interface"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Connection status
        status_frame = ttk.Frame(main_frame)
        status_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        ttk.Label(status_frame, text="MIDI Status:").grid(row=0, column=0, padx=(0, 5))
        self.connection_status = tk.Label(status_frame, text="Connecting...", fg="orange")
        self.connection_status.grid(row=0, column=1, padx=(0, 20))
        
        ttk.Button(status_frame, text="Reconnect", command=self.connect_to_midi_port).grid(row=0, column=2)
        
        # Create notebook for tabs
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        
        # Create tabs
        self.create_volume_tab()
        self.create_mute_solo_tab()
        self.create_pan_tab()
        self.create_positioning_tab()
        self.create_testing_tab()
        
        # Log area
        log_frame = ttk.LabelFrame(main_frame, text="MIDI Log", padding="5")
        log_frame.grid(row=2, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(10, 0))
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=8, width=80)
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Create logger
        self.logger = MIDILogger(self.log_text)
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(1, weight=1)
        main_frame.rowconfigure(2, weight=1)
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
    
    def create_volume_tab(self):
        """Create the volume control tab"""
        volume_frame = ttk.Frame(self.notebook)
        self.notebook.add(volume_frame, text="Volume")
        
        # Master volume
        master_frame = ttk.LabelFrame(volume_frame, text="Master Volume", padding="10")
        master_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        self.master_volume = tk.IntVar(value=100)
        ttk.Scale(master_frame, from_=0, to=127, orient=tk.HORIZONTAL, 
                 variable=self.master_volume, command=self.on_master_volume_change).grid(row=0, column=0, sticky=(tk.W, tk.E), padx=(0, 10))
        ttk.Label(master_frame, textvariable=self.master_volume).grid(row=0, column=1)
        
        master_frame.columnconfigure(0, weight=1)
        
        # Track volumes (1-24)
        tracks1_frame = ttk.LabelFrame(volume_frame, text="Tracks 1-24", padding="10")
        tracks1_frame.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 5))
        
        self.track_volumes_1_24 = {}
        for i in range(24):
            track_num = i + 1
            row = i // 6
            col = i % 6
            
            frame = ttk.Frame(tracks1_frame)
            frame.grid(row=row*2, column=col, padx=5, pady=5)
            
            ttk.Label(frame, text=f"T{track_num}").grid(row=0, column=0)
            
            var = tk.IntVar(value=100)
            self.track_volumes_1_24[track_num] = var
            
            scale = ttk.Scale(frame, from_=0, to=127, orient=tk.VERTICAL, length=100,
                            variable=var, command=lambda val, t=track_num: self.on_track_volume_change(t, val))
            scale.grid(row=1, column=0)
            
            ttk.Label(frame, textvariable=var, width=3).grid(row=2, column=0)
        
        # Track volumes (25-48)
        tracks2_frame = ttk.LabelFrame(volume_frame, text="Tracks 25-48", padding="10")
        tracks2_frame.grid(row=1, column=1, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(5, 0))
        
        self.track_volumes_25_48 = {}
        for i in range(24):
            track_num = i + 25
            row = i // 6
            col = i % 6
            
            frame = ttk.Frame(tracks2_frame)
            frame.grid(row=row*2, column=col, padx=5, pady=5)
            
            ttk.Label(frame, text=f"T{track_num}").grid(row=0, column=0)
            
            var = tk.IntVar(value=100)
            self.track_volumes_25_48[track_num] = var
            
            scale = ttk.Scale(frame, from_=0, to=127, orient=tk.VERTICAL, length=100,
                            variable=var, command=lambda val, t=track_num: self.on_track_volume_change(t, val))
            scale.grid(row=1, column=0)
            
            ttk.Label(frame, textvariable=var, width=3).grid(row=2, column=0)
        
        volume_frame.columnconfigure(0, weight=1)
        volume_frame.columnconfigure(1, weight=1)
        volume_frame.rowconfigure(1, weight=1)
    
    def create_mute_solo_tab(self):
        """Create the mute/solo control tab"""
        mute_solo_frame = ttk.Frame(self.notebook)
        self.notebook.add(mute_solo_frame, text="Mute/Solo")
        
        # Tracks 1-24
        tracks1_frame = ttk.LabelFrame(mute_solo_frame, text="Tracks 1-24", padding="10")
        tracks1_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 5))
        
        for i in range(24):
            track_num = i + 1
            row = i // 6
            col = i % 6
            
            frame = ttk.Frame(tracks1_frame)
            frame.grid(row=row*3, column=col, padx=5, pady=5)
            
            ttk.Label(frame, text=f"Track {track_num}").grid(row=0, column=0, columnspan=2)
            
            # Mute button
            mute_btn = ttk.Button(frame, text="Mute", width=6,
                                command=lambda t=track_num: self.toggle_mute(t))
            mute_btn.grid(row=1, column=0, padx=(0, 2))
            
            # Solo button
            solo_btn = ttk.Button(frame, text="Solo", width=6,
                                command=lambda t=track_num: self.toggle_solo(t))
            solo_btn.grid(row=1, column=1, padx=(2, 0))
        
        # Tracks 25-48
        tracks2_frame = ttk.LabelFrame(mute_solo_frame, text="Tracks 25-48", padding="10")
        tracks2_frame.grid(row=0, column=1, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(5, 0))
        
        for i in range(24):
            track_num = i + 25
            row = i // 6
            col = i % 6
            
            frame = ttk.Frame(tracks2_frame)
            frame.grid(row=row*3, column=col, padx=5, pady=5)
            
            ttk.Label(frame, text=f"Track {track_num}").grid(row=0, column=0, columnspan=2)
            
            # Mute button
            mute_btn = ttk.Button(frame, text="Mute", width=6,
                                command=lambda t=track_num: self.toggle_mute(t))
            mute_btn.grid(row=1, column=0, padx=(0, 2))
            
            # Solo button
            solo_btn = ttk.Button(frame, text="Solo", width=6,
                                command=lambda t=track_num: self.toggle_solo(t))
            solo_btn.grid(row=1, column=1, padx=(2, 0))
        
        mute_solo_frame.columnconfigure(0, weight=1)
        mute_solo_frame.columnconfigure(1, weight=1)
        mute_solo_frame.rowconfigure(0, weight=1)
    
    def create_pan_tab(self):
        """Create the pan control tab"""
        pan_frame = ttk.Frame(self.notebook)
        self.notebook.add(pan_frame, text="Pan")
        
        # Tracks 1-24
        tracks1_frame = ttk.LabelFrame(pan_frame, text="Tracks 1-24", padding="10")
        tracks1_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 5))
        
        self.track_pans_1_24 = {}
        for i in range(24):
            track_num = i + 1
            row = i // 6
            col = i % 6
            
            frame = ttk.Frame(tracks1_frame)
            frame.grid(row=row*2, column=col, padx=5, pady=5)
            
            ttk.Label(frame, text=f"T{track_num}").grid(row=0, column=0)
            
            var = tk.IntVar(value=64)  # Center
            self.track_pans_1_24[track_num] = var
            
            scale = ttk.Scale(frame, from_=0, to=127, orient=tk.HORIZONTAL, length=80,
                            variable=var, command=lambda val, t=track_num: self.on_track_pan_change(t, val))
            scale.grid(row=1, column=0)
            
            ttk.Label(frame, textvariable=var, width=3).grid(row=2, column=0)
        
        # Tracks 25-48
        tracks2_frame = ttk.LabelFrame(pan_frame, text="Tracks 25-48", padding="10")
        tracks2_frame.grid(row=0, column=1, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(5, 0))
        
        self.track_pans_25_48 = {}
        for i in range(24):
            track_num = i + 25
            row = i // 6
            col = i % 6
            
            frame = ttk.Frame(tracks2_frame)
            frame.grid(row=row*2, column=col, padx=5, pady=5)
            
            ttk.Label(frame, text=f"T{track_num}").grid(row=0, column=0)
            
            var = tk.IntVar(value=64)  # Center
            self.track_pans_25_48[track_num] = var
            
            scale = ttk.Scale(frame, from_=0, to=127, orient=tk.HORIZONTAL, length=80,
                            variable=var, command=lambda val, t=track_num: self.on_track_pan_change(t, val))
            scale.grid(row=1, column=0)
            
            ttk.Label(frame, textvariable=var, width=3).grid(row=2, column=0)
        
        pan_frame.columnconfigure(0, weight=1)
        pan_frame.columnconfigure(1, weight=1)
        pan_frame.rowconfigure(0, weight=1)
    
    def create_positioning_tab(self):
        """Create the 3D positioning control tab"""
        pos_frame = ttk.Frame(self.notebook)
        self.notebook.add(pos_frame, text="3D Position")
        
        # Track selection
        select_frame = ttk.Frame(pos_frame)
        select_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Label(select_frame, text="Track:").grid(row=0, column=0, padx=(0, 5))
        self.position_track = tk.IntVar(value=1)
        track_spin = ttk.Spinbox(select_frame, from_=1, to=48, textvariable=self.position_track, width=5)
        track_spin.grid(row=0, column=1)
        
        # Position controls
        controls_frame = ttk.LabelFrame(pos_frame, text="Position Controls", padding="10")
        controls_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # X Position
        ttk.Label(controls_frame, text="X Position (-63 to +63):").grid(row=0, column=0, sticky=tk.W)
        self.pos_x = tk.IntVar(value=0)
        x_scale = ttk.Scale(controls_frame, from_=-63, to=63, orient=tk.HORIZONTAL, length=300,
                          variable=self.pos_x, command=self.on_position_x_change)
        x_scale.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(5, 10))
        ttk.Label(controls_frame, textvariable=self.pos_x).grid(row=1, column=1, padx=(10, 0))
        
        # Y Position
        ttk.Label(controls_frame, text="Y Position (-63 to +63):").grid(row=2, column=0, sticky=tk.W)
        self.pos_y = tk.IntVar(value=0)
        y_scale = ttk.Scale(controls_frame, from_=-63, to=63, orient=tk.HORIZONTAL, length=300,
                          variable=self.pos_y, command=self.on_position_y_change)
        y_scale.grid(row=3, column=0, sticky=(tk.W, tk.E), pady=(5, 10))
        ttk.Label(controls_frame, textvariable=self.pos_y).grid(row=3, column=1, padx=(10, 0))
        
        # Quick position buttons
        quick_frame = ttk.LabelFrame(pos_frame, text="Quick Positions", padding="10")
        quick_frame.grid(row=2, column=0, sticky=(tk.W, tk.E))
        
        positions = [
            ("Center", 0, 0),
            ("Front Left", -30, -30),
            ("Front Right", 30, -30),
            ("Back Left", -30, 30),
            ("Back Right", 30, 30),
            ("Reset", 0, 0)
        ]
        
        for i, (name, x, y) in enumerate(positions):
            btn = ttk.Button(quick_frame, text=name, 
                           command=lambda x=x, y=y: self.set_quick_position(x, y))
            btn.grid(row=i//3, column=i%3, padx=5, pady=5, sticky=(tk.W, tk.E))
        
        pos_frame.columnconfigure(0, weight=1)
        controls_frame.columnconfigure(0, weight=1)
        for i in range(3):
            quick_frame.columnconfigure(i, weight=1)
    
    def create_testing_tab(self):
        """Create the testing/demo tab"""
        test_frame = ttk.Frame(self.notebook)
        self.notebook.add(test_frame, text="Testing")
        
        # Test buttons
        tests_frame = ttk.LabelFrame(test_frame, text="Test Functions", padding="10")
        tests_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Button(tests_frame, text="Test All Track Volumes", 
                  command=self.test_all_volumes).grid(row=0, column=0, padx=5, pady=5, sticky=(tk.W, tk.E))
        ttk.Button(tests_frame, text="Test All Mutes", 
                  command=self.test_all_mutes).grid(row=0, column=1, padx=5, pady=5, sticky=(tk.W, tk.E))
        ttk.Button(tests_frame, text="Test All Solos", 
                  command=self.test_all_solos).grid(row=1, column=0, padx=5, pady=5, sticky=(tk.W, tk.E))
        ttk.Button(tests_frame, text="Test All Pans", 
                  command=self.test_all_pans).grid(row=1, column=1, padx=5, pady=5, sticky=(tk.W, tk.E))
        ttk.Button(tests_frame, text="Test Positioning", 
                  command=self.test_positioning).grid(row=2, column=0, padx=5, pady=5, sticky=(tk.W, tk.E))
        ttk.Button(tests_frame, text="Reset All", 
                  command=self.reset_all_controls).grid(row=2, column=1, padx=5, pady=5, sticky=(tk.W, tk.E))
        
        for i in range(2):
            tests_frame.columnconfigure(i, weight=1)
        
        # Manual MIDI send
        manual_frame = ttk.LabelFrame(test_frame, text="Manual MIDI Send", padding="10")
        manual_frame.grid(row=1, column=0, sticky=(tk.W, tk.E))
        
        # CC Message
        cc_frame = ttk.Frame(manual_frame)
        cc_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Label(cc_frame, text="CC Message:").grid(row=0, column=0, padx=(0, 5))
        ttk.Label(cc_frame, text="Channel:").grid(row=0, column=1, padx=(10, 5))
        self.manual_channel = tk.IntVar(value=0)
        ttk.Spinbox(cc_frame, from_=0, to=15, textvariable=self.manual_channel, width=5).grid(row=0, column=2)
        
        ttk.Label(cc_frame, text="Controller:").grid(row=0, column=3, padx=(10, 5))
        self.manual_controller = tk.IntVar(value=1)
        ttk.Spinbox(cc_frame, from_=0, to=127, textvariable=self.manual_controller, width=5).grid(row=0, column=4)
        
        ttk.Label(cc_frame, text="Value:").grid(row=0, column=5, padx=(10, 5))
        self.manual_value = tk.IntVar(value=64)
        ttk.Spinbox(cc_frame, from_=0, to=127, textvariable=self.manual_value, width=5).grid(row=0, column=6)
        
        ttk.Button(cc_frame, text="Send CC", command=self.send_manual_cc).grid(row=0, column=7, padx=(10, 0))
        
        test_frame.columnconfigure(0, weight=1)
        manual_frame.columnconfigure(0, weight=1)
    
    # MIDI Sending Methods
    def send_cc_message(self, channel: int, controller: int, value: int):
        """Send a Control Change message"""
        if not self.connected:
            self.logger.log("✗ Error: Not connected to MIDI port")
            return
        
        try:
            # MIDI CC: Status byte (0xB0 + channel), Controller, Value
            message = [0xB0 + channel, controller, value]
            self.midiout.send_message(message)
            self.logger.log(f"→ CC: Ch={channel}, CC={controller}, Val={value}")
        except Exception as e:
            self.logger.log(f"✗ Error sending CC message: {e}")
    
    def send_sysex_message(self, data: List[int]):
        """Send a System Exclusive message"""
        if not self.connected:
            self.logger.log("✗ Error: Not connected to MIDI port")
            return
        
        try:
            self.midiout.send_message(data)
            data_hex = ' '.join([f'{b:02X}' for b in data])
            self.logger.log(f"→ SysEx: {data_hex}")
        except Exception as e:
            self.logger.log(f"✗ Error sending SysEx message: {e}")
    
    def send_track_volume(self, track: int, value: int):
        """Send volume control for a specific track (1-48)"""
        if 1 <= track <= 24:
            # Tracks 1-24 on channel 0, controllers 1-24
            self.send_cc_message(0, track, value)
        elif 25 <= track <= 48:
            # Tracks 25-48 on channel 1, controllers 1-24
            self.send_cc_message(1, track - 24, value)
        else:
            self.logger.log(f"✗ Invalid track number: {track} (must be 1-48)")
    
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
            self.logger.log(f"✗ Invalid track number: {track} (must be 1-48)")
    
    def send_track_solo(self, track: int, solo: bool):
        """Send solo control for a specific track (1-48)"""
        if not (1 <= track <= 48):
            self.logger.log(f"✗ Invalid track number: {track} (must be 1-48)")
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
            self.logger.log(f"✗ Invalid track number: {track} (must be 1-48)")
    def send_position_x(self, track: int, value: int):
        """Send X position control for a specific track (1-48)"""
        if not (1 <= track <= 48):
            self.logger.log(f"✗ Invalid track number: {track} (must be 1-48)")
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
            self.logger.log(f"✗ Invalid track number: {track} (must be 1-48)")
            return
        
        # Convert value to 4-byte format (same format as X position)
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
        
        # SysEx pattern: F0 43 10 3E 7F 01 25 06 [track] [b1] [b2] [b3] [b4] F7
        sysex_data = [
            0xF0, 0x43, 0x10, 0x3E, 0x7F, 0x01, 0x25, 0x06,
            track_byte, b1, b2, b3, b4, 0xF7
        ]
        self.send_sysex_message(sysex_data)
    
    # GUI Event Handlers
    def on_master_volume_change(self, value):
        """Handle master volume slider change"""
        val = int(float(value))
        self.send_master_volume(val)
    
    def on_track_volume_change(self, track: int, value):
        """Handle track volume slider change"""
        val = int(float(value))
        self.send_track_volume(track, val)
    
    def toggle_mute(self, track: int):
        """Toggle mute state for a track"""
        current_state = self.mute_states.get(track, False)
        new_state = not current_state
        self.mute_states[track] = new_state
        self.send_track_mute(track, new_state)
        
        # Update button appearance would go here if we stored button references
        self.logger.log(f"Track {track} mute: {'ON' if new_state else 'OFF'}")
    
    def toggle_solo(self, track: int):
        """Toggle solo state for a track"""
        current_state = self.solo_states.get(track, False)
        new_state = not current_state
        self.solo_states[track] = new_state
        self.send_track_solo(track, new_state)
        
        # Update button appearance would go here if we stored button references
        self.logger.log(f"Track {track} solo: {'ON' if new_state else 'OFF'}")
    
    def on_track_pan_change(self, track: int, value):
        """Handle track pan slider change"""
        val = int(float(value))
        self.send_track_pan(track, val)
    
    def on_position_x_change(self, value):
        """Handle X position slider change"""
        val = int(float(value))
        track = self.position_track.get()
        self.send_position_x(track, val)
    
    def on_position_y_change(self, value):
        """Handle Y position slider change"""
        val = int(float(value))
        track = self.position_track.get()
        self.send_position_y(track, val)
    
    def set_quick_position(self, x: int, y: int):
        """Set a quick position"""
        self.pos_x.set(x)
        self.pos_y.set(y)
        track = self.position_track.get()
        self.send_position_x(track, x)
        self.send_position_y(track, y)
    
    def send_manual_cc(self):
        """Send a manually configured CC message"""
        channel = self.manual_channel.get()
        controller = self.manual_controller.get()
        value = self.manual_value.get()
        self.send_cc_message(channel, controller, value)
    
    # Test Functions
    def test_all_volumes(self):
        """Test volume controls for all tracks"""
        self.logger.log("Testing all track volumes...")
        for track in range(1, 49):
            self.send_track_volume(track, 100)
            time.sleep(0.1)
        self.send_master_volume(127)
        self.logger.log("Volume test complete")
    
    def test_all_mutes(self):
        """Test mute controls for all tracks"""
        self.logger.log("Testing all track mutes...")
        for track in range(1, 49):
            self.send_track_mute(track, True)
            time.sleep(0.05)
        time.sleep(1)
        for track in range(1, 49):
            self.send_track_mute(track, False)
            time.sleep(0.05)
        self.logger.log("Mute test complete")
    
    def test_all_solos(self):
        """Test solo controls for all tracks"""
        self.logger.log("Testing all track solos...")
        for track in range(1, 49):
            self.send_track_solo(track, True)
            time.sleep(0.1)
            self.send_track_solo(track, False)
        self.logger.log("Solo test complete")
    
    def test_all_pans(self):
        """Test pan controls for all tracks"""
        self.logger.log("Testing all track pans...")
        for track in range(1, 49):
            self.send_track_pan(track, 0)   # Left
            time.sleep(0.05)
            self.send_track_pan(track, 127) # Right
            time.sleep(0.05)
            self.send_track_pan(track, 64)  # Center
            time.sleep(0.05)
        self.logger.log("Pan test complete")
    
    def test_positioning(self):
        """Test 3D positioning for track 1"""
        self.logger.log("Testing 3D positioning for track 1...")
        positions = [(-30, -30), (30, -30), (30, 30), (-30, 30), (0, 0)]
        for x, y in positions:
            self.send_position_x(1, x)
            self.send_position_y(1, y)
            time.sleep(0.5)
        self.logger.log("Positioning test complete")
    
    def reset_all_controls(self):
        """Reset all controls to default values"""
        self.logger.log("Resetting all controls...")
        
        # Reset volumes
        for track in range(1, 49):
            self.send_track_volume(track, 100)
        self.send_master_volume(100)
        
        # Reset mutes and solos
        for track in range(1, 49):
            self.send_track_mute(track, False)
            self.send_track_solo(track, False)
        
        # Reset pans
        for track in range(1, 49):
            self.send_track_pan(track, 64)
        
        # Reset positions
        for track in range(1, 49):
            self.send_position_x(track, 0)
            self.send_position_y(track, 0)
        
        # Reset GUI controls
        self.master_volume.set(100)
        for var in self.track_volumes_1_24.values():
            var.set(100)
        for var in self.track_volumes_25_48.values():
            var.set(100)
        for var in self.track_pans_1_24.values():
            var.set(64)
        for var in self.track_pans_25_48.values():
            var.set(64)
        self.pos_x.set(0)
        self.pos_y.set(0)
        
        # Reset internal states
        self.mute_states.clear()
        self.solo_states.clear()
        
        self.logger.log("Reset complete")
    
    def run(self):
        """Start the GUI application"""
        self.logger.log("Yamaha 02R96-1 MIDI Simulator started")
        self.logger.log("Available tabs: Volume, Mute/Solo, Pan, 3D Position, Testing")
        self.root.mainloop()
    
    def __del__(self):
        """Cleanup on deletion"""
        if hasattr(self, 'midiout') and self.midiout:
            try:
                self.midiout.close_port()
            except:
                pass

def main():
    """Main entry point"""
    try:
        app = YamahaSimulatorGUI()
        app.run()
    except KeyboardInterrupt:
        print("\nShutting down simulator...")
    except Exception as e:
        print(f"Error starting simulator: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
