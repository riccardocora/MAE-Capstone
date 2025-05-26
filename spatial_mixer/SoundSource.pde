// Sound source types enum
enum SourceType {
  MONO_STEREO,  // 0 - Regular sound source, displayed in spatial view 
  AMBI,         // 1 - Ambisonics source, not displayed in spatial view
  SEND          // 2 - Send source, not displayed in spatial view
}

class SoundSource {
  float radius;      // Distance from center
  float azimuth;     // Horizontal angle (0 to 2π)
  float zenith;      // Vertical angle (0 to π)
  float x, y, z;     // Cartesian coordinates
  color sourceColor;
  float volume = 0;  // Volume level (0-1)
  float vuLevel = 0; // VU level (0-1), updated by parent class
  SourceType type = SourceType.MONO_STEREO;  // Default type is MONO_STEREO
  
  // Source rotation parameters
  float roll = 0;    // Rotation around Z-axis (in radians)
  float yaw = 0;     // Rotation around Y-axis (in radians)
  float pitch = 0;   // Rotation around X-axis (in radians)
  
  // For position tracking  
  float xNormalized, yNormalized;  // Normalized X and Y positions (-1 to 1)
  boolean hasXPosition = false;    // Whether we have received X position
  boolean hasYPosition = false;    // Whether we have received Y position
  boolean positionUpdated = false; // Track if position needs recalculation
  SoundSource(float r, float a, float z) {
    radius = constrain(r, 50, boundarySize - 200);
    azimuth = a;
    zenith = z;
    sourceColor = color(random(100, 255), random(100, 255), random(100, 255));
    type = SourceType.MONO_STEREO; // Default to MONO_STEREO type
    positionUpdated = true; // Mark position for update
    updatePosition();
  }
  
  void updatePosition() {
    println("Updating position for source with radius: " + radius + ", azimuth: " + azimuth + ", zenith: " + zenith);
    println("positionUpdated: " + positionUpdated);
    if (!positionUpdated) return; // Skip if already updated
    
    // First convert spherical to Cartesian coordinates without rotation
    float baseX = radius * sin(zenith) * cos(azimuth);
    float baseZ = radius * sin(zenith) * sin(azimuth);
    float baseY = -radius * cos(zenith); // Flip the Y-axis
    
    // Now apply rotations in order: roll (Z), yaw (Y), pitch (X)
    
    // Create temporary variables to store intermediate results
    float tempX, tempY, tempZ;
    
    // Apply roll (Z-axis rotation)
    tempX = baseX * cos(roll) - baseY * sin(roll);
    tempY = baseX * sin(roll) + baseY * cos(roll);
    baseX = tempX;
    baseY = tempY;
    
    // Apply yaw (Y-axis rotation)
    tempX = baseX * cos(yaw) + baseZ * sin(yaw);
    tempZ = -baseX * sin(yaw) + baseZ * cos(yaw);
    baseX = tempX;
    baseZ = tempZ;
    
    // Apply pitch (X-axis rotation)
    tempY = baseY * cos(pitch) - baseZ * sin(pitch);
    tempZ = baseY * sin(pitch) + baseZ * cos(pitch);
    baseY = tempY;
    baseZ = tempZ;
    
    // Store the final rotated coordinates
    x = baseX;
    y = baseY;
    z = baseZ;
    positionUpdated = true; // Reset flag
  }

  void display(boolean selected, int sourceNumber) {
    // Only display if the source is MONO_STEREO type
    if (type != SourceType.MONO_STEREO) {
      return; // Skip drawing for non-MONO_STEREO sources
    }
    
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
    drawSoundWaves();
   
    // Background circle for contrast
    pushMatrix();
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

  void drawSoundWaves() {
    float baseWaveRadius = 18;
    float outerWaveRadius = baseWaveRadius + (volume * 100); // Scale based on volume
    float innerWaveRadius = vuLevel > 0 ? map(vuLevel, 0, 1, 0, outerWaveRadius) : baseWaveRadius + abs(sin(frameCount * 0.1) * 8);

    // Draw outer wave
    drawWave(outerWaveRadius, 100);

    // Draw inner wave
    drawWave(innerWaveRadius, 200);
  }

  // Helper to draw a wave
  void drawWave(float radius, int alpha) {
    stroke(red(sourceColor), green(sourceColor), blue(sourceColor), alpha);
    strokeWeight(1.5);
    noFill();

    for (int i = 0; i < 3; i++) {
      pushMatrix();
      if (i == 0) rotateX(HALF_PI);
      else if (i == 1) rotateY(HALF_PI);
      else rotateZ(HALF_PI);
      ellipse(0, 0, radius, radius);
      popMatrix();
    }
  }

  // Method to update the volume (called by the parent class)
  void setVolume(float newVolume) {
    volume = constrain(newVolume, 0, 1); // Ensure volume is within range
    positionUpdated = true; // Mark position for update
  }

  // Method to update the VU level (called by the parent class)
  void setVuLevel(float newVuLevel) {
    vuLevel = constrain(newVuLevel, 0, 1); // Ensure VU level is within range
  }
  // Method to update the source type
  void setSourceType(SourceType newType) {
    this.type = newType;
  }
  
  // Method to set the roll rotation (Z-axis)
  void setRoll(float newRoll) {
    roll = newRoll;
    positionUpdated = true; // Mark position for update
    updatePosition();
  }
  
  // Method to set the yaw rotation (Y-axis)
  void setYaw(float newYaw) {
    yaw = newYaw;
    positionUpdated = true; // Mark position for update
    updatePosition();
  }
  
  // Method to set the pitch rotation (X-axis)
  void setPitch(float newPitch) {
    pitch = newPitch;
    positionUpdated = true; // Mark position for update
    updatePosition();
  }
  
  // Method to reset all rotation values to zero
  void resetRotation() {
    roll = 0;
    yaw = 0;
    pitch = 0;
    positionUpdated = true; // Mark position for update
    updatePosition();
  }

  // Method to update the source type using an integer value (for compatibility)
  void setSourceType(int typeValue) {
    switch(typeValue) {
      case 0:
        this.type = SourceType.MONO_STEREO;
        break;
      case 1:
        this.type = SourceType.AMBI;
        break;
      case 2:
        this.type = SourceType.SEND;
        break;
      default:
        this.type = SourceType.MONO_STEREO;
    }
  }

  // Method to update position from X and Y normalized values
  void updateFromCartesian(float xNorm, float yNorm) {
    // Compute azimuth from x, y coordinates
    azimuth = atan2(yNorm, xNorm);
    if (azimuth < 0) azimuth += TWO_PI;
    
    // Compute radius from x, y coordinates (0 to boundarySize/2)
    radius = sqrt(xNorm*xNorm + yNorm*yNorm) * boundarySize/2;
    radius = constrain(radius, 50, 600);
    
    // Update position
    positionUpdated = true; // Mark position for update
    updatePosition();
  }

  // Method to check if this source should be shown in visualization
  boolean isVisualizable() {
    return type == SourceType.MONO_STEREO;
  }
}