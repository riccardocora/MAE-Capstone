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
import java.util.HashMap;
import java.util.function.Consumer;

// Main component managers
ControlP5 cp5;
LayoutManager layoutManager;
UIManager uiManager;
TrackManager trackManager;
VisualizationManager visualizationManager;
CubeRenderer cubeRenderer;
MidiBus midiBus; // MIDI connection
OscHelper oscHelper; // OSC Helper instance

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

HashMap<String, Consumer<OscMessage>> oscHandlers = new HashMap<>();

void setup() {
  size(1000,700,P3D); // Initialize the window in full-screen mode with P3D renderer

  // Initialize the layout manager
  layoutManager = new LayoutManager(width, height);

  // Initialize the MIDI Mapping Manager and load the mappings
  midiManager = new MidiMappingManager();
  midiManager.loadMappings(midiMappingFile, "Yamaha 02R96-1");
  
  // Initialize ControlP5
  cp5 = new ControlP5(this);
  
  // Initialize component managers
  cubeRenderer = new CubeRenderer(boundarySize);
  uiManager = new UIManager(cp5, width, height);
  visualizationManager = new VisualizationManager(boundarySize, headSize);

  // Set containers for component managers
  uiManager.setContainer(layoutManager.uiControlsArea);
  visualizationManager.setContainer(layoutManager.mainViewArea);

  // Initialize OSC Helper
  oscHelper = new OscHelper(this, 8000, "127.0.0.1", 8001, new ParentCallback() {
    public void onOscMessageReceived(OscMessage msg) {
      handleOscMessage(msg);
    }
  });
  
  // Initialize sound sources and tracks
  for (int i = 0; i < 7; i++) {
    tracks.add(new Track(i + 1, "Track " + (i + 1), 150 + i * 70, height - 300, oscHelper));
    soundSources.add(new SoundSource(150, random(0, TWO_PI), random(0, PI / 2)));
  }
  
  // Initialize master track to the left of Track 1
  masterTrack = new Track(0, "Master", 70, height - 300, oscHelper);


// Initialize track manager
  trackManager = new TrackManager(tracks, masterTrack);
  trackManager.setContainer(layoutManager.trackControlsArea);

  // Setup UI controls
  uiManager.setupControls(radius, azimuth, zenith, boundarySize, midiManager.availableDevices);
  
  // Initialize MIDI connection
  MidiBus.list(); // List available MIDI devices in the console
  midiBus = new MidiBus(this, "Yamaha 02R96-1", "Yamaha 02R96-1"); // Replace with your MIDI device name

  // Initialize OSC handlers
  oscHandlers.put("/track/*/volume", msg -> {
    int trackNum = parseTrackNumber(msg.addrPattern());
    if (trackNum >= 1 && trackNum <= tracks.size()) {
      float volume = msg.get(0).floatValue();
      tracks.get(trackNum - 1).setVolume(volume);
      if (trackNum <= soundSources.size()) {
        soundSources.get(trackNum - 1).setVolume(volume);
      }
    }
  });

  oscHandlers.put("/track/*/vu", msg -> {
    int trackNum = parseTrackNumber(msg.addrPattern());
    if (trackNum >= 1 && trackNum <= tracks.size()) {
      float vuLevel = msg.get(0).floatValue();
      tracks.get(trackNum - 1).setVuLevel(vuLevel);
      if (trackNum <= soundSources.size()) {
        soundSources.get(trackNum - 1).setVuLevel(vuLevel);
      }
    }
  });

  oscHandlers.put("/track/*/mute", msg -> {
    int trackNum = parseTrackNumber(msg.addrPattern());
    if (trackNum >= 1 && trackNum <= tracks.size()) {
      boolean muted = (int) msg.get(0).floatValue() == 1;
      tracks.get(trackNum - 1).setMuted(muted);
    }
  });

  oscHandlers.put("/track/*/solo", msg -> {
    int trackNum = parseTrackNumber(msg.addrPattern());
    if (trackNum >= 1 && trackNum <= tracks.size()) {
      boolean soloed = (int) msg.get(0).floatValue() == 1;
      tracks.get(trackNum - 1).setSoloed(soloed);
    }
  });
}
void handleOscMessage(OscMessage msg) {
  String pattern = msg.addrPattern();
  StringBuilder fullMessage = new StringBuilder();
  
  fullMessage.append("[OSC] Received message: ")
            .append(pattern)
            .append(" | Arguments: [");
  
  // Extract and append all arguments
  for (int i = 0; i < msg.typetag().length(); i++) {
    char type = msg.typetag().charAt(i);
    
    if (i > 0) fullMessage.append(", ");
    
    // Handle different argument types
    switch (type) {
      case 'i':
        fullMessage.append("int: ").append(msg.get(i).intValue());
        break;
      case 'f':
        fullMessage.append("float: ").append(msg.get(i).floatValue());
        break;
      case 's':
        fullMessage.append("string: \"").append(msg.get(i).stringValue()).append("\"");
        break;
      case 'b':
        fullMessage.append("blob: ").append(msg.get(i).blobValue().length).append(" bytes");
        break;
      default:
        fullMessage.append(type).append(": ").append(msg.get(i));
    }
  }
  
  fullMessage.append("]");
  String logMessage = fullMessage.toString();
  
  // Print to console and log to UI
  println(logMessage);
  uiManager.logMessage(logMessage);
  
  // Match the pattern dynamically
  Consumer<OscMessage> handler = findOscHandler(pattern);
  if (handler != null) {
    handler.accept(msg);
  } else {
    println("Unhandled OSC message: " + pattern);
  }
}

public void controllerChange(int channel, int number, int value) {
  println("[MIDI CC] Channel: " + channel + ", Number: " + number + ", Value: " + value);
  uiManager.logMessage("[MIDI CC] Ch: " + channel + ", Num: " + number + ", Val: " + value);

  // Use the lookup table to find the mapping
  MidiMapping mapping = midiManager.findMappingForCC(channel, number);

  if (mapping != null) {
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
            oscHelper.sendOscVolume(selectedSource + 1, normalizedValue);
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
            oscHelper.sendOscMute(trackNum + 1, muted);
          }
        }
        break;
        
      case "toggleMasterMute":
        boolean muted = value > 63;
        masterTrack.setMuted(muted);
        oscHelper.sendOscMute(0, muted); // Use OscHelper to send mute message
        break;
        
      case "setTrackVolume":
        if (mapping instanceof CCMapping) {
          CCMapping ccMapping = (CCMapping) mapping;
          int trackNum = ccMapping.getTrackNumber(number);
          if (trackNum >= 0 && trackNum < tracks.size()) {
            tracks.get(trackNum).setVolume(normalizedValue);
            // If this track has a corresponding sound source, update its volume too
            if (trackNum < soundSources.size()) {
              SoundSource source = soundSources.get(trackNum);
              source.setVolume(normalizedValue);
            }
            oscHelper.sendOscVolume(trackNum + 1, normalizedValue);
          }
        }
        break;
        
      case "setMasterVolume":
        masterTrack.setVolume(normalizedValue);
        oscHelper.sendOscVolume(0, normalizedValue); // Use OscHelper to send volume message
        break;
        
      case "setPan":
        if (mapping instanceof CCMapping) {
          CCMapping ccMapping = (CCMapping) mapping;
          int trackNum = ccMapping.getTrackNumber(number);
          if (trackNum >= 0 && trackNum < tracks.size()) {
            // Map the pan value (0-127) to the zenith angle (-PI to +PI)
            float zenith = map(value, 0, 127, -PI, PI);
            if (trackNum < soundSources.size()) {
              SoundSource source = soundSources.get(trackNum);
              source.zenith = zenith;
              source.updatePosition();
              if (trackNum == selectedSource) {
                cp5.getController("zenith").setValue(source.zenith);
              }
            }
            oscHelper.sendOscPan(trackNum + 1, zenith);
          }
        }
        break;
        
      case "setMasterPan":
        float pan = map(normalizedValue, 0, 1, -1, 1);
        oscHelper.sendOscPan(0, pan); // Use OscHelper to send pan message
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
    uiManager.logMessage("[MIDI SysEx] " + hexString.trim());
    
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
            oscHelper.sendOscVolume(0, volume); // Use OscHelper to send volume message
          }
          break;
          
        case "toggleSolo":
          // Extract track number and solo state from SysEx data
          if (data.length >= 13) {
            int trackNum = data[8] & 0xFF;
            boolean solo = (data[12] & 0xFF) == 1;
            
            if (trackNum < tracks.size()) {
              tracks.get(trackNum).setSoloed(solo);
              oscHelper.sendOscSolo(trackNum + 1, solo); // Use OscHelper to send solo message
            }
          }
          break;
          
        case "toggleMasterSolo":
          // Extract master solo state from SysEx data
          if (data.length >= 13) {
            boolean solo = (data[12] & 0xFF) == 1;
            masterTrack.setSoloed(solo);
            oscHelper.sendOscSolo(0, solo); // Use OscHelper to send solo message
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
                oscHelper.sendOscVolume(trackNum + 1, map(source.radius, 50, 600, 0, 1));
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
                oscHelper.sendOscVolume(trackNum + 1, map(source.radius, 50, 600, 0, 1));
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

// Helper function to parse the track number from the OSC address pattern
int parseTrackNumber(String addrPattern) {
  try {
    String[] parts = addrPattern.split("/");
    return Integer.parseInt(parts[2]); // Extract the track number from the address
  } catch (Exception e) {
    println("Error parsing track number from OSC address: " + addrPattern);
    return -1; // Return an invalid track number if parsing fails
  }
}

public void noteOn(int channel, int note, int velocity) {
  // Log the incoming MIDI note message
  println("[MIDI NOTE] Channel: " + channel + ", Note: " + note + ", Velocity: " + velocity);
  uiManager.logMessage("[MIDI NOTE] Ch: " + channel + ", Note: " + note + ", Vel: " + velocity);

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
  handleOscMessage(msg);
}

Consumer<OscMessage> findOscHandler(String messagePattern) {
  for (String key : oscHandlers.keySet()) {
    if (matchesOscPattern(key, messagePattern)) {
      return oscHandlers.get(key);
    }
  }
  return null;
}

// Helper function to match OSC patterns with wildcards
boolean matchesOscPattern(String handlerPattern, String messagePattern) {
  // Replace '*' in the handler pattern with a regex to match any segment
  String regex = handlerPattern.replace("*", "[^/]+");
  return messagePattern.matches(regex);
}

void draw() {
  background(20, 25, 35);

  // Draw track controls (bottom)
  trackManager.draw();

  // Draw main visualization (top)
  visualizationManager.draw(soundSources, selectedSource);

  // Draw UI controls (right)
  uiManager.draw(soundSources.size(), selectedSource);
}

void mousePressed() {
  trackManager.handleMousePressed(mouseX, mouseY);
}

void mouseDragged() {
  trackManager.handleMouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  trackManager.handleMouseReleased();
}

// Window resize handling
void windowResized() {
  layoutManager.updateLayout(width, height);
  uiManager.setContainer(layoutManager.uiControlsArea);
  uiManager.updatePositions(); // Ensure UI elements are repositioned
  visualizationManager.setContainer(layoutManager.mainViewArea);
  trackManager.setContainer(layoutManager.trackControlsArea);
}

void keyPressed() {
  if (key == 'v' || key == 'V') {
    visualizationManager.toggleMode();
  }
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

  // Scroll the log window
  if (keyCode == UP) {
    uiManager.scrollLog(-1); // Scroll up
  } else if (keyCode == DOWN) {
    uiManager.scrollLog(1); // Scroll down
  }
}
