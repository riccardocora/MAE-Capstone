class VisualizationManager {
  View3D view3D;
  View2D view2D;
  Rectangle container;  
  boolean is3DMode = true; // Default to 3D mode
  float roll = 0;  // Camera rotation around the Z-axis
  float yaw = 0;   // Camera rotation around the Y-axis
  float pitch = 0; // Camera rotation around the X-axis
  
  CentralHead centralHead; // The central head with its own rotation parameters
  
  boolean isMouseOver = false;
  boolean isDragging = false;
  float lastMouseX, lastMouseY;
  // Constructor
  VisualizationManager(float boundarySize, float headSize) {
    view3D = new View3D(boundarySize, headSize);
    view2D = new View2D(boundarySize, headSize);
    centralHead = new CentralHead(headSize);
    view3D.setParent(this);
    view2D.setParent(this);
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
      view3D.draw(soundSources, selectedSource, container, roll, yaw, pitch);
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

  void setRoll(float roll) {
    this.roll = roll;
  }

  void setYaw(float yaw) {
    this.yaw = yaw;
  }

  void setPitch(float pitch) {
    this.pitch = pitch;
  }
  
  // Check if the mouse is over the visualization container
  boolean isMouseOverVisualization() {
    return container != null && 
           mouseX >= container.x && mouseX <= container.x + container.width && 
           mouseY >= container.y && mouseY <= container.y + container.height;
  }
  
  // Handle mouse pressed events
  void handleMousePressed() {
    if (isMouseOverVisualization() && is3DMode) {
      isMouseOver = true;
      isDragging = true;
      lastMouseX = mouseX;
      lastMouseY = mouseY;
    }
  }
  
  // Handle mouse dragged events
  void handleMouseDragged() {
    if (isDragging && is3DMode) {
      // Calculate the mouse movement
      float deltaX = mouseX - lastMouseX;
      float deltaY = mouseY - lastMouseY;
      
      // Update rotation values (scale the movement)
      // Map mouse movement to your coordinate system rotations
      yaw += deltaX * 0.01;    // Horizontal mouse movement -> yaw (Y-axis rotation)
      pitch += deltaY * 0.01;  // Vertical mouse movement -> pitch (X-axis rotation)
      
      // Constrain pitch to avoid gimbal lock
      pitch = constrain(pitch, -PI/2, PI/2);
      
      // Store current mouse position for next frame
      lastMouseX = mouseX;
      lastMouseY = mouseY;
    }
  }
  
  // Handle mouse released events
  void handleMouseReleased() {
    isDragging = false;
    isMouseOver = false;
  }  // Reset all rotations to default values
  void resetRotation() {
    // Reset camera rotation
    roll = 0;
    yaw = 0;
    pitch = 0;
    
    // // Reset central head rotation
    // if (centralHead != null) {
    //   centralHead.resetRotation();
    // }
    
    // // Reset cube rotation
    // resetCubeRotation();
  }
  
  // Reset only camera rotation (not head)
  void resetCameraRotation() {
    roll = 0;
    yaw = 0;
    pitch = 0;
  }
  
  // Reset only head rotation (not camera)
  void resetHeadRotation() {
    if (centralHead != null) {
      centralHead.resetRotation();
    }
  }
  
  // Set cube roll rotation
  void setCubeRoll(float roll) {
    if (view3D != null && view3D.cubeRenderer != null) {
      view3D.cubeRenderer.setRoll(roll);
    }
  }
  
  // Set cube yaw rotation
  void setCubeYaw(float yaw) {
    if (view3D != null && view3D.cubeRenderer != null) {
      view3D.cubeRenderer.setYaw(yaw);
    }
  }
  
  // Set cube pitch rotation
  void setCubePitch(float pitch) {
    if (view3D != null && view3D.cubeRenderer != null) {
      view3D.cubeRenderer.setPitch(pitch);
    }
  }
  
  // Reset only cube rotation
  void resetCubeRotation() {
    if (view3D != null && view3D.cubeRenderer != null) {
      view3D.cubeRenderer.resetRotation();
    }
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
  }  // Draw the 3D scene
  void draw(ArrayList<SoundSource> soundSources, int selectedSource, Rectangle container, float roll, float yaw, float pitch) {
    pushMatrix();

    // Calculate the scale factor to fit the cube within the container
    float scaleFactor = min(container.width, container.height) / (boundarySize *1.5f);

    // Translate to the center of the container in all three dimensions
    translate(container.x + container.width / 2, container.y + container.height / 2, 0);

    // Apply scaling to fit the cube within the container
    scale(scaleFactor);

    // Apply camera rotations to the view (this rotates the whole scene)
    rotateZ(roll);  // Roll (Z-axis)
    rotateY(yaw);   // Yaw (Y-axis)
    rotateX(pitch); // Pitch (X-axis)
    
    // Set up lighting
    ambientLight(50, 50, 50);
    directionalLight(200, 200, 200, 0, 1, -1);

    // Draw the cube frame
    cubeRenderer.drawCubeFrame(container);

    // Draw the sound sources
    drawSoundSources(soundSources, selectedSource);
    
    // Draw the central head with its own independent rotation
    if (parent != null && parent.centralHead != null) {
      parent.centralHead.draw();
    }

    popMatrix();
  }
  
  // Set parent reference
  private VisualizationManager parent;
  
  void setParent(VisualizationManager parent) {
    this.parent = parent;
  }
  // Draw the sound sources
  void drawSoundSources(ArrayList<SoundSource> soundSources, int selectedSource) {
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      boolean isSelected = (i == selectedSource);
      
      // Only draw mono/stereo sources and connection lines
      if (source.type == SourceType.MONO_STEREO) {
        source.display(isSelected, i + 1); // Pass the source number (1-indexed)

        // Draw a line connecting the source to the head
        stroke(180, 180, 200, 150);
        strokeWeight(1);
        line(0, 0, 0, source.x, -source.y, -source.z);
      }
    }
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
  private VisualizationManager parent;
  
  // Constructor
  View2D(float boundarySize, float headSize) {
    this.boundarySize = boundarySize;
    this.headSize = headSize;
  }
  
  // Set parent reference
  void setParent(VisualizationManager parent) {
    this.parent = parent;
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
    drawBoundingSquare("Front");
    
    // Draw head with its rotation
    noStroke();
    fill(220, 190, 170);
    
    // Draw basic head circle
    ellipse(0, 0, headSize, headSize);
    
    // Draw head axes based on rotation (for front view: X-Y plane)
    if (parent != null && parent.centralHead != null) {
      // Calculate axis projections for front view (X-Y plane)
      // Front view shows X and Y axes, affected by yaw (Y-axis) and roll (Z-axis)
      strokeWeight(2);
      
      // X-axis (red) - affected by roll and yaw
      stroke(255, 0, 0);
      float xLen = headSize * 1.5;
      float xRotX = xLen * cos(parent.centralHead.roll) * cos(parent.centralHead.yaw);
      float xRotY = xLen * sin(parent.centralHead.roll);
      line(0, 0, xRotX, xRotY);
      
      // Y-axis (green) - affected by roll and yaw
      stroke(0, 255, 0);
      float yLen = headSize * 1.5;
      float yRotX = -yLen * sin(parent.centralHead.roll) * sin(parent.centralHead.yaw);
      float yRotY = -yLen * cos(parent.centralHead.roll);
      line(0, 0, yRotX, yRotY);
    }
    
    // Draw sound sources with rotation applied if cube rotation exists
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      
      // Skip drawing non-MONO_STEREO sources
      if (source.type != SourceType.MONO_STEREO) {
        continue;
      }
      
      boolean isSelected = (i == selectedSource);
      
      // Get the source position
      float sourceX = source.x;
      float sourceY = -source.y;
      float sourceZ = -source.z;
      
      // // Apply cube rotation transformation if available
      // if (parent != null && parent.view3D != null && parent.view3D.cubeRenderer != null) {
      //   PVector rotatedPos = rotatePoint(
      //     new PVector(sourceX, sourceY, sourceZ),
      //     parent.view3D.cubeRenderer.roll,
      //     parent.view3D.cubeRenderer.yaw,
      //     parent.view3D.cubeRenderer.pitch
      //   );
        
      //   sourceX = rotatedPos.x;
      //   sourceY = rotatedPos.y;
      // }
      
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
    drawBoundingSquare("Top");
    
    // Draw head with its rotation
    noStroke();
    fill(220, 190, 170);
    
    // Draw basic head circle
    ellipse(0, 0, headSize, headSize);
    
    // Draw head axes based on rotation (for top view: X-Z plane)
    if (parent != null && parent.centralHead != null) {
      // Calculate axis projections for top view (X-Z plane)
      // Top view shows X and Z axes, affected by pitch (X-axis) and yaw (Y-axis)
      strokeWeight(2);
      
      // X-axis (red) - affected by yaw
      stroke(255, 0, 0);
      float xLen = headSize * 1.5;
      float xRotX = xLen * cos(parent.centralHead.yaw);
      float xRotZ = xLen * sin(parent.centralHead.yaw);
      line(0, 0, xRotX, xRotZ);
      
      // Z-axis (blue) - affected by pitch
      stroke(0, 0, 255);
      float zLen = headSize * 1.5;
      float zRotX = zLen * sin(parent.centralHead.pitch) * sin(parent.centralHead.yaw);
      float zRotZ = zLen * cos(parent.centralHead.pitch);
      line(0, 0, zRotX, zRotZ);
    }
    
    // Draw sound sources with rotation applied if cube rotation exists
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      
      // Skip drawing non-MONO_STEREO sources
      if (source.type != SourceType.MONO_STEREO) {
        continue;
      }
      
      boolean isSelected = (i == selectedSource);
      
      // Get the source position
      float sourceX = source.x;
      float sourceY = -source.y;
      float sourceZ = -source.z;
      
      // // Apply cube rotation transformation if available
      // if (parent != null && parent.view3D != null && parent.view3D.cubeRenderer != null) {
      //   PVector rotatedPos = rotatePoint(
      //     new PVector(sourceX, sourceY, sourceZ),
      //     parent.view3D.cubeRenderer.roll,
      //     parent.view3D.cubeRenderer.yaw,
      //     parent.view3D.cubeRenderer.pitch
      //   );
        
      //   sourceX = rotatedPos.x;
      //   sourceZ = rotatedPos.z;
      // }
      
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
    drawBoundingSquare("Side");
    
    // Draw head with its rotation
    noStroke();
    fill(220, 190, 170);
    
    // Draw basic head circle
    ellipse(0, 0, headSize, headSize);
    
    // Draw head axes based on rotation (for side view: Z-Y plane)
    if (parent != null && parent.centralHead != null) {
      // Calculate axis projections for side view (Z-Y plane)
      // Side view shows Z and Y axes, affected by roll (Z-axis) and pitch (X-axis)
      strokeWeight(2);
      
      // Z-axis (blue) - affected by pitch
      stroke(0, 0, 255);
      float zLen = headSize * 1.5;
      float zRotZ = zLen * cos(parent.centralHead.pitch);
      float zRotY = zLen * sin(parent.centralHead.pitch);
      line(0, 0, zRotZ, zRotY);
      
      // Y-axis (green) - affected by roll and pitch
      stroke(0, 255, 0);
      float yLen = headSize * 1.5;
      float yRotZ = -yLen * sin(parent.centralHead.roll) * sin(parent.centralHead.pitch);
      float yRotY = -yLen * cos(parent.centralHead.roll);
      line(0, 0, yRotZ, yRotY);
    }
    
    // Draw sound sources with rotation applied if cube rotation exists
    for (int i = 0; i < soundSources.size(); i++) {
      SoundSource source = soundSources.get(i);
      
      // Skip drawing non-MONO_STEREO sources
      if (source.type != SourceType.MONO_STEREO) {
        continue;
      }
      
      boolean isSelected = (i == selectedSource);
      
      // Get the source position
      float sourceX = source.x;
      float sourceY = -source.y;
      float sourceZ = source.z;
      
      // // Apply cube rotation transformation if available
      // if (parent != null && parent.view3D != null && parent.view3D.cubeRenderer != null) {
      //   PVector rotatedPos = rotatePoint(
      //     new PVector(sourceX, sourceY, sourceZ),
      //     parent.view3D.cubeRenderer.roll,
      //     parent.view3D.cubeRenderer.yaw,
      //     parent.view3D.cubeRenderer.pitch
      //   );
        
      //   sourceY = rotatedPos.y;
      //   sourceZ = rotatedPos.z;
      // }
      
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
  void drawBoundingSquare(String viewType) {
    // Use half of the boundary size to draw from center
    float halfSize = boundarySize / 2;
    
    // Get cube rotation parameters if available
    float cubeRoll = 0;
    float cubeYaw = 0;
    float cubePitch = 0;
    
    if (parent != null && parent.view3D != null && parent.view3D.cubeRenderer != null) {
      cubeRoll = parent.view3D.cubeRenderer.roll;
      cubeYaw = parent.view3D.cubeRenderer.yaw;
      cubePitch = parent.view3D.cubeRenderer.pitch;
    }
    
    // Create vertices for the cube
    PVector[] vertices = new PVector[8];
    
    // Define the 8 corners of the cube
    vertices[0] = new PVector(-halfSize, -halfSize, -halfSize); // Front top left
    vertices[1] = new PVector(halfSize, -halfSize, -halfSize);  // Front top right
    vertices[2] = new PVector(halfSize, halfSize, -halfSize);   // Front bottom right
    vertices[3] = new PVector(-halfSize, halfSize, -halfSize);  // Front bottom left
    vertices[4] = new PVector(-halfSize, -halfSize, halfSize);  // Back top left
    vertices[5] = new PVector(halfSize, -halfSize, halfSize);   // Back top right
    vertices[6] = new PVector(halfSize, halfSize, halfSize);    // Back bottom right
    vertices[7] = new PVector(-halfSize, halfSize, halfSize);   // Back bottom left
    
    // Apply rotations to all vertices
    for (int i = 0; i < 8; i++) {
      // Apply rotations in Z-Y-X order (roll, yaw, pitch)
      vertices[i] = rotatePoint(vertices[i], cubeRoll, cubeYaw, cubePitch);
    }
    
    // Draw square with light blue color and low opacity
    stroke(80, 120, 200, 150);
    strokeWeight(1.5);
    noFill();
    
    // Draw cube faces based on the view type
    if (viewType.equals("Front")) {
      // Front face (X-Y plane)
      beginShape();
      vertex(vertices[0].x, vertices[0].y);
      vertex(vertices[1].x, vertices[1].y);
      vertex(vertices[2].x, vertices[2].y);
      vertex(vertices[3].x, vertices[3].y);
      endShape(CLOSE);
      
      // Draw diagonal for orientation reference
      stroke(80, 120, 200, 100);
      line(vertices[0].x, vertices[0].y, vertices[2].x, vertices[2].y);
      
      // Draw back face with dashed lines
      stroke(80, 120, 200, 80);
      drawDashedLine(vertices[4].x, vertices[4].y, vertices[5].x, vertices[5].y);
      drawDashedLine(vertices[5].x, vertices[5].y, vertices[6].x, vertices[6].y);
      drawDashedLine(vertices[6].x, vertices[6].y, vertices[7].x, vertices[7].y);
      drawDashedLine(vertices[7].x, vertices[7].y, vertices[4].x, vertices[4].y);

    } else if (viewType.equals("Top")) {
      // Top view (X-Z plane)
      beginShape();
      vertex(vertices[0].x, -vertices[0].z);
      vertex(vertices[1].x, -vertices[1].z);
      vertex(vertices[5].x, -vertices[5].z);
      vertex(vertices[4].x, -vertices[4].z);
      endShape(CLOSE);
      
      // Draw diagonal for orientation reference
      stroke(80, 120, 200, 100);
      line(vertices[0].x, -vertices[0].z, vertices[5].x, -vertices[5].z);
      
      // Draw bottom face with dashed lines
      stroke(80, 120, 200, 80);
      drawDashedLine(vertices[3].x, -vertices[3].z, vertices[2].x, -vertices[2].z);
      drawDashedLine(vertices[2].x, -vertices[2].z, vertices[6].x, -vertices[6].z);
      drawDashedLine(vertices[6].x, -vertices[6].z, vertices[7].x, -vertices[7].z);
      drawDashedLine(vertices[7].x, -vertices[7].z, vertices[3].x, -vertices[3].z);
      
    } else if (viewType.equals("Side")) {
      // Side view (Z-Y plane)
      beginShape();
      vertex(-vertices[0].z, vertices[0].y);
      vertex(-vertices[4].z, vertices[4].y);
      vertex(-vertices[7].z, vertices[7].y);
      vertex(-vertices[3].z, vertices[3].y);
      endShape(CLOSE);
      
      // Draw diagonal for orientation reference
      stroke(80, 120, 200, 100);
      line(-vertices[0].z, vertices[0].y, -vertices[7].z, vertices[7].y);
      
      // Draw right face with dashed lines
      stroke(80, 120, 200, 80);
      drawDashedLine(-vertices[1].z, vertices[1].y, -vertices[5].z, vertices[5].y);
      drawDashedLine(-vertices[5].z, vertices[5].y, -vertices[6].z, vertices[6].y);
      drawDashedLine(-vertices[6].z, vertices[6].y, -vertices[2].z, vertices[2].y);
      drawDashedLine(-vertices[2].z, vertices[2].y, -vertices[1].z, vertices[1].y);
    }
  }
  
  // Helper method to draw a dashed line
  void drawDashedLine(float x1, float y1, float x2, float y2) {
    float dashLength = 4;
    float gapLength = 4;
    float dx = x2 - x1;
    float dy = y2 - y1;
    float distance = sqrt(dx * dx + dy * dy);
    float dashCount = distance / (dashLength + gapLength);
    float dashX = dx / dashCount;
    float dashY = dy / dashCount;
    
    boolean isDash = true;
    float x = x1;
    float y = y1;
    
    for (int i = 0; i < dashCount; i++) {
      float x2dash = x + dashX;
      float y2dash = y + dashY;
      
      if (isDash) {
        line(x, y, x2dash, y2dash);
      }
      
      x = x2dash;
      y = y2dash;
      isDash = !isDash;
    }
  }
  
  // Helper method to rotate a point around all three axes
  PVector rotatePoint(PVector p, float roll, float yaw, float pitch) {
    PVector result = p.copy();
    
    // Apply roll (Z-axis rotation)
    float tempX = result.x;
    float tempY = result.y;
    result.x = tempX * cos(roll) - tempY * sin(roll);
    result.y = tempX * sin(roll) + tempY * cos(roll);
    
    // Apply yaw (Y-axis rotation)
    tempX = result.x;
    float tempZ = result.z;
    result.x = tempX * cos(yaw) + tempZ * sin(yaw);
    result.z = -tempX * sin(yaw) + tempZ * cos(yaw);
    
    // Apply pitch (X-axis rotation)
    tempY = result.y;
    tempZ = result.z;
    result.y = tempY * cos(pitch) - tempZ * sin(pitch);
    result.z = tempY * sin(pitch) + tempZ * cos(pitch);
    
    return result;
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
    textSize(13);
    fill(220);
    
    // Check if we have cube rotation
    float cubeRoll = 0;
    float cubeYaw = 0;
    float cubePitch = 0;
    
    if (parent != null && parent.view3D != null && parent.view3D.cubeRenderer != null) {
      cubeRoll = parent.view3D.cubeRenderer.roll;
      cubeYaw = parent.view3D.cubeRenderer.yaw;
      cubePitch = parent.view3D.cubeRenderer.pitch;
    }
    
    // Format rotation values for display (convert to degrees and round)
    String rollStr = nf(degrees(cubeRoll), 0, 1);
    String yawStr = nf(degrees(cubeYaw), 0, 1);
    String pitchStr = nf(degrees(cubePitch), 0, 1);
    
    String[] info = {
      "Legend:",
      "• Circle: Sound Source",
      "• Number: Source ID",
      "• Size: Volume Level",
      "• Brightness: Audio Level",
      "• Blue Box: Rotatable Boundary",
      "",
      "Cube Rotation:",
      "• Roll: " + rollStr + "°",
      "• Yaw: " + yawStr + "°", 
      "• Pitch: " + pitchStr + "°",
      "",
      "Keyboard Shortcuts:",
      "• V: Toggle 2D/3D view",
      "• 1-9: Select source",
      "• R: Reset all rotations",
      "• C: Reset head rotation only",
      "• B: Reset cube rotation only"
    };
    
    float lineHeight = 18;
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
