/**
 * SliderManager class - Manages a collection of custom sliders
 * This replaces the direct use of ControlP5 sliders
 */
class SliderManager {
  // Collection of sliders
  HashMap<String, CustomSlider> sliders;
  
  // UI container reference
  Rectangle container;
  
  // Constructor
  SliderManager() {
    sliders = new HashMap<String, CustomSlider>();
  }
  
  // Set the container and update positions
  void setContainer(Rectangle container) {
    this.container = container;
    updatePositions();
  }
  
  // Add a slider to the collection
  CustomSlider addSlider(String name, float min, float max, float initialValue, String label) {
    // Default position will be updated later
    CustomSlider slider = new CustomSlider(0, 0, 200, 30, min, max, initialValue, label);
    sliders.put(name, slider);
    return slider;
  }
  
  // Get a slider by name
  CustomSlider getSlider(String name) {
    return sliders.get(name);
  }
  
  // Update slider positions based on container
  void updatePositions() {
    if (container == null) return;
    
    float sliderX = container.x + 20;
    float sliderY = container.y + 250;
    float sliderSpacing = 50;
    float sliderWidth = container.width - 40;
    
    int i = 0;
    for (CustomSlider slider : sliders.values()) {
      slider.setPosition(sliderX, sliderY + i * sliderSpacing);
      slider.setSize(sliderWidth, 30);
      i++;
    }
  }
  
  // Draw all visible sliders
  void draw() {
    for (CustomSlider slider : sliders.values()) {
      if (slider.isVisible()) {
        slider.draw();
      }
    }
  }
  
  // Handle mouse pressed event for all sliders
  void mousePressed() {
    for (CustomSlider slider : sliders.values()) {
      if (slider.isVisible()) {
        slider.mousePressed();
      }
    }
  }
  
  // Handle mouse dragged event for all sliders
  void mouseDragged() {
    for (CustomSlider slider : sliders.values()) {
      if (slider.isVisible()) {
        slider.mouseDragged();
      }
    }
  }
  
  // Handle mouse released event for all sliders
  void mouseReleased() {
    for (CustomSlider slider : sliders.values()) {
      if (slider.isVisible()) {
        slider.mouseReleased();
      }
    }
  }
  
  // Set visibility of sliders for different modes
  void setSliderMode(int mode) {
    // Stereo/Mono: show radius, azimuth, zenith; hide roll, yaw, pitch
    boolean showStereo = (mode == 0);
    boolean showAmbi = (mode == 1);
    
    if (sliders.containsKey("radius")) sliders.get("radius").setVisible(showStereo);
    if (sliders.containsKey("azimuth")) sliders.get("azimuth").setVisible(showStereo);
    if (sliders.containsKey("zenith")) sliders.get("zenith").setVisible(showStereo);
    
    if (sliders.containsKey("roll")) sliders.get("roll").setVisible(showAmbi);
    if (sliders.containsKey("yaw")) sliders.get("yaw").setVisible(showAmbi);
    if (sliders.containsKey("pitch")) sliders.get("pitch").setVisible(showAmbi);
  }
}
