

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
 */

import controlP5.*;
import themidibus.*; // Import the MidiBus library

MidiBus myBus; // The MidiBus instance


// ControlP5 library
ControlP5 cp5;

// Arrays to store sound source positions
ArrayList<SoundSource> soundSources;
int selectedSource = 0;

// Central subject
float headSize = 30;

// Cube boundary
float boundarySize = 700;

// Add event variables to capture slider values
float radius = 150;
float azimuth = 0;
float zenith = PI/4;

void setup() {
  size(1000, 700, P3D);
  
  // Initialize ControlP5
  cp5 = new ControlP5(this);
  MidiBus.list(); // List available MIDI devices in the console
  try {
    myBus = new MidiBus(this,"MPK mini Play mk3", "MPK mini Play mk3");
  } catch (Exception e) {
    println("Error initializing MidiBus: " + e.getMessage());
  }  
  // Initialize sound sources
  soundSources = new ArrayList<SoundSource>();
  // Add some initial sound sources
  soundSources.add(new SoundSource(150, 0, PI/4));
  soundSources.add(new SoundSource(200, PI/2, PI/3));
  soundSources.add(new SoundSource(130, PI, PI/2));
  soundSources.add(new SoundSource(180, -PI/3, PI/6));
  soundSources.add(new SoundSource(160, PI/4, PI/2));
  soundSources.add(new SoundSource(170, -PI/2, PI/3));
  soundSources.add(new SoundSource(190, PI/6, PI/4));
  soundSources.add(new SoundSource(210, -PI/4, PI/5));
  
  // Calculate positions for UI elements
  float panelX = width - 300;
  float sliderX = panelX + 50;
  
  // Create sliders with event handlers
  cp5.addSlider("radius")
     .setPosition(sliderX, 300)
     .setSize(200, 30)
     .setRange(50, boundarySize - 20)
     .setValue(150)
     .setCaptionLabel("Radius")
     .setColorCaptionLabel(color(255))
     .setColorBackground(color(60, 65, 75))
     .setColorForeground(color(100, 120, 140))
     .setColorActive(color(180, 200, 220));
     
  cp5.addSlider("azimuth")
     .setPosition(sliderX, 350)
     .setSize(200, 30)
     .setRange(0, TWO_PI)
     .setValue(0)
     .setCaptionLabel("Azimuth")
     .setColorCaptionLabel(color(255))
     .setColorBackground(color(60, 65, 75))
     .setColorForeground(color(100, 120, 140))
     .setColorActive(color(180, 200, 220));
     
  cp5.addSlider("zenith")
     .setPosition(sliderX, 400)
     .setSize(200, 30)
     .setRange(0, PI)
     .setValue(PI/4)
     .setCaptionLabel("Zenith")
     .setColorCaptionLabel(color(255))
     .setColorBackground(color(60, 65, 75))
     .setColorForeground(color(100, 120, 140))
     .setColorActive(color(180, 200, 220));
  
  // Create buttons
  cp5.addButton("addSource")
     .setPosition(sliderX, 450)
     .setSize(95, 30)
     .setCaptionLabel("Add Source")
     .setColorBackground(color(60, 70, 90))
     .setColorForeground(color(80, 90, 110))
     .setColorActive(color(100, 110, 130));
     
  cp5.addButton("removeSource")
     .setPosition(sliderX + 105, 450)
     .setSize(95, 30)
     .setCaptionLabel("Remove Source")
     .setColorBackground(color(60, 70, 90))
     .setColorForeground(color(80, 90, 110))
     .setColorActive(color(100, 110, 130));
}

void draw() {
  background(20, 25, 35);
  
  // Draw the 3D scene
  draw3DScene();
  
  // Draw the 2D UI
  drawUI();
  
  // Update the selected sound source based on slider values
  if (soundSources.size() > 0) {
    SoundSource source = soundSources.get(selectedSource);
    source.radius = radius;
    source.azimuth = azimuth;
    source.zenith = zenith;
    source.updatePosition();
  }
}

void draw3DScene() {
  pushMatrix();
  
  // Center the 3D scene on the screen with a better view
  translate(width/2, height/2, -30);
  rotateX(radians(-30));  // Looking down from above at a milder angle
  //rotateY(radians(45));  // Rotated to see multiple sides of the cube
  scale(0.8);  // Scale down to fit better
  
  // Set up lighting
  ambientLight(50, 50, 50);
  directionalLight(200, 200, 200, -1, -1, -1);
  
  // Draw cube frame
  drawCubeFrame();
  
  // Draw coordinate system
  drawCoordinateSystem();
  
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
    source.display(isSelected);
    
    // Draw line connecting source to head
    stroke(180, 180, 200, 150);
    strokeWeight(1);
    line(0, 0, 0, source.x, source.y, source.z);
  }
  
  popMatrix();
}

void drawUI() {
  // Reset to 2D for UI elements
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();
  
  // Calculate panel positions relative to window size
  float panelX = width - 300;  // Fixed width of 280 + 20px padding
  float panelY = 100;
  
  // Draw UI panel background
  fill(40, 45, 55, 200);
  noStroke();
  rect(panelX, panelY, 280, 500, 10);
  
  // Draw title
  fill(255);
  textAlign(CENTER);
  textSize(20);
  text("Sound Source Controls", panelX + 140, panelY + 30);
  
  // Draw source selector
  fill(255);
  textAlign(LEFT);
  textSize(16);
  text("Selected Source: " + (selectedSource + 1) + " / " + soundSources.size(), panelX + 20, panelY + 70);
  
  // Draw source position info
  if (soundSources.size() > 0) {
    SoundSource source = soundSources.get(selectedSource);
    fill(200);
    textSize(14);
    text("Position (x, y, z): ", panelX + 20, panelY + 100);
    text(String.format("(%.1f, %.1f, %.1f)", source.x, source.y, source.z), panelX + 20, panelY + 120);
    
    // Draw spherical coordinates
    text("Spherical Coordinates:", panelX + 20, panelY + 150);
    text(String.format("Radius: %.1f", source.radius), panelX + 20, panelY + 170);
    text(String.format("Azimuth: %.1f° (%.1f rad)", source.azimuth * 180/PI, source.azimuth), panelX + 20, panelY + 190);
    
    // Update controllP5 slider positions when source changes (prevent feedback loops)
    if (!cp5.getController("radius").isMousePressed()) {
      cp5.getController("radius").setValue(source.radius);
    }
    if (!cp5.getController("azimuth").isMousePressed()) {
      cp5.getController("azimuth").setValue(source.azimuth);
    }
    if (!cp5.getController("zenith").isMousePressed()) {
      cp5.getController("zenith").setValue(source.zenith);
    }
    
  }
  
  // Draw instructions
  fill(200);
  textSize(12);
  textAlign(LEFT);
  text("Instructions:", panelX + 20, panelY + 400);
  text("- Use sliders to position sound sources", panelX + 20, panelY + 420);
  text("- Select sources using numeric keys (1, 2, 3...)", panelX + 20, panelY + 440);
  text("- Use buttons to add/remove sources", panelX + 20, panelY + 460);
  
  hint(ENABLE_DEPTH_TEST);
}

void drawCubeFrame() {
  strokeWeight(2);
  stroke(100, 120, 140);
  noFill();
  
  // Draw cube centered at origin using box() primitive
  box(boundarySize);
}
void drawCoordinateSystem() {
  strokeWeight(1);
  
  // X axis (red)
  stroke(255, 0, 0);
  line(0, 0, 0, 100, 0, 0);
  pushMatrix();
  translate(110, 0, 0);
  fill(255, 0, 0);
  text("X", 0, 0);
  popMatrix();
  
  // Y axis (green) - Flipped
  stroke(0, 255, 0);
  line(0, 0, 0, 0, -100, 0); // Inverted direction
  pushMatrix();
  translate(0, -110, 0); // Adjusted label position
  fill(0, 255, 0);
  text("Y", 0, 0);
  popMatrix();
  
  // Z axis (blue)
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 100);
  pushMatrix();
  translate(0, 0, 110);
  fill(0, 0, 255);
  text("Z", 0, 0);
  popMatrix();
}

// Window resize handling - automatically called by Processing
void windowResized() {
  // Recalculate positions for ControlP5 elements
  float panelX = width - 300;
  float sliderX = panelX + 50;
  
  // Update slider positions
  cp5.getController("radius")
     .setPosition(sliderX, 300);
     
  cp5.getController("azimuth")
     .setPosition(sliderX, 350);
     
  cp5.getController("zenith")
     .setPosition(sliderX, 400);
  
  // Update button positions
  cp5.getController("addSource")
     .setPosition(sliderX, 450);
     
  cp5.getController("removeSource")
     .setPosition(sliderX + 105, 450);
}

// Button event handlers
void addSource() {
  // Add a new sound source with random position
  soundSources.add(new SoundSource(random(50, boundarySize - 50), random(TWO_PI), random(PI)));
  selectedSource = soundSources.size() - 1;
}

void removeSource() {
  if (soundSources.size() > 1) {
    // Remove the selected sound source
    soundSources.remove(selectedSource);
    selectedSource = selectedSource % soundSources.size();
  }
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

class SoundSource {
  float radius;      // Distance from center
  float azimuth;     // Horizontal angle (0 to 2π)
  float zenith;      // Vertical angle (0 to π)
  float x, y, z;     // Cartesian coordinates
  color sourceColor;
  
  SoundSource(float r, float a, float z) {
    radius = constrain(r, 50, boundarySize - 50);
    azimuth = a;
    zenith = z;
    sourceColor = color(random(100, 255), random(100, 255), random(100, 255));
    updatePosition();
  }
  
 void updatePosition() {
    // Convert spherical to Cartesian coordinates
    x = radius * sin(zenith) * cos(azimuth);
    z = radius * sin(zenith) * sin(azimuth);
    y = -radius * cos(zenith); // Flip the Y-axis
  }

  void display(boolean selected) {
    pushMatrix();
    translate(x, y, z);
    
    // Draw selection indicator if selected
    if (selected) {
      stroke(255, 255, 0);
      strokeWeight(2);
      noFill();
      box(25);
    }
    
    // Draw sound source
    noStroke();
    fill(sourceColor);
    sphere(12);
    
    // Draw sound waves emanating from source
    drawSoundWaves();
    
    popMatrix();
  }
  
  void drawSoundWaves() {
    // Draw circular sound wave indicators
    float waveRadius = sin(frameCount * 0.1) * 8 + 18;
    stroke(red(sourceColor), green(sourceColor), blue(sourceColor), 150);
    strokeWeight(1.5);
    noFill();
    
    pushMatrix();
    rotateX(HALF_PI);
    ellipse(0, 0, waveRadius, waveRadius);
    popMatrix();
    
    pushMatrix();
    rotateY(HALF_PI);
    ellipse(0, 0, waveRadius, waveRadius);
    popMatrix();
    
    pushMatrix();
    rotateZ(HALF_PI);
    ellipse(0, 0, waveRadius, waveRadius);
    popMatrix();
  }


}
  // Log MIDI Control Change messages (e.g., knobs, faders, etc.)
void controllerChange(int channel, int number, int value) {
  // Ensure we're working with channel 0 and control numbers 1 to 3
  if (channel == 0) {
    // Check for Control Change values and map them to the corresponding sound source property
    if (selectedSource >= 0 && selectedSource < soundSources.size()) {
      SoundSource source = soundSources.get(selectedSource);

      // Control Change for Radius (Control number 1)
      if (number == 1) {
        // Map MIDI value (0-127) to the radius range (50 to boundarySize - 50)
        float mappedRadius = map(value, 0, 127, 50, boundarySize - 50);
        source.radius = mappedRadius;
        source.updatePosition(); // Update the position based on the new radius
        println("Updated Radius: " + source.radius);
      }

      // Control Change for Azimuth (Control number 2)
      if (number == 2) {
        // Map MIDI value (0-127) to azimuth range (0 to TWO_PI)
        float mappedAzimuth = map(value, 0, 127, 0, TWO_PI);
        source.azimuth = mappedAzimuth;
        source.updatePosition(); // Update the position based on the new azimuth
        println("Updated Azimuth: " + source.azimuth);
      }

      // Control Change for Zenith (Control number 3)
      if (number == 3) {
        // Map MIDI value (0-127) to zenith range (0 to PI)
        float mappedZenith = map(value, 0, 127, 0, PI);
        source.zenith = mappedZenith;
        source.updatePosition(); // Update the position based on the new zenith
        println("Updated Zenith: " + source.zenith);
      }
    }
  }
}

// Listen for MIDI "note on" messages
void noteOn(int channel, int note, int velocity) {
  // Check if the note is within the range of 36 to 43
  if (note >= 36 && note <= 43) {
    // Map the note to the index of soundSources (36 maps to index 0, 37 to 1, ..., 43 to 7)
    selectedSource = note - 36;  // This will give us an index from 0 to 7
    
    // Print the note and the selected source
    println("[NOTE ON] Channel: " + channel + ", Note: " + note + ", Velocity: " + velocity + " - Source selected: " + selectedSource);
  }
}
