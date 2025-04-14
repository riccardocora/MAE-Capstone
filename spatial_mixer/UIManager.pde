class UIManager {
  ControlP5 cp5;
  float width, height;
  Rectangle container; // Reference to the UI container
  
  // UI positions relative to container
  float sliderX;
  
  // Constructor
  UIManager(ControlP5 cp5, float width, float height) {
    this.cp5 = cp5;
    this.width = width;
    this.height = height;
  }
  
  // Set the container reference and update positions
  void setContainer(Rectangle container) {
    this.container = container;
    updatePositions();
  }
  
  // Update positions based on container
  void updatePositions() {
    sliderX = container.x + 20;

    // Update ControlP5 element positions dynamically
    String[] sliders = { "radius", "azimuth", "zenith" };
    for (int i = 0; i < sliders.length; i++) {
      if (cp5.getController(sliders[i]) != null) {
        cp5.getController(sliders[i]).setPosition(sliderX, container.y + 250 + i * 50);
      }
    }
  }
  
  // Setup control sliders
  void setupControls(float radius, float azimuth, float zenith, float boundarySize) {
    cp5.addSlider("radius")
       .setPosition(sliderX, container.y + 250)
       .setSize((int)(container.width - 40), 30) // Cast width to int
       .setRange(50, boundarySize - 20)
       .setValue(radius)
       .setCaptionLabel("Radius")
       .setColorCaptionLabel(color(255, 255, 200))
       .setColorBackground(color(100, 100, 120))
       .setColorForeground(color(150, 150, 200))
       .setColorActive(color(255, 255, 255));
       
    cp5.addSlider("azimuth")
       .setPosition(sliderX, container.y + 300)
       .setSize((int)(container.width - 40), 30) // Cast width to int
       .setRange(0, TWO_PI)
       .setValue(azimuth)
       .setCaptionLabel("Azimuth")
       .setColorCaptionLabel(color(255, 255, 200))
       .setColorBackground(color(100, 100, 120))
       .setColorForeground(color(150, 150, 200))
       .setColorActive(color(255, 255, 255));
       
    cp5.addSlider("zenith")
       .setPosition(sliderX, container.y + 350)
       .setSize((int)(container.width - 40), 30) // Cast width to int
       .setRange(0, PI)
       .setValue(zenith)
       .setCaptionLabel("Zenith")
       .setColorCaptionLabel(color(255, 255, 200))
       .setColorBackground(color(100, 100, 120))
       .setColorForeground(color(150, 150, 200))
       .setColorActive(color(255, 255, 255));
  }
  
  // Draw UI panel
  void draw(int numSources, int selectedSource) {
    if (container == null) return;
    
    // Reset to 2D for UI elements
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();
    
    // Draw UI panel background
    fill(40, 45, 55, 200);
    noStroke();
    rect(container.x, container.y, container.width, container.height, 10);
    
    // Draw title
    fill(255);
    textAlign(CENTER);
    textSize(20);
    text("Sound Source Controls", container.x + container.width/2, container.y + 30);
    
    // Draw source selector
    fill(255);
    textAlign(LEFT);
    textSize(16);
    text("Selected Source: " + (selectedSource + 1) + " / " + numSources, container.x + 20, container.y + 70);
    
    // Draw source position info only if valid
    if (numSources > 0 && selectedSource < numSources) {
      SoundSource source = soundSources.get(selectedSource);
      fill(200);
      textSize(14);
      text("Position (x, y, z): ", container.x + 20, container.y + 100);
      text(String.format("(%.1f, %.1f, %.1f)", source.x, source.y, source.z), container.x + 20, container.y + 120);
      text("Spherical Coordinates:", container.x + 20, container.y + 150);
      text(String.format("Radius: %.1f", source.radius), container.x + 20, container.y + 170);
      text(String.format("Azimuth: %.1f° (%.1f rad)", source.azimuth * 180 / PI, source.azimuth), container.x + 20, container.y + 190);
      text(String.format("Zenith: %.1f° (%.1f rad)", source.zenith * 180 / PI, source.zenith), container.x + 20, container.y + 210);
    }
    
    // Draw instructions at the bottom of the UI panel
    float instructionsY = container.y + container.height - 100;
    fill(200);
    textSize(12);
    textAlign(LEFT);
    text("Instructions:", container.x + 20, instructionsY);
    text("- Use sliders to position sound sources", container.x + 20, instructionsY + 20);
    text("- Press 1-7 to select sources", container.x + 20, instructionsY + 40);
    text("- Press V to toggle view mode", container.x + 20, instructionsY + 60);
    
    hint(ENABLE_DEPTH_TEST);
  }
}
