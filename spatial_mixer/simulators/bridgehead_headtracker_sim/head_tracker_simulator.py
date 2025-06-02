#!/usr/bin/env python3
"""
Head Tracking Device Simulator
Simulates a head tracking device with roll, yaw, and pitch controls.
Sends OSC messages with pattern /ypr -yaw,-pitch,roll to port 9000.
"""

import tkinter as tk
from tkinter import ttk
import threading
import time
import math
from pythonosc import udp_client

class HeadTrackerSimulator:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Head Tracker Simulator")
        self.root.geometry("400x300")
        self.root.resizable(True, True)
        
        # OSC client setup
        self.osc_client = udp_client.SimpleUDPClient("127.0.0.1", 9100)
        
        # Head tracking values (in degrees)
        self.yaw = tk.DoubleVar(value=0.0)
        self.pitch = tk.DoubleVar(value=0.0)
        self.roll = tk.DoubleVar(value=0.0)
        
        # Send rate control
        self.send_rate = tk.DoubleVar(value=30.0)  # Hz
        self.is_sending = tk.BooleanVar(value=False)
        
        self.setup_gui()
        self.osc_thread = None
        
    def setup_gui(self):
        """Setup the GUI interface"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
        # Title
        title_label = ttk.Label(main_frame, text="Head Tracker Simulator", 
                               font=("Arial", 14, "bold"))
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 20))
        
        # Yaw control
        ttk.Label(main_frame, text="Yaw:").grid(row=1, column=0, sticky=tk.W, pady=5)
        yaw_scale = ttk.Scale(main_frame, from_=-180, to=180, orient=tk.HORIZONTAL, 
                             variable=self.yaw, length=200)
        yaw_scale.grid(row=1, column=1, sticky=(tk.W, tk.E), padx=(10, 5), pady=5)
        yaw_value = ttk.Label(main_frame, text="0.0°")
        yaw_value.grid(row=1, column=2, sticky=tk.W, pady=5)
        
        # Pitch control
        ttk.Label(main_frame, text="Pitch:").grid(row=2, column=0, sticky=tk.W, pady=5)
        pitch_scale = ttk.Scale(main_frame, from_=-180, to=180, orient=tk.HORIZONTAL, 
                               variable=self.pitch, length=200)
        pitch_scale.grid(row=2, column=1, sticky=(tk.W, tk.E), padx=(10, 5), pady=5)
        pitch_value = ttk.Label(main_frame, text="0.0°")
        pitch_value.grid(row=2, column=2, sticky=tk.W, pady=5)
        
        # Roll control
        ttk.Label(main_frame, text="Roll:").grid(row=3, column=0, sticky=tk.W, pady=5)
        roll_scale = ttk.Scale(main_frame, from_=-180, to=180, orient=tk.HORIZONTAL, 
                              variable=self.roll, length=200)
        roll_scale.grid(row=3, column=1, sticky=(tk.W, tk.E), padx=(10, 5), pady=5)
        roll_value = ttk.Label(main_frame, text="0.0°")
        roll_value.grid(row=3, column=2, sticky=tk.W, pady=5)
        
        # Send rate control
        ttk.Label(main_frame, text="Send Rate:").grid(row=4, column=0, sticky=tk.W, pady=5)
        rate_scale = ttk.Scale(main_frame, from_=1, to=60, orient=tk.HORIZONTAL, 
                              variable=self.send_rate, length=200)
        rate_scale.grid(row=4, column=1, sticky=(tk.W, tk.E), padx=(10, 5), pady=5)
        rate_value = ttk.Label(main_frame, text="30 Hz")
        rate_value.grid(row=4, column=2, sticky=tk.W, pady=5)
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=5, column=0, columnspan=3, pady=20)
        
        self.start_button = ttk.Button(button_frame, text="Start Sending", 
                                      command=self.start_sending)
        self.start_button.pack(side=tk.LEFT, padx=5)
        
        self.stop_button = ttk.Button(button_frame, text="Stop Sending", 
                                     command=self.stop_sending, state=tk.DISABLED)
        self.stop_button.pack(side=tk.LEFT, padx=5)
        
        reset_button = ttk.Button(button_frame, text="Reset", command=self.reset_values)
        reset_button.pack(side=tk.LEFT, padx=5)
          # Status and info
        self.status_label = ttk.Label(main_frame, text="Status: Stopped", 
                                     foreground="red")
        self.status_label.grid(row=6, column=0, columnspan=3, pady=10)
        
        info_label = ttk.Label(main_frame, text="OSC Pattern: /ypr -yaw,-pitch,roll → 127.0.0.1:9100", 
                              font=("Arial", 9), foreground="gray")
        info_label.grid(row=7, column=0, columnspan=3, pady=5)
        
        # Store value labels for updates
        self.value_labels = {
            'yaw': yaw_value,
            'pitch': pitch_value,
            'roll': roll_value,
            'rate': rate_value
        }
        
        # Bind value change events
        self.yaw.trace('w', self.update_value_labels)
        self.pitch.trace('w', self.update_value_labels)
        self.roll.trace('w', self.update_value_labels)
        self.send_rate.trace('w', self.update_value_labels)
        
        # Initial label update
        self.update_value_labels()
        
    def update_value_labels(self, *args):
        """Update the value labels when sliders change"""
        self.value_labels['yaw'].config(text=f"{self.yaw.get():.1f}°")
        self.value_labels['pitch'].config(text=f"{self.pitch.get():.1f}°")
        self.value_labels['roll'].config(text=f"{self.roll.get():.1f}°")
        self.value_labels['rate'].config(text=f"{int(self.send_rate.get())} Hz")
        
    def reset_values(self):
        """Reset all values to zero"""
        self.yaw.set(0.0)
        self.pitch.set(0.0)
        self.roll.set(0.0)
        
    def start_sending(self):
        """Start sending OSC messages"""
        if not self.is_sending.get():
            self.is_sending.set(True)
            self.start_button.config(state=tk.DISABLED)
            self.stop_button.config(state=tk.NORMAL)
            self.status_label.config(text="Status: Sending", foreground="green")
            
            # Start OSC sending thread
            self.osc_thread = threading.Thread(target=self.osc_sender_loop, daemon=True)
            self.osc_thread.start()
            
    def stop_sending(self):
        """Stop sending OSC messages"""
        self.is_sending.set(False)
        self.start_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)
        self.status_label.config(text="Status: Stopped", foreground="red")
        
    def osc_sender_loop(self):
        """Main loop for sending OSC messages"""
        while self.is_sending.get():           
            try:
                # Get current values in degrees
                yaw_val = self.yaw.get()
                pitch_val = self.pitch.get()
                roll_val = self.roll.get()
                
                # Send OSC message with pattern /ypr -yaw,-pitch,roll (in degrees)
                self.osc_client.send_message("/ypr", [-yaw_val, -pitch_val, roll_val])
                
                # Calculate sleep time based on send rate
                sleep_time = 1.0 / self.send_rate.get()
                time.sleep(sleep_time)
                
            except Exception as e:
                print(f"Error sending OSC message: {e}")
                # Small delay before retrying
                time.sleep(0.1)
                
    def run(self):
        """Start the GUI application"""
        try:
            print("Head Tracker Simulator starting...")
            print("OSC messages will be sent to 127.0.0.1:9100")
            print("Pattern: /ypr -yaw,-pitch,roll")
            print("GUI ready.")
            self.root.mainloop()
        except KeyboardInterrupt:
            print("\nShutting down...")
        finally:
            self.is_sending.set(False)

if __name__ == "__main__":
    # Check if required modules are available
    try:
        import pythonosc
    except ImportError:
        print("Error: python-osc module not found!")
        print("Please install it with: pip install python-osc")
        exit(1)
    
    # Create and run the simulator
    simulator = HeadTrackerSimulator()
    simulator.run()
