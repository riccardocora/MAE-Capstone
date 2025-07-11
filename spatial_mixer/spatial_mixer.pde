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
OscHelper headTrackerOscHelperRec; // OSC Helper for head tracker

OscHelper headTrackerOscHelperSend; // OSC Helper for head tracker

OscHelper ambiMicRotatorOscHelper; // OSC Helper for ambisonic mic rotator


MidiMappingManager midiManager; // MIDI mapping object
String midiMappingFile = "data/midi_mapping.json";

// Data structures to store track and sound source information
final int NUM_TRACKS = 7; // Or any default you want

ArrayList<Track> tracks = new ArrayList<Track>();
ArrayList<SoundSource> soundSources = new ArrayList<SoundSource>();
SourceManager sourceManager;
int selectedSource = 0;

// Central subject
float headSize = 30;

// Cube boundary
float boundarySize = 800;

// Default values for sliders
float radius = 150;
float azimuth = 0;
float zenith = 0; // Changed to 0 for horizontal (new range is -π/2 to π/2)

Track masterTrack; // Declare a master track

HashMap<String, Consumer<OscMessage>> oscHandlers = new HashMap<>();

void setup() {
  size(1280,720,P3D);

  // Initialize ControlP5
  cp5 = new ControlP5(this);

  // Initialize layout manager
  layoutManager = new LayoutManager(width, height);
  // Initialize sound sources and tracks with matching indices
  for (int i = 0; i < NUM_TRACKS; i++) {
    tracks.add(new Track(i + 1, "Track " + (i + 1), 150 + i * 70, height - 300, oscHelper, i+1));
    SoundSource newSource = new SoundSource(150, random(0, TWO_PI), random(0, PI / 2));
    newSource.setSourceType(SourceType.MONO_STEREO); // Default all sources to MONO_STEREO
    soundSources.add(newSource);
  }

  // Initialize source manager with the same number of tracks
  sourceManager = new SourceManager( NUM_TRACKS);
  sourceManager.setContainer(layoutManager.sourceControlsArea);
  
  // Synchronize source types between UI and sound sources
  for (int i = 0; i < NUM_TRACKS; i++) {
    sourceManager.trackSources.get(i).mode = 0; // Set all to MONO_STEREO (0) initially
  }

  // Initialize the MIDI Mapping Manager and load the mappings
  midiManager = new MidiMappingManager();
  midiManager.loadMappings(midiMappingFile, "Yamaha 02R96-1");

  
  // Initialize component managers
  cubeRenderer = new CubeRenderer(boundarySize);
  uiManager = new UIManager(cp5, width, height);
  visualizationManager = new VisualizationManager(boundarySize, headSize);

  // Set containers for component managers
  uiManager.setContainer(layoutManager.uiControlsArea);
  visualizationManager.setContainer(layoutManager.mainViewArea);

  // Initialize OSC Helper
  oscHelper = new OscHelper(this, 8000, "192.168.1.50",8100, new ParentCallback() {
    public void onOscMessageReceived(OscMessage msg) {
      handleOscMessage(msg);
    }
  });
  
   // Initialize head tracker OSC Helper
  headTrackerOscHelperRec = new OscHelper(this, 9000, "127.0.0.1", 9101, new ParentCallback() {
    public void onOscMessageReceived(OscMessage msg) {
      handleOscMessage(msg);
    }
  });


    // Initialize head tracker OSC Helper
  headTrackerOscHelperSend = new OscHelper(this, 9000, "192.168.1.50", 9000, new ParentCallback() {
    public void onOscMessageReceived(OscMessage msg) {
      handleOscMessage(msg);
    }
  });


   // Initialize ambi mic rotator OSC Helper
  ambiMicRotatorOscHelper = new OscHelper(this, 9200, "192.168.1.60", 9201, new ParentCallback() {
    public void onOscMessageReceived(OscMessage msg) {
      handleOscMessage(msg);
    }
  });

  // Initialize master track to the left of Track 1
  masterTrack = new Track(0, "Master", 70, height - 300, oscHelper,0);


  // Initialize track manager
  trackManager = new TrackManager(tracks, masterTrack);
  trackManager.setContainer(layoutManager.trackControlsArea);

  // Setup UI controls
  uiManager.setupControls(radius, azimuth, zenith, boundarySize, midiManager.availableDevices);
  
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

  MidiBus.list(); // List available MIDI devices in the console
  String[] availableDevices = MidiBus.availableInputs();
  if (availableDevices.length > 0) {
      midiBus = new MidiBus(this, 1, -1);
      println("MIDI device initialized: " + availableDevices[0]);
  } else {
      println("No MIDI devices found. MIDI functionality will be disabled.");
  } 
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
  } else if (pattern.startsWith("/ypr")) {
    // Handle head rotation messages
    handleHeadRotationMessage(msg);
  } else {
    println("Unhandled OSC message: " + pattern);
  }
}

// Handle head rotation messages
void handleHeadRotationMessage(OscMessage msg) {
  String pattern = msg.addrPattern();
  
  // Handle /ypr pattern from head tracker simulator
  if (pattern.equals("/ypr")) {
    // Check if we have enough arguments (expecting 3 floats: -yaw, -pitch, roll)
    if (msg.typetag().length() < 3) {
      println("Error: /ypr message requires 3 arguments (-yaw, -pitch, roll)");
      return;
    }
      try {
      // Extract the three rotation values: -yaw, -pitch, roll (in degrees)
      float negYaw = msg.get(0).floatValue();    // -yaw in degrees
      float negPitch = msg.get(1).floatValue();  // -pitch in degrees  
      float roll = msg.get(2).floatValue();      // roll in degrees
      
      // Convert to positive values (since simulator sends negative values)
      float yawDegrees = negYaw;     // Convert back to positive yaw
      float pitchDegrees = negPitch; // Convert back to positive pitch
      // roll is already correct
      
      // Convert degrees to radians for internal use
      float yaw = radians(yawDegrees);
      float pitch = radians(pitchDegrees);
      float rollRad = radians(roll);
      
      // Update head rotation parameters
      visualizationManager.centralHead.setYaw(yaw);
      visualizationManager.centralHead.setPitch(pitch);
      visualizationManager.centralHead.setRoll(rollRad);
      
      // Log the update
      uiManager.logMessage(String.format("[Head] YPR updated - Yaw: %.2f°, Pitch: %.2f°, Roll: %.2f°", 
                                        yawDegrees, pitchDegrees, roll));
      headTrackerOscHelperSend.sendYprMessage(negYaw, negPitch, roll);

    } catch (Exception e) {
      println("Error parsing /ypr values: " + e.getMessage());
      return;
    }
    return;
  }
  
  // Handle individual head rotation patterns (legacy support)
  // Check if we have enough arguments
  if (msg.typetag().length() < 1) {
    println("Error: Head rotation message missing value");
    return;
  }
  
  // Extract the rotation value (should be a float)
  float value = 0;
  try {
    if (msg.typetag().charAt(0) == 'f') {
      value = msg.get(0).floatValue();
    } else if (msg.typetag().charAt(0) == 'i') {
      // Convert integer to float if needed
      value = (float) msg.get(0).intValue();
    } else {
      println("Error: Head rotation message has invalid type: " + msg.typetag().charAt(0));
      return;
    }
  } catch (Exception e) {
    println("Error parsing head rotation value: " + e.getMessage());
    return;
  }
  
}

// Handle cube rotation messages
void handleCubeRotationMessage(OscMessage msg) {
  String pattern = msg.addrPattern();
  
  // Check if we have enough arguments
  if (msg.typetag().length() < 1) {
    println("Error: Cube rotation message missing value");
    return;
  }
  
  // Extract the rotation value (should be a float)
  float value = 0;
  try {
    if (msg.typetag().charAt(0) == 'f') {
      value = msg.get(0).floatValue();
    } else if (msg.typetag().charAt(0) == 'i') {
      // Convert integer to float if needed
      value = (float) msg.get(0).intValue();
    } else {
      println("Error: Cube rotation message has invalid type: " + msg.typetag().charAt(0));
      return;
    }
  } catch (Exception e) {
    println("Error parsing cube rotation value: " + e.getMessage());
    return;
  }
  
  // Map the incoming value (typically 0-1) to an appropriate rotation range (-PI to PI)
  float mappedValue = map(value, 0, 1, -PI, PI);
    // Update the appropriate cube rotation parameter
  if (pattern.equals("/cube/roll")) {
    visualizationManager.setCubeRoll(mappedValue);
    uiManager.updateSliderValue("roll", mappedValue);
    uiManager.logMessage("[Cube] Set roll to " + mappedValue);
  } 
  else if (pattern.equals("/cube/yaw")) {
    visualizationManager.setCubeYaw(mappedValue);
    uiManager.updateSliderValue("yaw", mappedValue);
    uiManager.logMessage("[Cube] Set yaw to " + mappedValue);
  } 
  else if (pattern.equals("/cube/pitch")) {
    visualizationManager.setCubePitch(mappedValue);
    uiManager.updateSliderValue("pitch", mappedValue);
    uiManager.logMessage("[Cube] Set pitch to " + mappedValue);
  }
}

public void controllerChange(int channel, int number, int value) {
  println("[MIDI CC] Channel: " + channel + ", Number: " + number + ", Value: " + value);
  uiManager.logMessage("[MIDI CC] Ch: " + channel + ", Num: " + number + ", Val: " + value);

  // Use the lookup table to find the mapping
  MidiMapping mapping = midiManager.findMappingForCC(channel, number);

  if (mapping != null) {
    float normalizedValue = mapping.getNormalizedValue(value);
    CCMapping ccMapping = (CCMapping) mapping;
    int trackNum = ccMapping.getTrackNumber(number);
    if(trackNum < 0 || trackNum >= soundSources.size()) {
      println("Invalid track number: " + trackNum);
      return; // Invalid track number, skip processing
    }
    selectedSource = trackNum;
    uiManager.updateSliders(selectedSource);
    switch (mapping.action) {
      case "updateSource":
        if (selectedSource >= 0 && selectedSource < soundSources.size()) {
          SoundSource source = soundSources.get(selectedSource);          if (mapping.parameter.equals("radius")) {
            float radius = map(normalizedValue, 0, 1, 50, 600);
            source.radius = radius;
            source.positionUpdated = true; // Mark position for update
            source.updatePosition();
            uiManager.updateSliderValue("radius", source.radius);
            oscHelper.sendOscVolume(selectedSource + 1, normalizedValue);
          } 
          else if (mapping.parameter.equals("azimuth")) {
            float azimuth = map(normalizedValue, 0, 1, 0, TWO_PI);
            source.azimuth = azimuth;
            source.positionUpdated = true; // Mark position for update
            source.updatePosition();
            uiManager.updateSliderValue("azimuth", source.azimuth);
          } 
          else if (mapping.parameter.equals("zenith")) {
            float zenith = map(normalizedValue, 0, 1, 0, PI);
            source.zenith = zenith;
            source.positionUpdated = true; // Mark position for update
            source.updatePosition();
            uiManager.updateSliderValue("zenith", source.zenith);
          }
        }
        break;
        
      case "selectSource":
        // Only trigger source selection when value is in the active range
        if (mapping instanceof CCMapping) {
          if (trackNum >= 0 && trackNum < soundSources.size()) {
            selectedSource = trackNum;
            updateUIControls(soundSources.get(selectedSource));
            println("Selected source: " + selectedSource);
          }
        }
        break;
        
      case "toggleMute":
        if (mapping instanceof CCMapping) {
          
          if (trackNum >= 0 && trackNum < tracks.size()) {
            boolean muted = value < 63; // Consider values > 63 as mute ON
            tracks.get(trackNum).setMuted(muted);
            oscHelper.sendOscMute(trackNum + 1, muted);
          }
        }
        break;
        
      case "toggleMasterMute":
        boolean muted = value < 63;
        masterTrack.setMuted(muted);
        oscHelper.sendOscMute(0, muted); // Use OscHelper to send mute message
        break;
        
      case "setTrackVolume":
        if (mapping instanceof CCMapping) {
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
        println("SET MASTER VOLUME: ",normalizedValue);
        masterTrack.setVolume(normalizedValue);
        oscHelper.sendOscVolume(0, normalizedValue); // Use OscHelper to send volume message
        break;
        
      case "setZenith":
        if (mapping instanceof CCMapping) {
      
          if (trackNum >= 0 && trackNum < tracks.size() && trackNum < soundSources.size()) {
            // Map the (pan value (0-127) to the zenith angle (-PI to +PI)
            SoundSource source = soundSources.get(trackNum);
            if (source != null) {
              if(source.type == SourceType.MONO_STEREO){
                float zenith = map(value, 0, 127, -PI/2, PI/2);
                source.zenith = zenith;
                source.positionUpdated = true; // Mark position for update
                source.updatePosition();
                if (trackNum == selectedSource) {
                  uiManager.updateSliderValue("zenith", source.zenith);
                }
                oscHelper.sendOscMessage("/track/" + (trackNum + 1) + "/zenith", zenith);
              }
              else if(source.type == SourceType.AMBI){
                float yaw = map(value, 0, 127, -PI, PI);
                // Update the yaw value in the visualization manager
                visualizationManager.setCubeYaw(yaw);
                // Also apply rotation to all sound sources
                for(int i = 0; i < soundSources.size(); i++) {
                  soundSources.get(i).setYaw(yaw);
                  // Send OSC messages for the updated polar coordinates  
                  float sendAzimuth = atan2(-soundSources.get(i).x,soundSources.get(i).z);
                  if (sendAzimuth < 0) sendAzimuth += TWO_PI;

                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/radius", soundSources.get(i).radius);
                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/azimuth", map(sendAzimuth, -PI, PI, 0, 1));
                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/zenith", map(soundSources.get(i).zenith, -PI/2, PI/2, 0, 1));
                }


                // Update UI sliders to reflect new yaw value
                uiManager.updateSliders(selectedSource);
                // Send OSC message for the updated yaw value
                ambiMicRotatorOscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/yaw", yaw);
                println("Ambisonic yaw value: " + yaw);
              } else {
                println("Unsupported source type for X position update: " + source.type);
              }
            }
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
    
    // Log if no matches were found
    if (matches.isEmpty()) {
      println("No matching SysEx mappings found for this message");
    }
    
    for (MidiMapping mapping : matches) {
      println("Found matching SysEx mapping: " + mapping.name + " (" + mapping.action + ")");
      
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
          // Process positioning X data - directly update X coordinate
          if (data.length >= 13 && data[7] == 0x05) { // Check for X position command (0x05)
            int trackNum = data[8] & 0xFF;
            println("Received X position command for track: " + trackNum);
            if (trackNum>=0 && trackNum < soundSources.size()) {
              selectedSource = trackNum;
              uiManager.updateSliders(selectedSource);
              // Extract the 4 bytes that represent the X position
              int xPos = parsePositionValue(data[9], data[10], data[11], data[12]);
              println("Raw X position data: " + xPos);
              // Get the selected source and update its X coordinate
              SoundSource source = soundSources.get(selectedSource);

              if(source.type == SourceType.MONO_STEREO){
                // Map X position (-63 to +63) to coordinate space (-boundarySize/2 to +boundarySize/2)
                float xCoord = map(xPos, -63, 63, -boundarySize/2, boundarySize/2);
                println("Mapped X coordinate: " + xCoord);
                
                  // Update cartesian coordinates (keeping current Y and Z)
                source.updateFromCartesian(xCoord, source.y, source.z);
                
                // Update UI sliders to reflect new polar coordinates
                uiManager.updatePositionSliders(source);
                float sendAzimuth = atan2(-source.x,source.z);
                if (sendAzimuth < 0) sendAzimuth += TWO_PI;

                // Send OSC messages for the updated polar coordinates
                oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/radius", source.radius);
                oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/azimuth", map(sendAzimuth, -PI, PI, 0, 1));
                oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/zenith", map(source.zenith, -PI/2, PI/2, 0, 1));
                
                println("Updated X coordinate to: " + xCoord + 
                        ", new azimuth: " + degrees(source.azimuth) + "°" +
                        ", new radius: " + source.radius);
              }else if(source.type == SourceType.AMBI){
                float value = map(xPos, -63, 63, -PI, PI);
                // Update the roll value in the visualization manager
                visualizationManager.setCubeRoll(value);
                // Also apply rotation to all sound sources
                for(int i = 0; i < soundSources.size(); i++) {
                  soundSources.get(i).setRoll(value);
                    // Send OSC messages for the updated polar coordinates
                float sendAzimuth = atan2(-soundSources.get(i).x,soundSources.get(i).z);
                 if (sendAzimuth < 0) sendAzimuth += TWO_PI;

                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/radius", soundSources.get(i).radius);
                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/azimuth", map(sendAzimuth,-PI, PI, 0, 1));
                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/zenith", map(soundSources.get(i).zenith, -PI/2, PI/2, 0, 1));

                }


                // Update UI sliders to reflect new roll value
                uiManager.updateSliders(selectedSource);
                // Send OSC message for the updated roll value
                ambiMicRotatorOscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/roll", value);
                println("Ambisonic roll value: " + value);
              } else {
                println("Unsupported source type for X position update: " + source.type);
              }
            }
          }
          break;            
        case "setPositionY":
          // Process positioning Y data - directly update Z coordinate (transverse axis)
          if (data.length >= 13 && data[7] == 0x06) { // Check for Y position command (0x06)
            int trackNum = data[8] & 0xFF;
            println("Received Y position command for track: " + trackNum);

              if (trackNum>=0 && trackNum < soundSources.size()) {
              selectedSource = trackNum;
              uiManager.updateSliders(selectedSource);
              // Extract the 4 bytes that represent the Y position
              int yPos = parsePositionValue(data[9], data[10], data[11], data[12]);
              println("Raw Z position data: " + yPos);
              // Get the selected source and update its Z coordinate
              SoundSource source = soundSources.get(selectedSource);
              
              if(source.type == SourceType.MONO_STEREO){
                // Map Y position (-63 to +63) to Z coordinate space (-boundarySize/2 to +boundarySize/2)
                float zCoord = map(yPos, -63, 63, -boundarySize/2, boundarySize/2);
                

                println("Mapped Z coordinate: " + zCoord);
              
                  // Update cartesian coordinates (keeping current X and Y)
                source.updateFromCartesian(source.x, source.y, zCoord);
                
                // Update UI sliders to reflect new polar coordinates
                uiManager.updatePositionSliders(source);
                
                // Send OSC messages for the updated polar coordinates
                float sendAzimuth = atan2(-source.x,source.z);
                if (sendAzimuth < 0) sendAzimuth += TWO_PI;

                oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/radius", source.radius);
                oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/azimuth", map(sendAzimuth, -PI, PI, 0, 1));
                oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/zenith", map(source.zenith, -PI/2, PI/2, 0, 1));
                
                println("Updated Z coordinate to: " + zCoord + 
                        ", new azimuth: " + degrees(source.azimuth) + "°" +
                        ", new radius: " + source.radius);
              } else if(source.type == SourceType.AMBI){
                float value = map(yPos, -63, 63, -PI, PI);
                // Update the roll value in the visualization manager
                visualizationManager.setCubePitch(value);
                // Also apply rotation to all sound sources
                for(int i = 0; i < soundSources.size(); i++) {
                  soundSources.get(i).setPitch(value);
                  float sendAzimuth = atan2(-soundSources.get(i).x,soundSources.get(i).z);
                  if (sendAzimuth < 0) sendAzimuth += TWO_PI;
                  println("sendAzimuth: ",sendAzimuth);
                  // Send OSC messages for the updated polar coordinates
                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/radius", soundSources.get(i).radius);
                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/azimuth", map(sendAzimuth,-PI, PI, 0, 1));
                  oscHelper.sendOscMessage("/track/" + (i + 1) + "/zenith", map(soundSources.get(i).zenith, -PI/2, PI/2, 0, 1));
                }
                // Update UI sliders to reflect new pitch value
                uiManager.updateSliders(selectedSource);
                // Send OSC message for the updated pitch value
                ambiMicRotatorOscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/pitch", value);
                println("Ambisonic pitch value: " + value);
              } else {
                println("Unsupported source type for Y position update: " + source.type);
              }
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
              source.positionUpdated = true; // Mark position for update
              source.updatePosition();
              
              // Update UI if this is the currently selected source
              if (trackNum == selectedSource) {
                uiManager.updateSliders(selectedSource);
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
  // The format is:
  // 00 00 00 00 = position 0 (origin)
  // 00 00 00 3F = position +63 (max positive)
  // 7F 7F 7F 7F = position -1
  // 7F 7F 7F 41 = position -63 (max negative)
  // Negative values descend from 7F 7F 7F 7F (-1) down to 7F 7F 7F 41 (-63)
  
  int value = 0;
  
  // Check if we're in the positive range (first three bytes are 0)
  if ((b1 & 0xFF) == 0x00 && (b2 & 0xFF) == 0x00 && (b3 & 0xFF) == 0x00) {
    // Positive range: 0 to +63
    value = b4 & 0x7F;  // Use the last byte for the positive range
    if (value > 63) value = 63;  // Clamp to max value
  } else if ((b1 & 0xFF) == 0x7F && (b2 & 0xFF) == 0x7F && (b3 & 0xFF) == 0x7F) {
    // Negative range: -1 to -63
    // 7F 7F 7F 7F = -1, values descend as last byte decreases
    // 7F 7F 7F 41 = -63 (0x41 = 65 decimal)
    int lastByte = b4 & 0x7F;
    if (lastByte == 0x7F) {
      value = -1;  // 7F 7F 7F 7F = -1
    } else {
      // Calculate negative values: 7F->-1, 7E->-2, ..., 41->-63
      value = -(0x7F - lastByte + 1);
      if (value < -63) value = -63;  // Clamp to min value
    }
  } else {
    // Invalid format, default to 0
    println("Warning: Invalid position format in SysEx data");
    value = 0;
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
    uiManager.updateSliders(selectedSource);
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
  background(30);

  // Draw layout borders
  layoutManager.drawContainerBorders();

  // Update the selected source in the source manager
  sourceManager.selectedSource = selectedSource;
  
  // Draw source manager with highlighting for selected source
  sourceManager.draw();

  // Draw track controls (bottom) with highlighting for selected source
  trackManager.draw(selectedSource);

  // Draw main visualization (top)
  visualizationManager.draw(soundSources, selectedSource);

  // Draw UI controls (right)
  uiManager.draw(soundSources.size(), selectedSource);
  uiManager.setSliderMode(sourceManager.trackSources.get(selectedSource).mode);
}


void mouseWheel(MouseEvent event) {
  sourceManager.mouseWheel(event);
}

void mousePressed() {
  // Check if mouse is over visualization first
  visualizationManager.handleMousePressed();
  
  // If not dragging visualization, handle other components
  if (!visualizationManager.isDragging) {
    sourceManager.mousePressed();
    trackManager.handleMousePressed(mouseX, mouseY);
    uiManager.mousePressed(); // Handle custom sliders
  }
}

void mouseDragged() {
  // First check if visualization is being dragged
  if (visualizationManager.isDragging) {
    visualizationManager.handleMouseDragged();
  } else {
    // Otherwise handle other components' dragging
    sourceManager.mouseDragged();
    trackManager.handleMouseDragged(mouseX, mouseY);
    uiManager.mouseDragged(); // Handle custom sliders
  }
}

void mouseReleased() {
  visualizationManager.handleMouseReleased();
  sourceManager.mouseReleased();
  trackManager.handleMouseReleased();
  uiManager.mouseReleased(); // Handle custom sliders
}
// Window resize handling
void windowResized() {
  layoutManager.updateLayout(width, height);
  uiManager.setContainer(layoutManager.uiControlsArea);
  uiManager.updatePositions(); // Ensure UI elements are repositioned
  visualizationManager.setContainer(layoutManager.mainViewArea);
  trackManager.setContainer(layoutManager.trackControlsArea);
  sourceManager.setContainer(layoutManager.sourceControlsArea);
}

void keyPressed() {
  if (key == 'v' || key == 'V') {
    visualizationManager.toggleMode();
  }
  
  // Reset camera view with 'r' key
  if (key == 'r' || key == 'R') {
    visualizationManager.resetRotation();
  }
  // Change source type based on key press (m=Mono/Stereo, a=Ambi, s=Send)
  if (selectedSource >= 0 && selectedSource < sourceManager.trackSources.size() && 
      selectedSource < soundSources.size()) {
      
    if (key == 'm' || key == 'M') {
      // Set to Mono/Stereo mode
      sourceManager.changeSourceMode(selectedSource, 0); 
      // Only update SoundSource if the UI mode was changed successfully
      if (sourceManager.trackSources.get(selectedSource).mode == 0) {
        soundSources.get(selectedSource).setSourceType(SourceType.MONO_STEREO);
        println("Changed source " + selectedSource + " to Mono/Stereo mode");
      }
    } else if (key == 'a' || key == 'A') {      // Try to set to Ambi mode - this will fail if another source is already in Ambi mode
      int currentAmbiIdx = sourceManager.getAmbiSourceIndex();
      if (currentAmbiIdx >= 0 && currentAmbiIdx != selectedSource) {
        // Another source is already in Ambi mode
        String errorMsg = "Cannot set source " + selectedSource + " to Ambi mode because source " + 
                currentAmbiIdx + " is already in Ambi mode";
        println(errorMsg);
        uiManager.logMessage("ERROR: " + errorMsg);
      } else {
        sourceManager.changeSourceMode(selectedSource, 1);
        if (sourceManager.trackSources.get(selectedSource).mode == 1) {
          soundSources.get(selectedSource).setSourceType(SourceType.AMBI);
          println("Changed source " + selectedSource + " to Ambi mode");
        }
      }
    } else if (key == 's' || key == 'S') {
      // Set to Send mode
      sourceManager.changeSourceMode(selectedSource, 2);
      soundSources.get(selectedSource).setSourceType(SourceType.SEND);
      println("Changed source " + selectedSource + " to Send mode");
    }
  }
  
  // Select sound source using number keys
  if (key >= '1' && key <= '9') {
    int sourceIndex = key - '1';
    if (sourceIndex < soundSources.size()) {
      selectSource(sourceIndex);

    }
  }

  // Scroll the log window
  if (keyCode == UP) {
    uiManager.scrollLog(-1); // Scroll up
  } else if (keyCode == DOWN) {
    uiManager.scrollLog(1); // Scroll down
  }
}
void addSource() {
  int idx = tracks.size();
  SoundSource newSource = new SoundSource(150, random(0, TWO_PI), random(-PI/4, PI/4)); // Random zenith in new range
  newSource.setSourceType(SourceType.MONO_STEREO); // Explicitly set to MONO_STEREO
  soundSources.add(newSource);
  tracks.add(new Track(idx + 1, "Track " + (idx + 1), 150 + idx * 70, height - 300, oscHelper, idx));
  
  // Add track source to the UI
  sourceManager.addTrackSource();
  
  // Make sure the track source mode matches the sound source type
  sourceManager.trackSources.get(idx).mode = 0; // 0 = MONO_STEREO
  
  // Update positions in both managers
  trackManager.updateTrackPositions();
  sourceManager.updateTrackPositions();
}

void removeSource(int idx) {
  if (idx >= 0 && idx < tracks.size()) {
    // Check if we're removing an Ambi source
    boolean wasAmbiSource = (sourceManager.trackSources.get(idx).mode == 1);
    
    soundSources.remove(idx);
    tracks.remove(idx);
    sourceManager.removeTrackSource(idx);
    
    // If we removed the Ambi source, log a message
    if (wasAmbiSource) {
      println("Ambi source removed. Another source can now be set to Ambi mode.");
      uiManager.logMessage("Ambi source removed. Another source can now be set to Ambi mode.");
    }
    
    // Update indices for all remaining tracks and sources
    for (int i = 0; i < tracks.size(); i++) {
      tracks.get(i).index = i;
      tracks.get(i).name = sourceManager.trackSources.get(i).name; // Keep names in sync
    }
    trackManager.updateTrackPositions();
    sourceManager.updateTrackPositions();
  }
}

void renameSource(int idx, String newName) {
  if (idx >= 0 && idx < tracks.size()) {
    tracks.get(idx).name = newName;
    sourceManager.trackSources.get(idx).name = newName;
    //sourceManager.trackSources.get(idx).nameField.setText(newName);
  }
}

void onSourceModeChange(int idx, int mode) {
  // Update UI for the selected source
  if (idx == selectedSource) {
    uiManager.setSliderMode(mode);
  }
  
  // Update the source type in the SoundSource object if it exists
  if (idx >= 0 && idx < soundSources.size()) {
    soundSources.get(idx).setSourceType(mode);
  }
}

void selectSource(int idx) {
  selectedSource = idx;
  int mode = sourceManager.trackSources.get(idx).mode;
  uiManager.setSliderMode(mode);
  uiManager.updateSliders(selectedSource);
}

// Helper function to update UI controls with source values
void updateUIControls(SoundSource source) {
  // Use the UIManager to update all sliders
  uiManager.updateSliders(selectedSource);
}

// Helper function to update UI position sliders for a specific source
void updateSourceUI(int sourceIndex) {
  if (sourceIndex >= 0 && sourceIndex < soundSources.size()) {
    SoundSource source = soundSources.get(sourceIndex);
    uiManager.updatePositionSliders(source);
  }
}
