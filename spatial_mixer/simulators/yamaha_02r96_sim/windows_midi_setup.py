#!/usr/bin/env python3
"""
Windows MIDI Setup Helper

This script helps set up MIDI simulation on Windows by:
1. Checking for available MIDI ports
2. Providing download links for required software
3. Testing MIDI connections
"""

import rtmidi
import webbrowser
import sys

def check_midi_setup():
    """Check current MIDI setup and provide guidance"""
    print("🎹 Windows MIDI Setup Helper")
    print("=" * 40)
    
    # Check available MIDI outputs
    midiout = rtmidi.MidiOut()
    available_ports = midiout.get_ports()
    
    print(f"📋 Available MIDI Output Ports ({len(available_ports)}):")
    if not available_ports:
        print("   ❌ No MIDI ports found")
    else:
        for i, port in enumerate(available_ports):
            print(f"   {i}: {port}")
    
    # Check for Yamaha or loopMIDI ports
    suitable_ports = []
    for i, port in enumerate(available_ports):
        if any(keyword in port.lower() for keyword in ["yamaha", "02r96", "loopmidi"]):
            suitable_ports.append((i, port))
    
    print(f"\n🎯 Suitable Ports for Simulation ({len(suitable_ports)}):")
    if not suitable_ports:
        print("   ❌ No suitable ports found")
        print("\n💡 Recommendations:")
        print("   1. Install loopMIDI (creates virtual MIDI ports)")
        print("   2. Create a port named 'Yamaha 02R96-1'")
        print("   3. Run this script again to verify")
        
        choice = input("\n📥 Would you like to download loopMIDI now? (y/n): ").lower()
        if choice == 'y':
            print("🌐 Opening loopMIDI download page...")
            webbrowser.open("https://www.tobias-erichsen.de/software/loopmidi.html")
        
        return False
    else:
        for i, port in suitable_ports:
            print(f"   ✅ {i}: {port}")
        
        print("\n🎉 Great! You have suitable MIDI ports available.")
        return True

def test_midi_connection():
    """Test MIDI connection with available ports"""
    print("\n🧪 Testing MIDI Connection...")
    
    midiout = rtmidi.MidiOut()
    available_ports = midiout.get_ports()
    
    if not available_ports:
        print("❌ No MIDI ports available for testing")
        return False
    
    # Find best port to test
    test_port = None
    test_port_name = ""
    
    # Look for Yamaha or loopMIDI first
    for i, port in enumerate(available_ports):
        if any(keyword in port.lower() for keyword in ["yamaha", "02r96", "loopmidi"]):
            test_port = i
            test_port_name = port
            break
    
    # If no specific port found, use first available
    if test_port is None and available_ports:
        test_port = 0
        test_port_name = available_ports[0]
    
    try:
        print(f"🔌 Connecting to: {test_port_name}")
        midiout.open_port(test_port)
        
        print("📤 Sending test MIDI message...")
        # Send a simple CC message (Channel 0, Controller 1, Value 64)
        test_message = [0xB0, 1, 64]
        midiout.send_message(test_message)
        
        print("✅ MIDI test successful!")
        print(f"   Sent: Control Change (Ch=0, CC=1, Val=64)")
        
        midiout.close_port()
        return True
        
    except Exception as e:
        print(f"❌ MIDI test failed: {e}")
        return False

def provide_setup_instructions():
    """Provide detailed setup instructions"""
    print("\n📖 Windows MIDI Setup Instructions")
    print("=" * 40)
    
    print("\n1️⃣ Install loopMIDI:")
    print("   • Download from: https://www.tobias-erichsen.de/software/loopmidi.html")
    print("   • Install and run the application")
    print("   • It will appear in your system tray")
    
    print("\n2️⃣ Create Virtual MIDI Port:")
    print("   • Open loopMIDI from system tray")
    print("   • In 'New port-name' field, enter: Yamaha 02R96-1")
    print("   • Click the '+' button to create the port")
    print("   • The port should appear in the list")
    
    print("\n3️⃣ Test Your Setup:")
    print("   • Run this script again: python windows_midi_setup.py")
    print("   • Or run the simulator: python yamaha_02r96_simulator_gui.py")
    
    print("\n4️⃣ Configure Your Processing Sketch:")
    print("   • Make sure your Processing sketch looks for 'Yamaha 02R96-1'")
    print("   • The simulator will connect to this port automatically")
    
    print("\n🆘 Troubleshooting:")
    print("   • If ports don't appear: Restart loopMIDI")
    print("   • If connection fails: Check port name spelling")
    print("   • If still issues: Try running as administrator")

def main():
    """Main setup function"""
    try:
        # Check current setup
        has_suitable_ports = check_midi_setup()
        
        if has_suitable_ports:
            # Test connection
            connection_works = test_midi_connection()
            
            if connection_works:
                print("\n🎉 Your MIDI setup is ready!")
                print("You can now run the Yamaha simulator:")
                print("   python yamaha_02r96_simulator_gui.py")
                print("   python yamaha_02r96_simulator.py")
            else:
                print("\n⚠️ MIDI ports found but connection test failed")
                provide_setup_instructions()
        else:
            provide_setup_instructions()
    
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Install with: pip install python-rtmidi")
    except Exception as e:
        print(f"❌ Setup check failed: {e}")
    
    input("\nPress Enter to exit...")

if __name__ == "__main__":
    main()
