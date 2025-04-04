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
  
  // Initialize ControlP5
  cp5 = new ControlP5(this);
  
  // Initialize component managers
  cubeRenderer = new CubeRenderer(boundarySize);
  uiManager = new UIManager(cp5, width, height);

  // Initialize OSC
  oscP5 = new OscP5(this, 8000); // Listen on port 8000
  reaper = new NetAddress("127.0.0.1", 8001); // Send to Reaper on port 8001
  
  
  // Initialize sound sources and tracks
  for (int i = 0; i < 4; i++) {
    tracks.add(new Track(i + 1, "Track " + (i + 1), 150 + i * 70, height - 300));
    soundSources.add(new SoundSource(150, random(0, TWO_PI), random(0, PI / 2)));
  }
  
  // Initialize master track to the left of Track 1
  masterTrack = new Track(0, "Master", 70, height - 300);

  // Setup UI controls
  uiManager.setupControls(radius, azimuth, zenith, boundarySize);
  
  // Initialize MIDI connection
  MidiBus.list(); // List available MIDI devices in the console
  midiBus = new MidiBus(this, "MPK mini Play mk3", "MPK mini Play mk3"); // Replace with your MIDI device name
}

public void controllerChange(int channel, int number, int value) {
  // Log the incoming MIDI CC message
  println("[MIDI CC] Channel: " + channel + ", Number: " + number + ", Value: " + value);
  
  switch (number) {
    case 1: // Radius
      if (selectedSource >= 0 && selectedSource < soundSources.size()) {
        float radius = map(value, 0, 127, 50, 600);
        SoundSource source = soundSources.get(selectedSource);
        source.radius = radius;
        source.updatePosition();
        cp5.getController("radius").setValue(source.radius);
        sendOscVolume(selectedSource + 1, map(radius, 50, 600, 0, 1));
      }
      break;

    case 2: // Azimuth
      if (selectedSource >= 0 && selectedSource < soundSources.size()) {
        float azimuth = map(value, 0, 127, 0, TWO_PI);
        SoundSource source = soundSources.get(selectedSource);
        source.azimuth = azimuth;
        source.updatePosition();
        cp5.getController("azimuth").setValue(source.azimuth);

      }
      break;

    case 3: // Zenith
      if (selectedSource >= 0 && selectedSource < soundSources.size()) {
        float zenith = map(value, 0, 127, 0, PI);
        SoundSource source = soundSources.get(selectedSource);
        source.zenith = zenith;
        source.updatePosition();
        cp5.getController("zenith").setValue(source.zenith);
      }
      break;
  }
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

