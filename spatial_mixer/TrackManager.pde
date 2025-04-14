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
    
    // Position master track
    float trackSpacing = 70;
    float initialX = container.x + 20;
    float trackY = container.y + 15;
    
    masterTrack.setPosition(initialX, trackY);
    
    // Position other tracks
    for (int i = 0; i < tracks.size(); i++) {
      tracks.get(i).setPosition(initialX + (i + 1) * trackSpacing, trackY);
    }
  }
  
  void draw() {
    if (container == null) return;
    
    // Draw container background
    fill(40, 45, 55, 200);
    noStroke();
    rect(container.x, container.y, container.width, container.height, 10);
    
    // Draw title
    fill(255);
    textAlign(LEFT);
    textSize(14);
    text("Mixer Channels", container.x + 10, container.y + 15);
    
    // Draw master track
    masterTrack.draw();
    
    // Draw other tracks
    for (Track track : tracks) {
      track.draw();
    }
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
  
  // Track dimensions
  float width = 60;
  float height = 120;
  
  Track(int id, String name, float x, float y) {
    this.id = id;
    this.name = name;
    this.x = x;
    this.y = y;
  }
  
  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  void setVolume(float volume) {
    this.volume = constrain(volume, 0, 1);
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
  
  void draw() {
    // Draw track background
    noStroke();
    fill(50, 55, 65);
    rect(x, y, width, height, 5);
    
    // Draw track label
    fill(255);
    textAlign(CENTER);
    textSize(12);
    text(name, x + width/2, y + 15);
    
    // Draw volume fader background
    fill(30, 35, 45);
    rect(x + 10, y + 25, 20, 80, 3);
    
    // Draw VU meter (behind volume fader)
    if (!muted) {
      // Gradient for VU meter from green to yellow to red
      float vuHeight = vuLevel * 80;
      for (int i = 0; i < vuHeight; i++) {
        float position = i / 80.0;
        // Green to yellow to red gradient
        color meterColor = lerpColor(
          lerpColor(color(0, 200, 0), color(255, 255, 0), min(position * 2, 1)),
          color(255, 0, 0), 
          max((position - 0.5) * 2, 0)
        );
        stroke(meterColor);
        line(x + 12, y + 105 - i, x + 28, y + 105 - i);
      }
    }
    
    // Draw volume fader
    fill(muted ? color(100, 0, 0) : (soloed ? color(0, 100, 0) : color(180)));
    float faderY = y + 105 - (volume * 80);
    rect(x + 8, faderY - 3, 24, 6, 2);
    
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
}

