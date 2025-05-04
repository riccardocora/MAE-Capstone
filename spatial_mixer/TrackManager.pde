/**
 * TrackManager class
 * Manages all tracks within the track controls area
 */
class TrackManager {
  ArrayList<Track> tracks;
  Track masterTrack;
  Rectangle container;

  TrackManager(ArrayList<Track> tracks, Track masterTrack) {
    this.tracks = tracks;
    this.masterTrack = masterTrack;
  }

  void setContainer(Rectangle container) {
    this.container = container;
    updateTrackPositions();
  }

  void updateTrackPositions() {
    if (container == null) return;

    // Calculate track height based on container height with padding
    float trackHeight = container.height - 20; // Subtract 10 padding from top and bottom
    float trackSpacing = 70;
    float initialX = container.x + 20;
    float trackY = container.y + 10; // Add top padding

    masterTrack.setPosition(initialX, trackY);
    masterTrack.setHeight(trackHeight); // Set height for master track

    // Position other tracks
    for (int i = 0; i < tracks.size(); i++) {
      tracks.get(i).setPosition(initialX + (i + 1) * trackSpacing, trackY);
      tracks.get(i).setHeight(trackHeight); // Set height for each track
    }
  }

  void draw() {
    if (container == null) return;

    drawContainerBackground(container, "Mixer Channels");

    // Draw master track
    masterTrack.draw();

    // Draw other tracks
    for (Track track : tracks) {
      track.draw();
    }
  }

  void handleMousePressed(float mouseX, float mouseY) {
    // Check if the mouse is over any track's fader
    for (Track track : tracks) {
      if (track.isMouseOverFader(mouseX, mouseY)) {
        track.startDragging(mouseY);
      }
    }

    // Check for master track
    if (masterTrack.isMouseOverFader(mouseX, mouseY)) {
      masterTrack.startDragging(mouseY);
    }
  }

  void handleMouseDragged(float mouseX, float mouseY) {
    // Update the fader position for any track being dragged
    for (Track track : tracks) {
      if (track.isDragging) {
        track.updateFader(mouseY);
      }
    }

    // Update master track if being dragged
    if (masterTrack.isDragging) {
      masterTrack.updateFader(mouseY);
    }
  }

  void handleMouseReleased() {
    // Stop dragging for all tracks
    for (Track track : tracks) {
      track.stopDragging();
    }

    // Stop dragging for master track
    masterTrack.stopDragging();
  }

  // Helper method to draw container background and title
  void drawContainerBackground(Rectangle container, String title) {
    fill(40, 45, 55, 200);
    noStroke();
    rect(container.x, container.y, container.width, container.height, 10);

    fill(255);
    textAlign(LEFT);
    textSize(14);
    text(title, container.x + 10, container.y + 15);
  }
}

class Track {
  int id;
  String name;
  float x, y;
  float volume = 0.7; // Default volume (0.0 to 1.0)
  float vuLevel = 0.0; // VU meter level (0.0 to 1.0)
  boolean muted = false;
  boolean soloed = false;
  boolean isDragging = false; // Whether the fader is being dragged

  // Track dimensions
  float width = 60;
  float height = 120;

  OscHelper oscHelper; // Reference to the OscHelper instance

  Track(int id, String name, float x, float y, OscHelper oscHelper) {
    this.id = id;
    this.name = name;
    this.x = x;
    this.y = y;
    this.oscHelper = oscHelper; // Assign the OscHelper instance
  }

  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void setVolume(float volume) {
    this.volume = constrain(volume, 0, 1);
    sendOscVolume(); // Send OSC message when volume changes
  }

  void setVuLevel(float level) {
    this.vuLevel = constrain(level, 0, 1);
  }

  void setMuted(boolean muted) {
    this.muted = muted;
  }

  void setSoloed(boolean soloed) {
    this.soloed = soloed;
  }

  void setHeight(float height) {
    this.height = height;
  }

  void draw() {
    // Draw track background
    noStroke();
    fill(50, 55, 65);
    rect(x, y, width, height, 5);

    // Draw track label
    fill(255);
    textAlign(CENTER);
    textSize(12);
    text(name, x + width / 2, y + 15);

    // Draw volume fader background
    fill(30, 35, 45);
    float faderBgX = x + (width - 20) / 2; // Center the fader background horizontally
    rect(faderBgX, y + 25, 20, height - 50, 3);

    // Draw VU meter (behind volume fader)
    if (!muted) {
      float vuHeight = vuLevel * (height - 50);
      for (int i = 0; i < vuHeight; i++) {
        float position = i / (height - 50.0);
        color meterColor = lerpColor(
          lerpColor(color(0, 200, 0), color(255, 255, 0), min(position * 2, 1)),
          color(255, 0, 0),
          max((position - 0.5) * 2, 0)
        );
        stroke(meterColor);
        line(faderBgX + 2, y + height - 25 - i, faderBgX + 18, y + height - 25 - i);
      }
    }

    // Draw volume fader
    fill(muted ? color(100, 0, 0) : (soloed ? color(0, 100, 0) : color(180)));
    float faderY = y + height - 25 - (volume * (height - 50));
    rect(faderBgX - 2, faderY - 3, 24, 6, 2);

    // Draw mute/solo buttons
    fill(muted ? color(255, 0, 0) : color(100));
    rect(x + 10, y + height - 25, 15, 15, 3);
    fill(255);
    textSize(10);
    text("M", x + 18, y + height - 14);

    fill(soloed ? color(0, 255, 0) : color(100));
    rect(x + width - 25, y + height - 25, 15, 15, 3);
    fill(255);
    text("S", x + width - 17, y + height - 14);
  }

  boolean isMouseOverFader(float mouseX, float mouseY) {
    float faderBgX = x + (width - 20) / 2;
    float faderY = y + height - 25 - (volume * (height - 50));
    return mouseX >= faderBgX - 2 && mouseX <= faderBgX + 22 && mouseY >= faderY - 10 && mouseY <= faderY + 10;
  }

  void startDragging(float mouseY) {
    isDragging = true;
    updateFader(mouseY);
  }

  void updateFader(float mouseY) {
    float faderHeight = height - 50;
    float newVolume = constrain((y + height - 25 - mouseY) / faderHeight, 0, 1);
    setVolume(newVolume);
  }

  void stopDragging() {
    isDragging = false;
  }

  void sendOscVolume() {
    if (oscHelper != null) {
      oscHelper.sendOscVolume(id, volume); // Use OscHelper to send the volume message
    } else {
      println("Error: OscHelper is not initialized.");
    }
  }
}