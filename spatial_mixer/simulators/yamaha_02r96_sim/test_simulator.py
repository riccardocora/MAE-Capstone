#!/usr/bin/env python3
"""
Quick test script to verify the new Yamaha 02R96-1 GUI simulator functionality
"""

import rtmidi
import time

def test_midi_connection():
    """Test if we can connect to the Yamaha MIDI port"""
    print("🎵 Yamaha 02R96-1 MIDI Simulator Test")
    print("=" * 50)
    
    # Check for MIDI input ports (what our Processing sketch would see)
    midiin = rtmidi.MidiIn()
    input_ports = midiin.get_ports()
    
    print(f"📥 Available MIDI INPUT ports:")
    for i, port in enumerate(input_ports):
        print(f"   {i}: {port}")
        if "Yamaha 02R96-1" in port:
            print(f"   ✓ Found target port: {port}")
    
    # Check for MIDI output ports (what our simulator connects to)
    midiout = rtmidi.MidiOut()
    output_ports = midiout.get_ports()
    
    print(f"\n📤 Available MIDI OUTPUT ports:")
    for i, port in enumerate(output_ports):
        print(f"   {i}: {port}")
        if "Yamaha 02R96-1" in port:
            print(f"   ✓ Found target port: {port}")
    
    # Test connection
    print(f"\n🔗 Testing MIDI connection...")
    
    target_port = None
    for i, port in enumerate(output_ports):
        if "Yamaha 02R96-1" in port:
            target_port = i
            break
    
    if target_port is not None:
        try:
            midiout.open_port(target_port)
            print(f"   ✓ Successfully connected to: {output_ports[target_port]}")
            
            # Send a test CC message
            print(f"   🎛️ Sending test CC message...")
            test_message = [0xB0, 1, 64]  # CC message: Channel 0, Controller 1, Value 64
            midiout.send_message(test_message)
            print(f"   ✓ Sent: Channel=0, Controller=1, Value=64")
            
            midiout.close_port()
            print(f"   ✓ Connection test successful!")
            return True
            
        except Exception as e:
            print(f"   ✗ Connection failed: {e}")
            return False
    else:
        print(f"   ✗ No Yamaha 02R96-1 port found")
        print(f"   💡 Make sure loopMIDI is running with 'Yamaha 02R96-1 1' port")
        print(f"   💡 Or run the simulator GUI first")
        return False

def test_message_formats():
    """Test different MIDI message formats"""
    print(f"\n🧪 Testing MIDI message formats:")
    
    # CC Message format
    cc_msg = [0xB0 + 0, 1, 127]  # Channel 0, Controller 1, Value 127
    print(f"   CC Message: {[hex(b) for b in cc_msg]} -> Ch=0, CC=1, Val=127")
    
    # SysEx Message format (Solo)
    solo_msg = [0xF0, 0x43, 0x10, 0x3E, 0x0B, 0x03, 0x2E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xF7]
    print(f"   Solo SysEx: {[hex(b) for b in solo_msg]} -> Track 1 Solo ON")
    
    # SysEx Message format (Position X)
    pos_msg = [0xF0, 0x43, 0x10, 0x3E, 0x7F, 0x01, 0x25, 0x05, 0x00, 0x00, 0x00, 0x00, 0x1E, 0xF7]
    print(f"   Position SysEx: {[hex(b) for b in pos_msg]} -> Track 1 X=+30")

def show_gui_usage():
    """Show usage instructions for the GUI"""
    print(f"\n📋 GUI Simulator Usage:")
    print(f"   1. Run: python yamaha_02r96_simulator_gui_v2.py")
    print(f"   2. Check connection status (should show 'Connected')")
    print(f"   3. Use tabs to control different functions:")
    print(f"      • Volume: Adjust master and track volumes")
    print(f"      • Mute/Solo: Toggle mute/solo for tracks")
    print(f"      • Pan: Control stereo panning")
    print(f"      • 3D Position: Set X/Y coordinates for spatial audio")
    print(f"      • Testing: Run automated tests and send custom MIDI")
    print(f"   4. Watch the MIDI Log for sent messages")
    print(f"   5. Your Processing sketch should receive these messages")

def main():
    """Main test function"""
    test_midi_connection()
    test_message_formats()
    show_gui_usage()
    
    print(f"\n🎯 Next Steps:")
    print(f"   1. Start the GUI simulator if not already running")
    print(f"   2. Start your Processing spatial mixer sketch")
    print(f"   3. Use the GUI to control the mixer parameters")
    print(f"   4. Verify the Processing sketch responds to the controls")
    
    print(f"\n✨ Test complete!")

if __name__ == "__main__":
    main()
