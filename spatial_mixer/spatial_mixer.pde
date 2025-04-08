/**
 * 3D Sound Source Visualization
 * 
 * Features:
 * - Fixed perspective view with box centered
 * - Simple cube frame boundary using box() primitive
 * - Central subject as a sphere representing a head
 * - Sound sources controlled by ControlP5 sliders
 * - Visualization of sound positions using spherical coordinates
 * - Responsive UI that adapts to window resizing
 * - Numbered sound sources for easy identification
 */

import controlP5.*;
import oscP5.*;
import netP5.*;
import themidibus.*;

// Main component managers
ControlP5 cp5;
UIManager uiManager;
CubeRenderer cubeRenderer;
MidiBus midiBus; // MIDI connection
OscP5 oscP5;   // OSC instance for receiving messages
NetAddress reaper; // NetAddress for sending messages to Reaper

MidiMappingManager midiManager; // MIDI mapping object
String midiMappingFile = "data/midi_mapping.json";

// Data structures to store track and sound source information
ArrayList<Track> tracks = new ArrayList<Track>();
ArrayList<SoundSource> soundSources = new ArrayList<SoundSource>();
int selectedSource = 0;

// Central subject
float headSize = 30;

// Cube boundary
float boundarySize = 800;

// Default values for sliders
float radius = 150;
float azimuth = 0;
float zenith = PI / 4;

Track masterTrack; // Declare a master track

void setup() {
  size(1000, 700, P3D);

  // Initialize the MIDI Mapping Manager and load the mappings
  midiManager = new MidiMappingManager();
  midiManager.loadMappings(midiMappingFile);
  
  // Initialize ControlP5
  cp5 = new ControlP5(this);
  
  // Initialize component managers
  cubeRenderer = new CubeRenderer(boundarySize);
  uiManager = new UIManager(cp5, width, height);

  // Initialize OSC
  oscP5 = new OscP5(this, 8000); // Listen on port 8000
  reaper = new NetAddress("127.0.0.1", 8001); // Send to Reaper on port 8001
  
  
  // Initialize sound sources and tracks
  for (int i = 0; i < 7; i++) {
    tracks.add(new Track(i + 1, "Track " + (i + 1), 150 + i * 70, height - 300));
    soundSources.add(new SoundSource(150, random(0, TWO_PI), random(0, PI / 2)));
  }
  
  // Initialize master track to the left of Track 1
  masterTrack = new Track(0, "Master", 70, height - 300);

  // Setup UI controls
  uiManager.setupControls(radius, azimuth, zenith, boundarySize);
  
  // Initialize MIDI connection
  MidiBus.list(); // List available MIDI devices in the console
  midiBus = new MidiBus(this, "Yamaha 02R96-1", "Yamaha 02R96-1"); // Replace with your MIDI device name
}

// Instead of Java's MidiMessage class, we'll use the MidiBus event handlers
public void controllerChange(int channel, int number, int value) {
  // Log the incoming MIDI CC message
  println("[MIDI CC] Channel: " + channel + ", Number: " + number + ", Value: " + value);
  
  // Find matching mappings for this CC message
  ArrayList<MidiMapping> matches = midiManager.findMappingsForCC(channel, number, value);
  
  for (MidiMapping mapping : matches) {
    float normalizedValue = mapping.getNormalizedValue(value);
    
    switch (mapping.action) {
      case "updateSource":
        if (selectedSource >= 0 && selectedSource < soundSources.size()) {
          SoundSource source = soundSources.get(selectedSource);
          
          if (mapping.parameter.equals("radius")) {
            float radius = map(normalizedValue, 0, 1, 50, 600);
            source.radius = radius;
            source.updatePosition();
            cp5.getController("radius").setValue(source.radius);
            sendOscVolume(selectedSource + 1, normalizedValue);
          } 
          else if (mapping.parameter.equals("azimuth")) {
            float azimuth = map(normalizedValue, 0, 1, 0, TWO_PI);
            source.azimuth = azimuth;
            source.updatePosition();
            cp5.getController("azimuth").setValue(source.azimuth);
          } 
          else if (mapping.parameter.equals("zenith")) {
            float zenith = map(normalizedValue, 0, 1, 0, PI);
            source.zenith = zenith;
            source.updatePosition();
            cp5.getController("zenith").setValue(source.zenith);
          }
        }
        break;
        
      case "selectSource":
        // Only trigger source selection when value is in the active range
        if (mapping instanceof CCMapping) {
          CCMapping ccMapping = (CCMapping) mapping;
          int sourceIndex = ccMapping.getTrackNumber(number);
          if (sourceIndex >= 0 && sourceIndex < soundSources.size()) {
            selectedSource = sourceIndex;
            SoundSource source = soundSources.get(selectedSource);
            cp5.getController("radius").setValue(source.radius);
            cp5.getController("azimuth").setValue(source.azimuth);
            cp5.getController("zenith").setValue(source.zenith);
            println("Selected source: " + selectedSource);
          }
        }
        break;
        
      case "toggleMute":
        if (mapping instanceof CCMapping) {
          CCMapping ccMapping = (CCMapping) mapping;
          int trackNum = ccMapping.getTrackNumber(number);
          if (trackNum >= 0 && trackNum < tracks.size()) {
            boolean muted = value > 63; // Consider values > 63 as mute ON
            tracks.get(trackNum).setMuted(muted);
            sendOscMute(trackNum + 1, muted);
          }
        }
        break;
        
      case "toggleMasterMute":
        boolean muted = value > 63;
        masterTrack.setMuted(muted);
        sendOscMessage("/master/mute", muted ? 1 : 0);
        break;
        
      case "setTrackVolume":
        if (mapping instanceof CCMapping) {
          CCMapping ccMapping = (CCMapping) mapping;
          int trackNum = ccMapping.getTrackNumber(number);
          if (trackNum >= 0 && trackNum < tracks.size()) {
            tracks.get(trackNum).setVolume(normalizedValue);
            // If this track has a corresponding sound source, update its volume too
            if (trackNum < soundSources.size()) {
              soundSources.get(trackNum).setVolume(normalizedValue);
            }
            sendOscVolume(trackNum + 1, normalizedValue);
          }
        }
        break;
        
      case "setMasterVolume":
        masterTrack.setVolume(normalizedValue);
        sendOscMessage("/track/volume", normalizedValue);
        break;
        
      case "setPan":
        if (mapping instanceof CCMapping) {
          CCMapping ccMapping = (CCMapping) mapping;
          int trackNum = ccMapping.getTrackNumber(number);
          if (trackNum >= 0 && trackNum < tracks.size()) {
            // Convert normalized value to -1 to 1 range for pan
            float pan = map(normalizedValue, 0, 1, -1, 1);
            //tracks.get(trackNum).setPan(pan);
            sendOscPan(trackNum + 1, pan);
          }
        }
        break;
        
      case "setMasterPan":
        float pan = map(normalizedValue, 0, 1, -1, 1);
        //masterTrack.setPan(pan);
        sendOscMessage("/track/pan", pan);
        break;
    }
  }
}

// Handle raw MIDI messages for SysEx data
void rawMidi(byte[] data) {
  // Check if this is a SysEx message (starts with 0xF0)
  if (data.length > 0 && (data[0] & 0xFF) == 0xF0) {
    // Log the SysEx message
    println("[MIDI SysEx] Received SysEx message:");
    String hexString = "";
    for (int i = 0; i < data.length; i++) {
      hexString += String.format("%02X ", data[i] & 0xFF);
    }
    println(hexString.trim());
    
    // Find matching mappings for this SysEx message
    ArrayList<MidiMapping> matches = midiManager.findMappingsForSysEx(data);
    
    for (MidiMapping mapping : matches) {
      println("Found matching SysEx mapping: " + mapping.name);
      
      switch (mapping.action) {
        case "setMasterVolume":
          // Extract volume value from SysEx data
          if (data.length >= 5) {
            float volume = map(data[4] & 0xFF, 0, 127, 0, 1);
            masterTrack.setVolume(volume);
            sendOscMessage("/track/volume", volume);
          }
          break;
          
        case "toggleSolo":
          // Extract track number and solo state from SysEx data
          if (data.length >= 13) {
            int trackNum = data[8] & 0xFF;
            boolean solo = (data[12] & 0xFF) == 1;
            
            if (trackNum < tracks.size()) {
              tracks.get(trackNum).setSoloed(solo);
              sendOscSolo(trackNum + 1, solo);
            }
          }
          break;
          
        case "toggleMasterSolo":
          // Extract master solo state from SysEx data
          if (data.length >= 13) {
            boolean solo = (data[12] & 0xFF) == 1;
            masterTrack.setSoloed(solo);
            sendOscMessage("/track/solo", solo ? 1 : 0);
          }
          break;
          
        case "setPositionX":
          // Process positioning X data
          if (data.length >= 13 && data[7] == 0x05) { // Check for X position command (0x05)
            int trackNum = data[8] & 0xFF;
            
            if (trackNum < soundSources.size()) {
              // Extract the 4 bytes that represent the X position
              int xPos = parsePositionValue(data[9], data[10], data[11], data[12]);
              
              // Now we have the X position value, ranging from -63 to +63
              // We'll use it to calculate part of the spherical coordinates
              SoundSource source = soundSources.get(trackNum);
              
              // Store the X position to use later for radius calculation
              float xNormalized = map(xPos, -63, 63, -1, 1);
              
              // Update source position if we already have the Y position
              if (source.hasYPosition) {
                // Convert cartesian (x, y) to polar (azimuth, radius)
                float azimuth = atan2(source.yNormalized, xNormalized);
                float radius = sqrt(xNormalized*xNormalized + source.yNormalized*source.yNormalized) * boundarySize/2;
                
                // Adjust azimuth to the 0-2π range
                if (azimuth < 0) azimuth += TWO_PI;
                
                // Update the sound source
                source.radius = constrain(radius, 50, 600);
                source.azimuth = azimuth;
                source.updatePosition();
                
                // Update UI if this is the currently selected source
                if (trackNum == selectedSource) {
                  cp5.getController("radius").setValue(source.radius);
                  cp5.getController("azimuth").setValue(source.azimuth);
                }
                
                // Send OSC updates
                sendOscVolume(trackNum + 1, map(source.radius, 50, 600, 0, 1));
              } else {
                // Store X position for later
                source.xNormalized = xNormalized;
                source.hasXPosition = true;
              }
              
              println("Set X position for track " + trackNum + ": " + xPos + " (normalized: " + xNormalized + ")");
            }
          }
          break;
          
        case "setPositionY":
          // Process positioning Y data
          if (data.length >= 13 && data[7] == 0x06) { // Check for Y position command (0x06)
            int trackNum = data[8] & 0xFF;
            
            if (trackNum < soundSources.size()) {
              // Extract the 4 bytes that represent the Y position
              int yPos = parsePositionValue(data[9], data[10], data[11], data[12]);
              
              // Now we have the Y position value, ranging from -63 to +63
              SoundSource source = soundSources.get(trackNum);
              
              // Store the Y position to use later for radius calculation
              float yNormalized = map(yPos, -63, 63, -1, 1);
              
              // Update source position if we already have the X position
              if (source.hasXPosition) {
                // Convert cartesian (x, y) to polar (azimuth, radius)
                float azimuth = atan2(yNormalized, source.xNormalized);
                float radius = sqrt(source.xNormalized*source.xNormalized + yNormalized*yNormalized) * boundarySize/2;
                
                // Adjust azimuth to the 0-2π range
                if (azimuth < 0) azimuth += TWO_PI;
                
                // Update the sound source
                source.radius = constrain(radius, 50, 600);
                source.azimuth = azimuth;
                source.updatePosition();
                
                // Update UI if this is the currently selected source
                if (trackNum == selectedSource) {
                  cp5.getController("radius").setValue(source.radius);
                  cp5.getController("azimuth").setValue(source.azimuth);
                }
                
                // Send OSC updates
                sendOscVolume(trackNum + 1, map(source.radius, 50, 600, 0, 1));
              } else {
                // Store Y position for later
                source.yNormalized = yNormalized;
                source.hasYPosition = true;
              }
              
              println("Set Y position for track " + trackNum + ": " + yPos + " (normalized: " + yNormalized + ")");
            }
          }
          break;
          
        case "setElevation":
          // Process elevation data (this would be your separate control for zenith)
          if (data.length >= 10) {
            int trackNum = data[8] & 0xFF;
            if (trackNum < soundSources.size()) {
              // Parse the elevation data (assuming it's a single byte value)
              float zenith = map(data[9] & 0xFF, 0, 127, 0, PI);
              
              // Update the sound source
              SoundSource source = soundSources.get(trackNum);
              source.zenith = zenith;
              source.updatePosition();
              
              // Update UI if this is the currently selected source
              if (trackNum == selectedSource) {
                cp5.getController("zenith").setValue(source.zenith);
              }
              
              println("Set elevation for track " + trackNum + ": " + zenith);
            }
          }
          break;
      }
    }
  }
}

// Helper function to parse position values from 4 SysEx bytes
int parsePositionValue(byte b1, byte b2, byte b3, byte b4) {
  // The format seems to be special where:
  // 00 00 00 00 = position 0
  // 00 00 00 3F = position +63 (max)
  // 7F 7F 7F 41 = position -63 (min)
  
  int value = 0;
  
  // Check if we're in the positive range (first byte is 0)
  if ((b1 & 0xFF) == 0x00) {
    // Positive range: 0 to +63
    value = b4 & 0x7F;  // Use the last byte for the positive range
    if (value > 63) value = 63;  // Clamp to max value
  } else {
    // Negative range: -1 to -63
    // Use a scale where 7F 7F 7F 7F = -1 and 7F 7F 7F 41 = -63
    value = -((b4 & 0x7F) == 0x7F ? 1 : (0x7F - (b4 & 0x7F)));
    if (value < -63) value = -63;  // Clamp to min value
  }
  
  return value;
}
public void noteOn(int channel, int note, int velocity) {
  // Log the incoming MIDI note message
  println("[MIDI NOTE] Channel: " + channel + ", Note: " + note + ", Velocity: " + velocity);

  int sourceIndex = note - 36; // Assuming note 36 corresponds to source 0
  if (sourceIndex >= 0 && sourceIndex < soundSources.size()) {
    selectedSource = sourceIndex;
    SoundSource source = soundSources.get(selectedSource);
    cp5.getController("radius").setValue(source.radius);
    cp5.getController("azimuth").setValue(source.azimuth);
    cp5.getController("zenith").setValue(source.zenith);
  }
}

public void oscEvent(OscMessage msg) {
  try {
    println("OSC Message Received: " + msg.addrPattern() + " " + msg.typetag());
    for (int i = 0; i < msg.arguments().length; i++) {
      println("Argument " + i + ": " + msg.arguments()[i]);
    }

    String pattern = msg.addrPattern();

    // Handle master track volume updates
    if (pattern.equals("/track/volume")) {
      float volume = msg.get(0).floatValue();
      masterTrack.setVolume(volume);
    }

    // Handle master track VU meter updates
    else if (pattern.equals("/track/vu")) {
      float vuLevel = msg.get(0).floatValue();
      masterTrack.setVuLevel(vuLevel);
    }

    // Handle master track mute updates
    else if (pattern.equals("/track/mute")) {
      boolean muted = (int) msg.get(0).floatValue() == 1;
      masterTrack.setMuted(muted);
    }

    // Handle master track solo updates
    else if (pattern.equals("/track/solo")) {
      boolean soloed = (int) msg.get(0).floatValue() == 1;
      masterTrack.setSoloed(soloed);
    }

    // Handle individual track updates
    else if (pattern.matches("/track/[0-7]/volume")) {
      String[] parts = pattern.split("/");
      int trackNum = Integer.parseInt(parts[2]);

    // Extract volume value (assuming it's sent as a float between 0 and 1)
      float volume = msg.get(0).floatValue();
      tracks.get(trackNum - 1).setVolume(volume);
      soundSources.get(trackNum - 1).setVolume(volume);
    }

    // Handle track VU meter updates
    else if (pattern.matches("/track/[0-7]/vu")) {
      String[] parts = pattern.split("/");
      int trackNum = Integer.parseInt(parts[2]);

    // Extract volume value (assuming it's sent as a float between 0 and 1)
      float vuLevel = msg.get(0).floatValue();
      tracks.get(trackNum - 1).setVuLevel(vuLevel);
      soundSources.get(trackNum - 1).setVuLevel(vuLevel); // Sync VU level with sound source
    }

    // Handle track mute updates
    else if (pattern.matches("/track/[0-7]/mute/toggle")) {
      String[] parts = pattern.split("/");
      int trackNum = Integer.parseInt(parts[2]);
      boolean muted = (int)msg.get(0).floatValue() == 1;       // Ensure the value is treated as an integer
      tracks.get(trackNum - 1).setMuted(muted);
    }

    // Handle track solo updates
    else if (pattern.matches("/track/[0-7]/solo/toggle")) {
      String[] parts = pattern.split("/");
      int trackNum = Integer.parseInt(parts[2]);
      boolean soloed = (int)msg.get(0).floatValue() == 1; // Ensure the value is treated as an integer
      tracks.get(trackNum - 1).setSoloed(soloed);
    }
  } catch (Exception e) {
    println("Error processing OSC message: " + e.getMessage());
  }
}

void draw() {
  background(20, 25, 35);

  // Draw master track first
  masterTrack.draw();

  // Draw other tracks
  for (Track track : tracks) {
    track.draw();
  }

  uiManager.draw(soundSources.size(), selectedSource);
  draw3DScene();
}

void draw3DScene() {
  pushMatrix();
  
  // Center the 3D scene on the screen with a better view
  translate(width/2, height/2, -30);
  rotateX(radians(-27));  // Looking down from above at a milder angle

  scale(0.8);  // Scale down to fit better
  
  // Set up lighting
  ambientLight(50, 50, 50);
  directionalLight(200, 200, 200, -1, -1, -1);
  
  // Draw cube frame
  cubeRenderer.drawCubeFrame();
  
  // Draw coordinate system
  cubeRenderer.drawCoordinateSystem();
  
  // Draw central head (fixed at center)
  pushMatrix();
  noStroke();
  fill(220, 190, 170);
  sphere(headSize);
  popMatrix();
  
  // Draw sound sources
  for (int i = 0; i < soundSources.size(); i++) {
    SoundSource source = soundSources.get(i);
    boolean isSelected = (i == selectedSource);
    source.display(isSelected, i+1); // Pass the source number (1-indexed)
    
    // Draw line connecting source to head
    stroke(180, 180, 200, 150);
    strokeWeight(1);
    line(0, 0, 0, source.x, source.y, source.z);
  }
  
  popMatrix();
}

// Window resize handling
void windowResized() {
  uiManager.updatePositions(width, height);
}

void keyPressed() {
  // Select sound source using number keys
  if (key >= '1' && key <= '9') {
    int sourceIndex = key - '1';
    if (sourceIndex < soundSources.size()) {
      selectedSource = sourceIndex;
      
      // Update sliders to reflect the selected source
      SoundSource source = soundSources.get(selectedSource);
      cp5.getController("radius").setValue(source.radius);
      cp5.getController("azimuth").setValue(source.azimuth);
      cp5.getController("zenith").setValue(source.zenith);
    }
  }
  

}




/**
  * Send a volume message to a specific track
  */
public void sendOscVolume(int trackNumber, float volume) {
  sendOscMessage("/track/" + trackNumber + "/volume", volume);
  println("Sent volume " + volume + " to track " + trackNumber);
}

/**
  * Send a pan message to a specific track
  */
public void sendOscPan(int trackNumber, float pan) {
  sendOscMessage("/track/" + trackNumber + "/pan", pan);
  println("Sent pan " + pan + " to track " + trackNumber);
}

/**
  * Send a mute message to a specific track
  */
public void sendOscMute(int trackNumber, boolean mute) {
  sendOscMessage("/track/" + trackNumber + "/mute", mute ? 1 : 0);
  println("Sent mute " + mute + " to track " + trackNumber);
}

/**
  * Send a solo message to a specific track
  */
public void sendOscSolo(int trackNumber, boolean solo) {
  sendOscMessage("/track/" + trackNumber + "/solo", solo ? 1 : 0);
  println("Sent solo " + solo + " to track " + trackNumber);
}

/**
  * Send a generic OSC message
  * @param address OSC address pattern
  * @param args Arguments to include in the message
  */
public void sendOscMessage(String address, Object... args) {
  try {
    OscMessage msg = new OscMessage(address);
    for (Object arg : args) {
      if (arg instanceof Integer) {
        msg.add((int) arg); // Add integer argument
      } else if (arg instanceof Float) {
        msg.add((float) arg); // Add float argument
      } else if (arg instanceof String) {
        msg.add((String) arg); // Add string argument
      } else {
        println("Unsupported argument type: " + arg.getClass().getName());
      }
    }
    oscP5.send(msg, reaper);
  } catch (Exception e) {
    println("Error sending OSC message: " + e.getMessage());
  }
}
