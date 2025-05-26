/**
 * CentralHead class
 * 
 * Represents the central head in the 3D space with independent rotation
 * parameters. The head can be rotated while the cube and sources remain still.
 */
class CentralHead {
  float headSize;  // Size of the head (sphere radius)
  float axisLength;  // Length of the coordinate axes
  
  // Rotation parameters for the head (independent of view rotation)
  float roll = 0;  // Rotation around Z-axis
  float yaw = 0;   // Rotation around Y-axis
  float pitch = 0; // Rotation around X-axis
  
  // Constructor
  CentralHead(float headSize) {
    this.headSize = headSize;
    this.axisLength = headSize * 2;  // Axes are twice the head size
  }
  
  // Update rotation values (to be called by OSC handlers)
  void setRoll(float roll) {
    this.roll = roll;
  }
  
  void setYaw(float yaw) {
    this.yaw = yaw;
  }
  
  void setPitch(float pitch) {
    this.pitch = pitch;
  }
  
  // Reset rotation values
  void resetRotation() {
    roll = 0;
    yaw = 0;
    pitch = 0;
  }
  
  // Draw the head with its own rotation
  void draw() {
    pushMatrix();
    
    // Apply head-specific rotations
    rotateZ(roll);  // Roll (Z-axis)
    rotateY(yaw);   // Yaw (Y-axis)
    rotateX(pitch); // Pitch (X-axis)
    
    // Draw the central head (sphere)
    noStroke();
    fill(220, 190, 170);
    sphere(headSize);
    
    // Draw the coordinate axes - these will rotate with the head
    drawAxes();
    
    popMatrix();
  }
  
  // Draw coordinate axes that rotate with the head
  private void drawAxes() {
    strokeWeight(2);
    
    // X-axis (red)
    stroke(255, 0, 0);
    line(0, 0, 0, axisLength, 0, 0);
    
    // Y-axis (green)
    stroke(0, 255, 0);
    line(0, 0, 0, 0, -axisLength, 0);
    
    // Z-axis (blue)
    stroke(0, 0, 255);
    line(0, 0, 0, 0, 0, axisLength);
  }
}
