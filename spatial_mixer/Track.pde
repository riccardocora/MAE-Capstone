class Track {
  int trackNumber;
  String trackName;
  float volume = 0.5; // Range 0-1
  float vuLevel = 0;  // Range 0-1
  boolean muted = false;
  boolean soloed = false;

  float x, y; // Position for drawing

  Track(int trackNumber, String trackName, float x, float y) {
    this.trackNumber = trackNumber;
    this.trackName = trackName;
    this.x = x;
    this.y = y;
  }

  void setVolume(float volume) {
    println("Setting volume for track " + trackNumber + " to " + volume);
    this.volume = constrain(volume, 0, 1);
  }

  void setVuLevel(float vuLevel) {
    println("Setting VU level for track " + trackNumber + " to " + vuLevel);
    this.vuLevel = constrain(vuLevel, 0, 1);
  }

  void setMuted(boolean muted) {
    this.muted = muted;
  }

  void setSoloed(boolean soloed) {
    this.soloed = soloed;
  }

  void draw() {
    // Draw fader background
    drawRect(x, y, 50, 200, color(40, 45, 55));

    // Draw VU meter
    float vuHeight = vuLevel * 200;
    drawRect(x + 10, y + 200 - vuHeight, 30, vuHeight, getVuColor());

    // Draw fader handle
    float faderY = y + 200 - (volume * 200);
    drawRect(x + 5, faderY - 5, 40, 10, color(180, 200, 220));

    // Draw track name and indicators
    drawText(trackName, x + 25, y - 10, 15, color(255));
    drawText("M", x + 10, y + 220, 20, muted ? color(255, 0, 0) : color(100));
    drawText("S", x + 40, y + 220, 20, soloed ? color(0, 255, 0) : color(100));
  }

  // Helper to draw a rectangle
  void drawRect(float x, float y, float w, float h, color c) {
    fill(c);
    noStroke();
    rect(x, y, w, h, 5);
  }

  // Helper to draw text
  void drawText(String text, float x, float y, int size, color c) {
    fill(c);
    textAlign(CENTER);
    textSize(size);
    text(text, x, y);
  }

  // Get VU meter color based on level
  color getVuColor() {
    return vuLevel < 0.6 ? color(0, 200, 0) : (vuLevel < 0.8 ? color(255, 255, 0) : color(255, 0, 0));
  }
}
