class SoundSource {
  float radius;      // Distance from center
  float azimuth;     // Horizontal angle (0 to 2π)
  float zenith;      // Vertical angle (0 to π)
  float x, y, z;     // Cartesian coordinates
  color sourceColor;
  float volume = 0;  // Volume level (0-1)
  float vuLevel = 0; // VU level (0-1), updated by parent class

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
    positionUpdated = true; // Mark position for update
    updatePosition();
  }
  

  void updatePosition() {
    if (!positionUpdated) return; // Skip if already updated
    // Convert spherical to Cartesian coordinates
    x = radius * sin(zenith) * cos(azimuth);
    z = radius * sin(zenith) * sin(azimuth);
    y = -radius * cos(zenith); // Flip the Y-axis
    positionUpdated = false; // Reset flag
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
}






