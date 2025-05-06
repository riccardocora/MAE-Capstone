/**
 * CubeRenderer class
 * Handles drawing the 3D cube frame and coordinate system
 */
class CubeRenderer {
  float boundarySize;
  
  // Constructor
  CubeRenderer(float boundarySize) {
    this.boundarySize = boundarySize;
  }
  
  // Draw cube frame (now accepts container dimensions)
  void drawCubeFrame(Rectangle container) {
    // Calculate scale factor based on container dimensions
    float scaleFactor = min(container.width, container.height) / (boundarySize);
    
    // Disable the default drawing of the box
    noFill();
    noStroke();
    
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
  
  // Draw coordinate system (now accepts container dimensions)
  void drawCoordinateSystem(Rectangle container) {
    // Calculate scale factor based on container dimensions
    float scaleFactor = min(container.width, container.height) / (boundarySize);
    float axisLength = 100 * scaleFactor;
    
    strokeWeight(1);
    
    // X axis (red)
    stroke(255, 0, 0);
    line(0, 0, 0, axisLength, 0, 0);
    pushMatrix();
    translate(axisLength + 10, 0, 0);
    fill(255, 0, 0);
    text("X", 0, 0);
    popMatrix();
    
    // Y axis (green) - Flipped
    stroke(0, 255, 0);
    line(0, 0, 0, 0, -axisLength, 0); // Inverted direction
    pushMatrix();
    translate(0, -axisLength - 10, 0); // Adjusted label position
    fill(0, 255, 0);
    text("Y", 0, 0);
    popMatrix();
    
    // Z axis (blue)
    stroke(0, 0, 255);
    line(0, 0, 0, 0, 0, axisLength);
    pushMatrix();
    translate(0, 0, axisLength + 10);
    fill(0, 0, 255);
    text("Z", 0, 0);
    popMatrix();
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
}