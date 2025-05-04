/**
 * VisualizationManager
 * Manages different visualization modes (2D and 3D) and handles switching between them
 */
class VisualizationManager {
  View3D view3D;
  View2D view2D;
  Rectangle container;  
  boolean is3DMode = true; // Default to 3D mode
  
  // Constructor
  VisualizationManager(float boundarySize, float headSize) {
    view3D = new View3D(boundarySize, headSize);
    view2D = new View2D(boundarySize, headSize);
  }

  void setContainer(Rectangle container) {
    this.container = container;
  }
  
  // Draw the current visualization
  void draw(ArrayList<SoundSource> soundSources, int selectedSource) {
    if (container == null) return;

    drawBackground(container, color(30, 35, 45)); // Draw background

    pushMatrix();
    if (is3DMode) {
      view3D.draw(soundSources, selectedSource, container);
    } else {
      view2D.draw(soundSources, selectedSource, container);
    }
    popMatrix();
  }

  // Helper method to draw a background rectangle
  void drawBackground(Rectangle container, color bgColor) {
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();
    fill(bgColor);
    noStroke();
    rect(container.x, container.y, container.width, container.height, 10);
    hint(ENABLE_DEPTH_TEST);
  }
  
  // Toggle between 2D and 3D modes
  void toggleMode() {
    is3DMode = !is3DMode;
  }
  
  // Get current mode as string (for UI display)
  String getCurrentMode() {
    return is3DMode ? "3D View" : "2D Views (Front/Top/Side)";
  }
  
  // Update visualization parameters if needed
  void updateParameters(float boundarySize, float headSize) {
    view3D.updateParameters(boundarySize, headSize);
    view2D.updateParameters(boundarySize, headSize);
  }
}

/**
 * View3D
 * Handles the 3D cube visualization
 */
class View3D {
  float boundarySize;
  float headSize;
  CubeRenderer cubeRenderer;
  
  // Constructor
  View3D(float boundarySize, float headSize) {
    this.boundarySize = boundarySize;
    this.headSize = headSize;
    this.cubeRenderer = new CubeRenderer(boundarySize);
  }
  
  // Draw the 3D scene
  void draw(ArrayList<SoundSource> soundSources, int selectedSource, Rectangle container) {
    pushMatrix();

    // Calculate the scale factor to fit the cube within the container
    float scaleFactor = min(container.width, container.height) / (boundarySize * 1.5);

    // Translate to the center of the container in all three dimensions
    translate(container.x + container.width / 2 + boundarySize / 6, container.y + container.height / 2, 0);

    // Apply scaling to fit the cube within the container
    scale(scaleFactor);

    // Adjust rotation for a better perspective view
    rotateX(radians(-33));  // Tilt the view slightly downward
    rotateY(0);             // No rotation on the Y-axis

    // Set up lighting
    ambientLight(50, 50, 50);
    directionalLight(200, 200, 200, -1, -1, -1);

    // Draw the cube frame
    cubeRenderer.drawCubeFrame(container);

    // Draw the coordinate system
    cubeRenderer.drawCoordinateSystem(container);

    // Draw the central head (fixed at the center of the cube)
    pushMatrix();
    noStroke();
    fill(220, 190, 170);
    sphere(headSize);
    popMatrix();

    // Draw sound sources
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      boolean isSelected = (i == selectedSource);
      source.display(isSelected, i + 1); // Pass the source number (1-indexed)

      // Draw a line connecting the source to the head
      stroke(180, 180, 200, 150);
      strokeWeight(1);
      line(0, 0, 0, source.x, source.y, source.z);
    }

    popMatrix();
  }
  
  // Update visualization parameters
  void updateParameters(float boundarySize, float headSize) {
    this.boundarySize = boundarySize;
    this.headSize = headSize;
    this.cubeRenderer = new CubeRenderer(boundarySize);
  }
}
/**
 * View2D
 * Handles the 2D perspective views (front, top, and side)
 */
class View2D {
  float boundarySize;
  float headSize;
  
  // Constructor
  View2D(float boundarySize, float headSize) {
    this.boundarySize = boundarySize;
    this.headSize = headSize;
  }
  
  // Draw all 2D views
  void draw(ArrayList<SoundSource> soundSources, int selectedSource, Rectangle container) {
    // Calculate the size and position of each quadrant within the container
    float quadWidth = container.width * 0.5f;
    float quadHeight = container.height * 0.5f;
    
    // Draw each perspective view in its own quadrant
    drawFrontView(container.x, container.y, quadWidth, quadHeight, soundSources, selectedSource);
    drawTopView(container.x, container.y + quadHeight, quadWidth, quadHeight, soundSources, selectedSource);
    drawSideView(container.x + quadWidth, container.y, quadWidth, quadHeight, soundSources, selectedSource);
    
    // Optional: Draw a legend or additional info in the bottom-right quadrant
    drawInfoPanel(container.x + quadWidth, container.y + quadHeight, quadWidth, quadHeight);
  }
  
  // Draw front view (X-Y plane)
  void drawFrontView(float x, float y, float w, float h, ArrayList<SoundSource> soundSources, int selectedSource) {
    pushMatrix();
    // Set up the view area
    translate(x, y);
    
    // Draw border and title
    stroke(200, 200, 255);
    strokeWeight(2);
    fill(40, 45, 55, 200);
    rect(0, 0, w, h);
    
    fill(255);
    textAlign(CENTER);
    textSize(16);
    text("Front View (X-Y)", w/2, 24);
    
    // Set up coordinate system with origin at center
    translate(w/2, h/2);
    
    // Draw grid lines
    drawGrid(w, h, 8);
    
    // Draw axes
    drawAxes(w*0.45, h*0.45, "X", "Y");
    
    // Scale for better visibility
    float scale = min(w, h) / boundarySize;
    scale(scale, scale);
    
    // Draw bounding square representing the cube's front face
    drawBoundingSquare();
    
    // Draw head (center point)
    noStroke();
    fill(220, 190, 170);
    ellipse(0, 0, headSize, headSize);
    
    // Draw sound sources
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      boolean isSelected = (i == selectedSource);
      
      // Calculate 2D position for front view (X-Y plane)
      // Y coordinate is inverted in Processing
      float sourceX = source.x;
      float sourceY = source.y; // Invert Y for screen coordinates
      
      // Draw the source with its color
      draw2DSource(sourceX, sourceY, source.volume, source.vuLevel, isSelected, i + 1, source.sourceColor);
      
      // Draw line connecting source to head
      stroke(180, 180, 200, 100);
      strokeWeight(1);
      line(0, 0, sourceX, sourceY);
    }
    popMatrix();
  }
  
  // Draw top view (X-Z plane)
  void drawTopView(float x, float y, float w, float h, ArrayList<SoundSource> soundSources, int selectedSource) {
    pushMatrix();
    // Set up the view area
    translate(x, y);
    
    // Draw border and title
    stroke(200, 200, 255);
    strokeWeight(2);
    fill(40, 45, 55, 200);
    rect(0, 0, w, h);
    
    fill(255);
    textAlign(CENTER);
    textSize(16);
    text("Top View (X-Z)", w/2, 24);
    
    // Set up coordinate system with origin at center
    translate(w/2, h/2);
    
    // Draw grid lines
    drawGrid(w, h, 8);
    
    // Draw axes
    drawAxes(w*0.45, h*0.45, "X", "Z");
    
    // Scale for better visibility
    float scale = min(w, h) / boundarySize;
    scale(scale, scale);
    
    // Draw bounding square representing the cube's top face
    drawBoundingSquare();
    
    // Draw head (center point)
    noStroke();
    fill(220, 190, 170);
    ellipse(0, 0, headSize, headSize);
    
    // Draw sound sources
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      boolean isSelected = (i == selectedSource);
      
      // Calculate 2D position for top view (X-Z plane)
      float sourceX = source.x;
      float sourceZ = source.z;
      
      // Draw the source with its color
      draw2DSource(sourceX, sourceZ, source.volume, source.vuLevel, isSelected, i + 1, source.sourceColor);
      
      // Draw line connecting source to head
      stroke(180, 180, 200, 100);
      strokeWeight(1);
      line(0, 0, sourceX, sourceZ);
    }
    popMatrix();
  }
  
  // Draw side view (Z-Y plane)
  void drawSideView(float x, float y, float w, float h, ArrayList<SoundSource> soundSources, int selectedSource) {
    pushMatrix();
    // Set up the view area
    translate(x, y);
    
    // Draw border and title
    stroke(200, 200, 255);
    strokeWeight(2);
    fill(40, 45, 55, 200);
    rect(0, 0, w, h);
    
    fill(255);
    textAlign(CENTER);
    textSize(16);
    text("Side View (Z-Y)", w/2, 24);
    
    // Set up coordinate system with origin at center
    translate(w/2, h/2);
    
    // Draw grid lines
    drawGrid(w, h, 8);
    
    // Draw axes
    drawAxes(w*0.45, h*0.45, "Z", "Y");
    
    // Scale for better visibility
    float scale = min(w, h) / boundarySize;
    scale(scale, scale);
    
    // Draw bounding square representing the cube's side face
    drawBoundingSquare();
    
    // Draw head (center point)
    noStroke();
    fill(220, 190, 170);
    ellipse(0, 0, headSize, headSize);
    
    // Draw sound sources
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      boolean isSelected = (i == selectedSource);
      
      // Calculate 2D position for side view (Z-Y plane)
      float sourceZ = -source.z;
      float sourceY = source.y; // Invert Y for screen coordinates
      
      // Draw the source with its color
      draw2DSource(sourceZ, sourceY, source.volume, source.vuLevel, isSelected, i + 1, source.sourceColor);
      
      // Draw line connecting source to head
      stroke(180, 180, 200, 100);
      strokeWeight(1);
      line(0, 0, sourceZ, sourceY);
    }
    popMatrix();
  }
  
  // Draw bounding square representing the cube faces in 2D views
  void drawBoundingSquare() {
    // Use half of the boundary size to draw from center
    float halfSize = boundarySize / 2;
    
    // Draw square with light blue color and low opacity
    stroke(80, 120, 200, 150);
    strokeWeight(1.5);
    noFill();
    rectMode(CENTER);
    rect(0, 0, boundarySize, boundarySize);
    
    // Optional: Add markers at the corners for better visibility
    float cornerSize = 5;
    
    // Top-left corner
    line(-halfSize, -halfSize, -halfSize + cornerSize, -halfSize);
    line(-halfSize, -halfSize, -halfSize, -halfSize + cornerSize);
    
    // Top-right corner
    line(halfSize, -halfSize, halfSize - cornerSize, -halfSize);
    line(halfSize, -halfSize, halfSize, -halfSize + cornerSize);
    
    // Bottom-left corner
    line(-halfSize, halfSize, -halfSize + cornerSize, halfSize);
    line(-halfSize, halfSize, -halfSize, halfSize - cornerSize);
    
    // Bottom-right corner
    line(halfSize, halfSize, halfSize - cornerSize, halfSize);
    line(halfSize, halfSize, halfSize, halfSize - cornerSize);
    
    // Reset rectMode to default
    rectMode(CORNER);
  }
  
  // Draw information panel (bottom-right quadrant)
  void drawInfoPanel(float x, float y, float w, float h) {
    pushMatrix();
    translate(x, y);
    
    // Draw border and title
    stroke(200, 200, 255);
    strokeWeight(2);
    fill(40, 45, 55, 200);
    rect(0, 0, w, h);
    
    fill(255);
    textAlign(CENTER);
    textSize(16);
    text("Information", w/2, 24);
    
    // Draw legend and instructions
    textAlign(LEFT);
    textSize(14);
    fill(220);
    
    String[] info = {
      "Legend:",
      "• Circle: Sound Source",
      "• Number: Source ID",
      "• Size: Volume Level",
      "• Brightness: Audio Level",
      "• Blue Square: Boundary Limits",
      "",
      "Press 'V' to toggle 2D/3D view",
      "Press 1-9 to select a source",
      "Use sliders to adjust position"
    };
    
    float lineHeight = 20;
    for (int i = 0; i < info.length; i++) {
      text(info[i], 20, 50 + i * lineHeight);
    }
    
    popMatrix();
  }
  
  // Helper method to draw a single sound source in 2D
  void draw2DSource(float x, float y, float volume, float vuLevel, boolean isSelected, int sourceNumber, color sourceColor) {
    // Calculate size based on volume (minimum size of 10, maximum of 30)
    float size = map(volume, 0, 1, 30, 60);
    
    // Use vuLevel to determine brightness
    float brightness = map(vuLevel, 0, 1, 100, 255);
    
    // Draw a circle for the sound source
    if (isSelected) {
      // Highlight selected source
      stroke(255, 255, 0);
      strokeWeight(2);
      fill(brightness, brightness, 100);
    } else {
      stroke(200);
      strokeWeight(1);
      fill(red(sourceColor), green(sourceColor), blue(sourceColor), brightness);
    }
    
    ellipse(x, y, size, size);
    
    // Display source number
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(min(size * 0.6, 20));
    text(sourceNumber, x, y);
  }
  
  // Helper method to draw grid lines
  void drawGrid(float w, float h, int divisions) {
    stroke(100, 100, 120, 120);
    strokeWeight(0.5);
    
    float cellWidth = w / divisions;
    float cellHeight = h / divisions;
    
    // Draw horizontal grid lines
    for (int i = -divisions/2; i <= divisions/2; i++) {
      float y = i * cellHeight;
      line(-w/2, y, w/2, y);
    }
    
    // Draw vertical grid lines
    for (int i = -divisions/2; i <= divisions/2; i++) {
      float x = i * cellWidth;
      line(x, -h/2, x, h/2);
    }
  }
  
  // Helper method to draw coordinate axes
  void drawAxes(float xLength, float yLength, String xLabel, String yLabel) {
    // X axis

    if (xLabel.equals("Z")) {
      stroke(100, 100, 255);
      strokeWeight(2);
      line(-xLength, 0, xLength, 0);
      fill(100, 100, 255);
    }else {
      stroke(220, 100, 100);
      strokeWeight(2);
      line(-xLength, 0, xLength, 0);
      fill(220, 100, 100);
    }
    triangle(xLength, 0, xLength - 7, -4, xLength - 7, 4);
    textAlign(CENTER);
    textSize(14);
    text(xLabel, xLength + 10, 5);
    
    // Y axis
    if (yLabel.equals("Z")) {
      stroke(100, 100, 255);
      strokeWeight(2);
      line(0, yLength, 0, -yLength);
      fill(100, 100, 255);
    }else {
      stroke(100, 220, 100);
      strokeWeight(2);
      line(0, yLength, 0, -yLength);
      fill(100, 220, 100);
    }
    triangle(0, -yLength, -4, -yLength + 7, 4, -yLength + 7);
    textAlign(CENTER);
    textSize(14);
    text(yLabel, 0, -yLength - 10);
    

  }
  
  // Update visualization parameters
  void updateParameters(float boundarySize, float headSize) {
    this.boundarySize = boundarySize;
    this.headSize = headSize;
  }
}