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
import themidibus.*; // Import the MidiBus library
import oscP5.*;     // Add OSC library
import netP5.*;     // Required for network communication



MidiBus myBus; // The MidiBus instance
OscP5 oscP5;   // OSC instance for receiving messages
NetAddress reaper; // NetAddress for sending messages to Reaper

// ControlP5 library
ControlP5 cp5;

// Arrays to store sound source positions
ArrayList<SoundSource> soundSources;
int selectedSource = 0;

// Central subject
float headSize = 30;

// Cube boundary
float boundarySize = 800;

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
   // Initialize OSC
  oscP5 = new OscP5(this, 8000); // Listen on port 8000
  reaper = new NetAddress("127.0.0.1", 8001); // Send to Reaper on port 8001
  
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
  rotateX(radians(-27));  // Looking down from above at a milder angle
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
    source.display(isSelected, i+1); // Pass the source number (1-indexed)
    
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
  // Disable the default drawing of the box
  noFill();
  noStroke();
  
  // Still use the box to generate the geometry
  box(boundarySize);
  
  // Define front and back colors
  color frontColor = color(0, 255, 255);   // Cyan
  color backColor = color(255, 150, 0);    // Orange
  
  // Now draw the edges with custom colors
  float halfSize = boundarySize / 2;
  strokeWeight(2);
  
  // Front face - with mesh (cyan)
  stroke(frontColor);
  // Draw frame
  line(-halfSize, -halfSize, -halfSize, halfSize, -halfSize, -halfSize);
  line(halfSize, -halfSize, -halfSize, halfSize, halfSize, -halfSize);
  line(halfSize, halfSize, -halfSize, -halfSize, halfSize, -halfSize);
  line(-halfSize, halfSize, -halfSize, -halfSize, -halfSize, -halfSize);
  
  // Mesh for front face
  drawMesh(-halfSize, -halfSize, -halfSize, 
           halfSize, halfSize, -halfSize, 
           10, color(red(frontColor), green(frontColor), blue(frontColor), 70));
  
  // Back face - frame only (orange)
  stroke(backColor);
  line(-halfSize, -halfSize, halfSize, halfSize, -halfSize, halfSize);
  line(halfSize, -halfSize, halfSize, halfSize, halfSize, halfSize);
  line(halfSize, halfSize, halfSize, -halfSize, halfSize, halfSize);
  line(-halfSize, halfSize, halfSize, -halfSize, -halfSize, halfSize);
  
  // Side and bottom faces with gradient mesh
  drawGradientMeshes(halfSize, frontColor, backColor);
  
  // Top face - kept as frame only (gradient from cyan to orange)
  drawGradientEdge(-halfSize, -halfSize, -halfSize, halfSize, -halfSize, -halfSize, frontColor, frontColor);
  drawGradientEdge(halfSize, -halfSize, -halfSize, halfSize, -halfSize, halfSize, frontColor, backColor);
  drawGradientEdge(halfSize, -halfSize, halfSize, -halfSize, -halfSize, halfSize, backColor, backColor);
  drawGradientEdge(-halfSize, -halfSize, halfSize, -halfSize, -halfSize, -halfSize, backColor, frontColor);
  
  // Edges connecting front to back with gradient
  for (int i = 0; i <= 1; i++) {
    for (int j = 0; j <= 1; j++) {
      float x = i == 0 ? -halfSize : halfSize;
      float y = j == 0 ? -halfSize : halfSize;
      
      // Draw line with gradient
      drawGradientEdge(x, y, -halfSize, x, y, halfSize, frontColor, backColor);
    }
  }
}

// Function to draw all gradient meshes for side and bottom faces
void drawGradientMeshes(float halfSize, color frontColor, color backColor) {
  // Left side face - with gradient mesh
  drawGradientEdge(-halfSize, -halfSize, -halfSize, -halfSize, halfSize, -halfSize, frontColor, frontColor);
  drawGradientEdge(-halfSize, halfSize, -halfSize, -halfSize, halfSize, halfSize, frontColor, backColor);
  drawGradientEdge(-halfSize, halfSize, halfSize, -halfSize, -halfSize, halfSize, backColor, backColor);
  drawGradientEdge(-halfSize, -halfSize, halfSize, -halfSize, -halfSize, -halfSize, backColor, frontColor);
  
  // Draw gradient mesh on left side
  drawGradientMesh(-halfSize, -halfSize, -halfSize,
                  -halfSize, halfSize, halfSize,
                  10, frontColor, backColor, true);
  
  // Right side face - with gradient mesh
  drawGradientEdge(halfSize, -halfSize, -halfSize, halfSize, halfSize, -halfSize, frontColor, frontColor);
  drawGradientEdge(halfSize, halfSize, -halfSize, halfSize, halfSize, halfSize, frontColor, backColor);
  drawGradientEdge(halfSize, halfSize, halfSize, halfSize, -halfSize, halfSize, backColor, backColor);
  drawGradientEdge(halfSize, -halfSize, halfSize, halfSize, -halfSize, -halfSize, backColor, frontColor);
  
  // Draw gradient mesh on right side
  drawGradientMesh(halfSize, -halfSize, -halfSize,
                  halfSize, halfSize, halfSize,
                  10, frontColor, backColor, true);
  
  // Bottom face - with gradient mesh
  drawGradientEdge(-halfSize, halfSize, -halfSize, halfSize, halfSize, -halfSize, frontColor, frontColor);
  drawGradientEdge(halfSize, halfSize, -halfSize, halfSize, halfSize, halfSize, frontColor, backColor);
  drawGradientEdge(halfSize, halfSize, halfSize, -halfSize, halfSize, halfSize, backColor, backColor);
  drawGradientEdge(-halfSize, halfSize, halfSize, -halfSize, halfSize, -halfSize, backColor, frontColor);
  
  // Draw gradient mesh on bottom (y is inverted)
  drawGradientMesh(-halfSize, halfSize, -halfSize,
                  halfSize, halfSize, halfSize,
                  10, frontColor, backColor, false);
}

// Draw a gradient line between two points with different colors
void drawGradientEdge(float x1, float y1, float z1, float x2, float y2, float z2, color c1, color c2) {
  beginShape(LINES);
  stroke(c1);
  vertex(x1, y1, z1);
  stroke(c2);
  vertex(x2, y2, z2);
  endShape();
}

// Helper function to draw a mesh on a rectangular face with gradient colors
void drawGradientMesh(float x1, float y1, float z1, float x2, float y2, float z2, 
                      int divisions, color frontColor, color backColor, boolean isSideFace) {
  // Calculate step sizes
  float xStep = (x2 - x1) / divisions;
  float yStep = (y2 - y1) / divisions;
  float zStep = (z2 - z1) / divisions;
  
  // Determine which plane this face is on (x, y, or z constant)
  boolean xConstant = (x1 == x2);
  boolean yConstant = (y1 == y2);
  boolean zConstant = (z1 == z2);
  
  // Set stroke weight for mesh lines
  strokeWeight(1);
  
  // Draw horizontal lines
  for (int i = 1; i < divisions; i++) {
    if (xConstant) {
      // Left/Right face (x is constant)
      float y = y1 + i * yStep;
      // Calculate gradient color based on z position
      color startColor = lerpColor(frontColor, backColor, 0);
      color endColor = lerpColor(frontColor, backColor, 1);
      // Draw line with gradient
      drawGradientEdge(x1, y, z1, x1, y, z2, startColor, endColor);
    } else if (yConstant) {
      // Top/Bottom face (y is constant)
      float x = x1 + i * xStep;
      // Draw gradient line front to back
      color startColor = lerpColor(frontColor, backColor, 0);
      color endColor = lerpColor(frontColor, backColor, 1);
      drawGradientEdge(x, y1, z1, x, y1, z2, startColor, endColor);
    } else if (zConstant) {
      // Front/Back face (z is constant) - not used in this case
      float x = x1 + i * xStep;
      line(x, y1, z1, x, y2, z1);
    }
  }
  
  // Draw vertical lines
  for (int i = 1; i < divisions; i++) {
    if (xConstant) {
      // Left/Right face (x is constant)
      float z = z1 + i * zStep;
      // Calculate interpolation factor based on z position
      float t = (z - z1) / (z2 - z1);
      // Interpolate between front and back colors
      color gradientColor = lerpColor(frontColor, backColor, t);
      // Set slightly transparent
      gradientColor = color(red(gradientColor), green(gradientColor), blue(gradientColor), 70);
      stroke(gradientColor);
      line(x1, y1, z, x1, y2, z);
    } else if (yConstant) {
      // Top/Bottom face (y is constant)
      float z = z1 + i * zStep;
      // Calculate interpolation factor based on z position
      float t = (z - z1) / (z2 - z1);
      // Interpolate between front and back colors
      color gradientColor = lerpColor(frontColor, backColor, t);
      // Set slightly transparent
      gradientColor = color(red(gradientColor), green(gradientColor), blue(gradientColor), 70);
      stroke(gradientColor);
      line(x1, y1, z, x2, y1, z);
    } else if (zConstant) {
      // Front/Back face (z is constant) - not used in this case
      float y = y1 + i * yStep;
      line(x1, y, z1, x2, y, z1);
    }
  }
  
  // For side faces, add horizontal lines that follow the gradient
  if (isSideFace && xConstant) {
    for (int i = 0; i <= divisions; i++) {
      float t = (float)i / divisions;
      float z = lerp(z1, z2, t);
      color gradientColor = lerpColor(frontColor, backColor, t);
      gradientColor = color(red(gradientColor), green(gradientColor), blue(gradientColor), 70);
      stroke(gradientColor);
      line(x1, y1, z, x1, y2, z);
    }
  }
}

// Helper function to draw a mesh on a rectangular face
void drawMesh(float x1, float y1, float z1, float x2, float y2, float z2, int divisions, color meshColor) {
  stroke(red(meshColor), green(meshColor), blue(meshColor), alpha(meshColor));
  strokeWeight(1);
  
  // Calculate step sizes
  float xStep = (x2 - x1) / divisions;
  float yStep = (y2 - y1) / divisions;
  float zStep = (z2 - z1) / divisions;
  
  // Determine which plane this face is on (x, y, or z constant)
  boolean xConstant = (x1 == x2);
  boolean yConstant = (y1 == y2);
  boolean zConstant = (z1 == z2);
  
  // Draw horizontal lines
  for (int i = 1; i < divisions; i++) {
    if (xConstant) {
      // Left/Right face (x is constant)
      float y = y1 + i * yStep;
      line(x1, y, z1, x1, y, z2);
    } else if (yConstant) {
      // Top/Bottom face (y is constant)
      float x = x1 + i * xStep;
      line(x, y1, z1, x, y1, z2);
    } else if (zConstant) {
      // Front/Back face (z is constant)
      float x = x1 + i * xStep;
      line(x, y1, z1, x, y2, z1);
    }
  }
  
  // Draw vertical lines
  for (int i = 1; i < divisions; i++) {
    if (xConstant) {
      // Left/Right face (x is constant)
      float z = z1 + i * zStep;
      line(x1, y1, z, x1, y2, z);
    } else if (yConstant) {
      // Top/Bottom face (y is constant)
      float z = z1 + i * zStep;
      line(x1, y1, z, x2, y1, z);
    } else if (zConstant) {
      // Front/Back face (z is constant)
      float y = y1 + i * yStep;
      line(x1, y, z1, x2, y, z1);
    }
  }
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

// New variable to track volume data from Reaper
float[] trackVolumes = new float[8]; // Array to store volume levels for 8 tracks

class SoundSource {
  float radius;      // Distance from center
  float azimuth;     // Horizontal angle (0 to 2π)
  float zenith;      // Vertical angle (0 to π)
  float x, y, z;     // Cartesian coordinates
  color sourceColor;
  float volume = 0;  // Volume level (0-1)
  
  SoundSource(float r, float a, float z) {
    radius = constrain(r, 50, boundarySize - 200);
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

void display(boolean selected, int sourceNumber) {
  pushMatrix();
  translate(x, y, z);

  // Draw selection indicator if selected
  if (selected) {
    stroke(255, 255, 0);
    strokeWeight(2);
    noFill();
    box(25);
  }

  // Draw sound source sphere
  noStroke();
  fill(sourceColor);
  sphere(12);

  // Draw sound waves
  drawSoundWaves(sourceNumber - 1);

  // Draw source number **above the sphere**
  pushMatrix();
  

  // Ensure text faces the camera (billboarding)
 /* PMatrix3D modelview = ((PGraphicsOpenGL) g).modelview.get();
  modelview.m03 = modelview.m13 = modelview.m23 = 0; // Remove translation
  modelview.invert();
  applyMatrix(modelview);*/

  // Background circle for contrast
  fill(0, 0, 0, 200);
  ellipse(0, 0, 30, 30);  

  // Draw text on top
  translate(0, -25, 0);  // Adjust to position text slightly above the sphere
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(16);
  text(sourceNumber, 0, 0);

  popMatrix();  // Restore state
  popMatrix();
}

  void drawSoundWaves(int sourceIndex) {
    // Get volume for this sound source (if available)
    float volume = sourceIndex < trackVolumes.length ? trackVolumes[sourceIndex] : 0;
    
    // Draw circular sound wave indicators
    // Base size on the volume, but always have a minimum size
    float baseWaveRadius = 18;
    float waveRadius = baseWaveRadius;
    
    // If we have volume data, use it to scale the waves
    if (volume > 0) {
      waveRadius = baseWaveRadius + (volume * 100); // Scale up to 15 units larger based on volume
    } else {
      // Use animation if no volume data
      waveRadius = baseWaveRadius + abs(sin(frameCount * 0.1) * 8);
    }
    
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
void sendOsc(float value){
  OscMessage msg = new OscMessage("/track/1/volume");
  msg.add(value);
  oscP5.send(msg,reaper);
  println("sentvolume change:",+value);
}
  // Log MIDI Control Change messages (e.g., knobs, faders, etc.)
void controllerChange(int channel, int number, int value) {
  // Ensure we're working with channel 0 and control numbers 1 to 3
  println("[CC] Channel: " + channel + ", Number: " + number + ", Value: " + value + " - Source selected: " + selectedSource);

  if (channel == 0) {
    // Check for Control Change values and map them to the corresponding sound source property
    if (selectedSource >= 0 && selectedSource < soundSources.size()) {
      SoundSource source = soundSources.get(selectedSource);

      // Control Change for Radius (Control number 1)
      if (number == 1) {
        // Map MIDI value (0-127) to the radius range (50 to boundarySize - 50)
        float mappedRadius = map(value, 0, 127, 50, boundarySize - 200);
        source.radius = mappedRadius;
        source.updatePosition(); // Update the position based on the new radius
        println("Updated Radius: " + source.radius);
        sendOsc(map(radius, 50, 600, 0, 1));
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

// OSC event, automatically called when receiving an OSC message
void oscEvent(OscMessage msg) {
  // Check for track volume messages from Reaper
  // Reaper typically sends track volumes as /track/x/volume where x is the track number
  String pattern = msg.addrPattern();
  
  // Debug incoming message
  //println("Received OSC message: " + pattern + " " + msg);
  
  // Check for volume messages
  // Assuming Reaper sends volume levels as /track/0/volume, /track/1/volume, etc.
  if (pattern.matches("/track/[0-7]/vu")) {
    // Extract track number from the pattern
    String[] parts = pattern.split("/");
    int trackNum = Integer.parseInt(parts[2]);
    
    // Extract volume value (assuming it's sent as a float between 0 and 1)
    float volume = msg.get(0).floatValue();
    
    // Update the volume for this track
    if (trackNum >= 0 && trackNum < trackVolumes.length) {
      trackVolumes[trackNum] = volume;
      println("Updated volume for track " + trackNum + ": " + volume);
    }
  }
  /*else if(pattern.matches("/track/[0-7]/vu")){
    // Extract track number from the pattern
    String[] parts = pattern.split("/");
    int trackNum = Integer.parseInt(parts[2]);
    
    // Extract volume value (assuming it's sent as a float between 0 and 1)
    float volume = msg.get(0).floatValue();
    
    // Update the volume for this track
    if (trackNum >= 0 && trackNum < trackVolumes.length) {
      println("track " + trackNum + "vu meter : " + volume);
    }
  }*/
}
