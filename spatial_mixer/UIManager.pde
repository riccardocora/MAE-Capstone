/**
 * UIManager class
 * Handles UI elements, controls, and their positioning
 */
class UIManager {
  ControlP5 cp5;
  float width, height;
  
  // UI positions
  float panelX, sliderX;
  
  // Constructor
  UIManager(ControlP5 cp5, float width, float height) {
    this.cp5 = cp5;
    this.width = width;
    this.height = height;
    
    // Calculate initial positions
    updatePositions(width, height);
  }
  
  // Update positions based on window size
  void updatePositions(float newWidth, float newHeight) {
    width = newWidth;
    height = newHeight;

    panelX = width - 300;
    sliderX = panelX + 20;

    // Update ControlP5 element positions dynamically
    String[] sliders = { "radius", "azimuth", "zenith" };
    for (int i = 0; i < sliders.length; i++) {
      if (cp5.getController(sliders[i]) != null) {
        cp5.getController(sliders[i]).setPosition(sliderX, height - 300 + i * 50);
      }
    }
  }
  
  // Setup control sliders
  void setupControls(float radius, float azimuth, float zenith, float boundarySize) {
    cp5.addSlider("radius")
       .setPosition(sliderX, height - 300)
       .setSize(200, 30)
       .setRange(50, boundarySize - 20)
       .setValue(radius)
       .setCaptionLabel("Radius")
       .setColorCaptionLabel(color(255, 255, 200)) // Brighter text color
       .setColorBackground(color(100, 100, 120))  // Brighter background
       .setColorForeground(color(150, 150, 200)) // Brighter foreground
       .setColorActive(color(255, 255, 255));    // Bright active color
       
    cp5.addSlider("azimuth")
       .setPosition(sliderX, height - 250)
       .setSize(200, 30)
       .setRange(0, TWO_PI)
       .setValue(azimuth)
       .setCaptionLabel("Azimuth")
       .setColorCaptionLabel(color(255, 255, 200)) // Brighter text color
       .setColorBackground(color(100, 100, 120))  // Brighter background
       .setColorForeground(color(150, 150, 200)) // Brighter foreground
       .setColorActive(color(255, 255, 255));    // Bright active color
       
    cp5.addSlider("zenith")
       .setPosition(sliderX, height - 200)
       .setSize(200, 30)
       .setRange(0, PI)
       .setValue(zenith)
       .setCaptionLabel("Zenith")
       .setColorCaptionLabel(color(255, 255, 200)) // Brighter text color
       .setColorBackground(color(100, 100, 120))  // Brighter background
       .setColorForeground(color(150, 150, 200)) // Brighter foreground
       .setColorActive(color(255, 255, 255));    // Bright active color
  }
  
  // Draw UI panel
  void draw(int numSources, int selectedSource) {
    // Reset to 2D for UI elements
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();
    
    // Avoid recalculating panelY multiple times
    float panelY = 100;
    
    // Draw UI panel background
    fill(40, 45, 55, 200);
    noStroke();
    rect(panelX, panelY, 280, height - panelY - 20, 10);
    
    // Draw title
    fill(255);
    textAlign(CENTER);
    textSize(20);
    text("Sound Source Controls", panelX + 140, panelY + 30);
    
    // Draw source selector
    fill(255);
    textAlign(LEFT);
    textSize(16);
    text("Selected Source: " + (selectedSource + 1) + " / " + numSources, panelX + 20, panelY + 70);
    
    // Draw source position info only if valid
    if (numSources > 0 && selectedSource < numSources) {
      SoundSource source = soundSources.get(selectedSource);
      fill(200);
      textSize(14);
      text("Position (x, y, z): ", panelX + 20, panelY + 100);
      text(String.format("(%.1f, %.1f, %.1f)", source.x, source.y, source.z), panelX + 20, panelY + 120);
      text("Spherical Coordinates:", panelX + 20, panelY + 150);
      text(String.format("Radius: %.1f", source.radius), panelX + 20, panelY + 170);
      text(String.format("Azimuth: %.1f° (%.1f rad)", source.azimuth * 180 / PI, source.azimuth), panelX + 20, panelY + 190);
      text(String.format("Zenith: %.1f° (%.1f rad)", source.zenith * 180 / PI, source.zenith), panelX + 20, panelY + 210);
    }
  
    // Draw sliders below spherical coordinates
    drawSliders(panelX + 20, panelY + 240);
    
    // Draw instructions below sliders
    drawInstructions(panelX + 20, panelY + 400);
    
    hint(ENABLE_DEPTH_TEST);
  }
  
  // Draw sliders
  void drawSliders(float x, float y) {
    fill(255);
    textSize(14);
    textAlign(LEFT);
  
    if (cp5.getController("radius") != null) {
      cp5.getController("radius").setPosition(x, y);
    }
  
    if (cp5.getController("azimuth") != null) {
      cp5.getController("azimuth").setPosition(x, y + 50);
    }
  
    if (cp5.getController("zenith") != null) {
      cp5.getController("zenith").setPosition(x, y + 100);
    }
  }
  
  void drawInstructions(float x, float y) {
    fill(200);
    textSize(12);
    textAlign(LEFT);
    text("Instructions:", x, y);
    text("- Use sliders to position sound sources", x, y + 20);
    text("- Sound sources auto-sync with Reaper tracks", x, y + 40);
    text("- Faders show track volumes and VU meters", x, y + 60);
  }
}
