/**
 * CustomSlider class to replace ControlP5 sliders
 * Features:
 * - Simple but customizable slider control
 * - Draggable slider knob
 * - Value label display
 * - Support for min/max range
 * - Customizable colors
 */
class CustomSlider {
  // Configuration
  float x, y;                // Position
  float width, height;       // Dimensions
  float minValue, maxValue;  // Range
  float value;               // Current value
  String label;              // Label text
  
  // Styling
  color backgroundColor = color(100, 100, 120);      // Background color
  color foregroundColor = color(150, 150, 200);      // Foreground color (track)
  color activeColor = color(255, 255, 255);          // Active color (when dragging)
  color labelColor = color(255, 255, 200);           // Label text color
  color valueTextColor = color(255);                 // Value text color
    // State
  boolean isDragging = false;                        // Whether the slider is being dragged
  boolean isHovering = false;                        // Whether the mouse is hovering over the slider
  boolean suppressCallback = false;                  // Flag to suppress callback during programmatic updates
  
  // Callback
  SliderCallback callback;                           // Callback function for value changes
  
  // Constructor
  CustomSlider(float x, float y, float width, float height, float minValue, float maxValue, float initialValue, String label) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.minValue = minValue;
    this.maxValue = maxValue;
    this.value = initialValue;
    this.label = label;
  }
  
  // Set callback function for when the value changes
  void setCallback(SliderCallback callback) {
    this.callback = callback;
  }
  
  // Set colors
  void setColors(color backgroundColor, color foregroundColor, color activeColor, color labelColor) {
    this.backgroundColor = backgroundColor;
    this.foregroundColor = foregroundColor;
    this.activeColor = activeColor;
    this.labelColor = labelColor;
  }
  
  // Update position (useful for layout changes)
  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  // Update size
  void setSize(float width, float height) {
    this.width = width;
    this.height = height;
  }
    // Set the current value
  void setValue(float value) {
    this.value = constrain(value, minValue, maxValue);
    
    // Call the callback if set and not suppressed
    if (callback != null && !suppressCallback) {
      callback.onValueChanged(this, this.value);
    }
  }
  
  // Set value without triggering callback (for programmatic updates)
  void setValueSilent(float value) {
    this.value = constrain(value, minValue, maxValue);
  }
  
  // Get the current value
  float getValue() {
    return value;
  }
  
  // Draw the slider
  void draw() {
    // Calculate the position of the knob
    float knobX = map(value, minValue, maxValue, x, x + width - height);
    
    // Check for hover
    isHovering = mouseX >= x && mouseX <= x + width && 
                mouseY >= y && mouseY <= y + height;
    
    // Draw slider track (background)
    noStroke();
    fill(backgroundColor);
    rect(x, y, width, height, height/2);
    
    // Draw filled portion (foreground)
    fill(isDragging ? activeColor : foregroundColor);
    float filledWidth = map(value, minValue, maxValue, 0, width);
    rect(x, y, filledWidth, height, height/2);
    
    // Draw the knob
    fill(isDragging ? activeColor : isHovering ? color(200, 200, 255) : color(200));
    ellipse(knobX + height/2, y + height/2, height * 1.2, height * 1.2);
    
    // Draw label
    fill(labelColor);
    textAlign(LEFT, CENTER);
    textSize(height );
    text(label, x, y - height * 0.7);
    
    // Draw value
    String displayValue;
    // Format the value differently based on the range
    if (maxValue - minValue <= 10) {
      // For small ranges, show more decimal places
      displayValue = nf(value, 0, 2);
    } else {
      // For larger ranges, show fewer decimal places
      displayValue = nf(value, 0, 1);
    }
      // For angle sliders, show degrees
    if (label.toLowerCase().contains("roll") || 
        label.toLowerCase().contains("yaw") || 
        label.toLowerCase().contains("pitch") || 
        label.toLowerCase().contains("azimuth") || 
        label.toLowerCase().contains("zenith")) {
      // Convert radians to degrees for display
      if (minValue == -PI && maxValue == PI) {
        float degrees = degrees(value);
        displayValue = nf(degrees, 0, 1) + "°";
      } else if (minValue == 0 && maxValue == TWO_PI) {
        float degrees = degrees(value);
        displayValue = nf(degrees, 0, 1) + "°";
      } else if (minValue == 0 && maxValue == PI) {
        float degrees = degrees(value);
        displayValue = nf(degrees, 0, 1) + "°";
      } else if (minValue == -PI/2 && maxValue == PI/2) {
        float degrees = degrees(value);
        displayValue = nf(degrees, 0, 1) + "°";
      }
    }
    
    fill(valueTextColor);
    textAlign(RIGHT, CENTER);
    text(displayValue, x + width, y - height * 0.7);
  }
  
  // Handle mouse pressed event
  void mousePressed() {
    if (mouseX >= x && mouseX <= x + width && 
        mouseY >= y && mouseY <= y + height) {
      isDragging = true;
      // Update value based on mouse position
      updateValueFromMouse();
    }
  }
  
  // Handle mouse dragged event
  void mouseDragged() {
    if (isDragging) {
      // Update value based on new mouse position
      updateValueFromMouse();
    }
  }
  
  // Handle mouse released event
  void mouseReleased() {
    isDragging = false;
  }
  
  // Update the value based on mouse X position
  private void updateValueFromMouse() {
    float newValue = map(mouseX, x, x + width, minValue, maxValue);
    setValue(constrain(newValue, minValue, maxValue));
  }
  
  // Visibility toggle
  boolean visible = true;
  
  void setVisible(boolean visible) {
    this.visible = visible;
  }
  
  boolean isVisible() {
    return visible;
  }
}

// Interface for slider callbacks
interface SliderCallback {
  void onValueChanged(CustomSlider slider, float value);
}
