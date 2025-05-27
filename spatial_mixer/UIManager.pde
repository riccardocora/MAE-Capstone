class UIManager {
  ControlP5 cp5;
  float width, height;
  Rectangle container; // Reference to the UI container
  ArrayList<String> messageLog = new ArrayList<String>(); // Log for incoming messages
  int maxLogSize = 50; // Maximum number of messages to store
  int visibleLogLines = 10; // Number of visible lines in the log window
  int logScrollOffset = 0; // Scroll offset for the log window
  DropdownList midiDeviceDropdown;
  
  // Custom slider manager
  SliderManager sliderManager;

  // UI positions relative to container
  float sliderX;

  int sliderMode = 0; // 0 = Mono/Stereo, 1 = Ambi, 2 = Bin

  // Constructor
  UIManager(ControlP5 cp5, float width, float height) {
    this.cp5 = cp5;
    this.width = width;
    this.height = height;
    
    // Initialize slider manager
    sliderManager = new SliderManager();
  }

  // Set the container reference and update positions
  void setContainer(Rectangle container) {
    this.container = container;
    updatePositions();
    
    // Also set container for slider manager
    sliderManager.setContainer(container);
  }
  // Update positions based on container
  void updatePositions() {
    if (container == null) return;

    sliderX = container.x + 20;

    // Update dropdown position
    if (midiDeviceDropdown != null) {
      midiDeviceDropdown
        .setPosition(container.x + 20, container.y + 200)
        .setSize((int)(container.width - 40), 150); // Update size dynamically
    }
    
    // Update custom slider positions
    sliderManager.updatePositions();
  }
  // Setup control sliders
  void setupControls(float radius, float azimuth, float zenith, float boundarySize, ArrayList<String> availableDevices) {
    // Setup custom sliders
    
    // Radius slider
    CustomSlider radiusSlider = sliderManager.addSlider("radius", 50, boundarySize / 2, radius, "Radius");
    radiusSlider.setColors(
      color(100, 100, 120),  // background
      color(150, 150, 200),  // foreground
      color(255, 255, 255),  // active
      color(255, 255, 200)   // label
    );
    radiusSlider.setCallback(new SliderCallback() {
      void onValueChanged(CustomSlider slider, float value) {
        if (selectedSource >= 0 && selectedSource < soundSources.size()) {
          SoundSource source = soundSources.get(selectedSource);
          source.radius = value;
          source.updatePosition(); // Update the position of the sound source

          // Send OSC message for radius
          oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/radius", source.radius);
        }
      }
    });
    
    // Azimuth slider
    CustomSlider azimuthSlider = sliderManager.addSlider("azimuth", -PI, PI, azimuth, "Azimuth");
    azimuthSlider.setColors(
      color(100, 100, 120),  // background
      color(150, 150, 200),  // foreground
      color(255, 255, 255),  // active
      color(255, 255, 200)   // label
    );
    azimuthSlider.setCallback(new SliderCallback() {
      void onValueChanged(CustomSlider slider, float value) {
        if (selectedSource >= 0 && selectedSource < soundSources.size()) {
          SoundSource source = soundSources.get(selectedSource);
          source.azimuth = value;
          source.updatePosition(); // Update the position of the sound source
          println("slider azimuth value: ",source.azimuth);
          // Send OSC message for azimuth
          oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/azimuth", map(source.azimuth, -PI, PI, 0, 1));
        }
      }
    });
    
    // Zenith slider
    CustomSlider zenithSlider = sliderManager.addSlider("zenith", 0, PI, zenith, "Zenith");
    zenithSlider.setColors(
      color(100, 100, 120),  // background
      color(150, 150, 200),  // foreground
      color(255, 255, 255),  // active
      color(255, 255, 200)   // label
    );
    zenithSlider.setCallback(new SliderCallback() {
      void onValueChanged(CustomSlider slider, float value) {
        if (selectedSource >= 0 && selectedSource < soundSources.size()) {
          SoundSource source = soundSources.get(selectedSource);
          source.zenith = value;
          source.updatePosition(); // Update the position of the sound source

          // Send OSC message for zenith
          oscHelper.sendOscMessage("/track/" + (selectedSource + 1) + "/zenith", map(source.zenith, 0, PI, 0, 1));
        }
      }
    });
    
    // Roll slider
    CustomSlider rollSlider = sliderManager.addSlider("roll", -PI, PI, 0, "Roll");
    rollSlider.setColors(
      color(100, 100, 120),  // background
      color(150, 150, 200),  // foreground
      color(255, 255, 255),  // active
      color(255, 255, 200)   // label
    );
    rollSlider.setCallback(new SliderCallback() {
      void onValueChanged(CustomSlider slider, float value) {
        visualizationManager.setCubeRoll(value);
        
        // Also apply rotation to all sound sources
        for(SoundSource source : soundSources) {
          source.setRoll(value);
        }
      }
    });
    
    // Yaw slider
    CustomSlider yawSlider = sliderManager.addSlider("yaw", -PI, PI, 0, "Yaw");
    yawSlider.setColors(
      color(100, 100, 120),  // background
      color(150, 150, 200),  // foreground
      color(255, 255, 255),  // active
      color(255, 255, 200)   // label
    );
    yawSlider.setCallback(new SliderCallback() {
      void onValueChanged(CustomSlider slider, float value) {
        visualizationManager.setCubeYaw(value);
        
        // Also apply rotation to all sound sources
        for(SoundSource source : soundSources) {
          source.setYaw(value);
        }
      }
    });
    
    // Pitch slider
    CustomSlider pitchSlider = sliderManager.addSlider("pitch", -PI, PI, 0, "Pitch");
    pitchSlider.setColors(
      color(100, 100, 120),  // background
      color(150, 150, 200),  // foreground
      color(255, 255, 255),  // active
      color(255, 255, 200)   // label
    );
    pitchSlider.setCallback(new SliderCallback() {
      void onValueChanged(CustomSlider slider, float value) {
        visualizationManager.setCubePitch(value);
        
        // Also apply rotation to all sound sources
        for(SoundSource source : soundSources) {
          source.setPitch(value);
        }
      }
    });
  
    // Add dropdown for MIDI device selection (still using ControlP5 for this)
    midiDeviceDropdown = cp5.addDropdownList("MIDI Device")
      .setPosition(container.x + 20, container.y + 200)
      .setSize((int)(container.width - 40), 150)
      .setBarHeight(30)
      .setItemHeight(20)
      .setColorBackground(color(100, 100, 120))
      .setColorForeground(color(150, 150, 200))
      .setColorActive(color(255, 255, 255))
      .setVisible(false); // Initially hidden

    for (String device : availableDevices) {
      midiDeviceDropdown.addItem(device, device);
    }

    midiDeviceDropdown.onChange(event -> {
      String selectedDevice = event.getController().getLabel();
      println("Selected MIDI Device: " + selectedDevice);
      midiManager.loadMappings("data/midi_mapping.json", selectedDevice);
    });
}

  // Add a message to the log
  void logMessage(String message) {
    messageLog.add(0, message); // Add new message to the top
    if (messageLog.size() > maxLogSize) {
      messageLog.remove(messageLog.size() - 1); // Remove the oldest message if log exceeds max size
    }
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
    
    // Draw custom sliders
    sliderManager.draw();

    // Draw title
    fill(255);
    textAlign(CENTER);
    textSize(20);
    text("Sound Source Controls", container.x + container.width / 2, container.y + 30);

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
    }    // Draw instructions above the log window
    float instructionsY = container.y + container.height - 375;
    fill(200);
    textSize(12);
    textAlign(LEFT);
    text("Instructions:", container.x + 20, instructionsY);
    text("- Use sliders to position sound sources", container.x + 20, instructionsY + 20);
    text("- Press 1-7 to select sources", container.x + 20, instructionsY + 40);
    text("- Press V to toggle view mode", container.x + 20, instructionsY + 60);
    
    fill(255, 220, 220); // Highlight the rotation systems
    text("Rotation Systems:", container.x + 20, instructionsY + 90);
    
    fill(200, 220, 255);
    text("1. Camera Rotation (View only):", container.x + 20, instructionsY + 110);
    text("  • Mouse drag or Roll/Yaw/Pitch sliders", container.x + 20, instructionsY + 125);
    text("  • Only changes view, not actual positions", container.x + 20, instructionsY + 140);
    
    fill(255, 200, 200);
    text("2. Cube Rotation:", container.x + 20, instructionsY + 160);
    text("  • CubeRoll/CubeYaw/CubePitch sliders", container.x + 20, instructionsY + 175);
    text("  • Rotates the cube frame only", container.x + 20, instructionsY + 190);
    
    fill(220, 255, 220);
    text("3. Head Rotation (OSC control):", container.x + 20, instructionsY + 210);
    text("  • /head/roll - Roll (Z-axis)", container.x + 20, instructionsY + 225);
    text("  • /head/pitch - Pitch (X-axis)", container.x + 20, instructionsY + 240);
    text("  • /head/yaw - Yaw (Y-axis)", container.x + 20, instructionsY + 255);
    
    fill(255, 255, 200);
    text("Keyboard Controls:", container.x + 20, instructionsY + 275);
    text("  • V - Toggle 2D/3D view", container.x + 20, instructionsY + 290);
    text("  • R - Reset ALL rotations", container.x + 20, instructionsY + 305);
    text("  • C - Reset camera rotation only", container.x + 20, instructionsY + 320);
    text("  • B - Reset cube rotation only", container.x + 20, instructionsY + 335);

    // Draw message log window
    //drawMessageLog();



    hint(ENABLE_DEPTH_TEST);
  }

  // Draw the message log window
  void drawMessageLog() {
    float logX = container.x + 20;
    float logY = container.y + container.height - 300;
    float logWidth = container.width - 40;
    float logHeight = 250;

    // Draw log background
    fill(30, 35, 45, 200);
    noStroke();
    rect(logX, logY, logWidth, logHeight, 5);

    // Draw log title
    fill(255);
    textAlign(LEFT);
    textSize(14);
    text("Message Log", logX + 10, logY + 20);

    // Draw log messages with scrolling
    textSize(12);
    int startIndex = logScrollOffset;
    int endIndex = min(startIndex + visibleLogLines, messageLog.size());
    for (int i = startIndex; i < endIndex; i++) {
      text(messageLog.get(i), logX + 10, logY + 40 + (i - startIndex) * 15);
    }
  }

  // Handle scrolling for the log window
  void scrollLog(int direction) {
    logScrollOffset = constrain(logScrollOffset + direction, 0, max(0, messageLog.size() - visibleLogLines));
  }
  void setSliderMode(int mode) {
    sliderMode = mode;
    updateSliderVisibility();
  }
  
  void updateSliderVisibility() {
    // Use the slider manager to set visibility
    sliderManager.setSliderMode(sliderMode);
  }

  // Add mouse handling for custom sliders
  void mousePressed() {
    sliderManager.mousePressed();
  }

  void mouseDragged() {
    sliderManager.mouseDragged();
  }

  void mouseReleased() {
    sliderManager.mouseReleased();
  }

  // Update slider values based on the selected source
  void updateSliders(int selectedSourceIndex) {
    if (selectedSourceIndex >= 0 && selectedSourceIndex < soundSources.size()) {
      SoundSource source = soundSources.get(selectedSourceIndex);
      
      // Update position sliders
      CustomSlider radiusSlider = sliderManager.getSlider("radius");
      if (radiusSlider != null) {
        radiusSlider.setValue(source.radius);
      }
      
      CustomSlider azimuthSlider = sliderManager.getSlider("azimuth");
      if (azimuthSlider != null) {
        azimuthSlider.setValue(source.azimuth);
      }
      
      CustomSlider zenithSlider = sliderManager.getSlider("zenith");
      if (zenithSlider != null) {
        zenithSlider.setValue(source.zenith);
      }
      
      // Update rotation sliders
      CustomSlider rollSlider = sliderManager.getSlider("roll");
      if (rollSlider != null) {
        rollSlider.setValue(source.roll);
      }
      
      CustomSlider yawSlider = sliderManager.getSlider("yaw");
      if (yawSlider != null) {
        yawSlider.setValue(source.yaw);
      }
      
      CustomSlider pitchSlider = sliderManager.getSlider("pitch");
      if (pitchSlider != null) {
        pitchSlider.setValue(source.pitch);
      }
    }
  }
  
  // Update a specific slider value
  void updateSliderValue(String sliderName, float value) {
    CustomSlider slider = sliderManager.getSlider(sliderName);
    if (slider != null) {
      slider.setValue(value);
    }
  }

  // Update position sliders (radius, azimuth, zenith) for a source
  void updatePositionSliders(SoundSource source) {
    if (source != null) {
      updateSliderValue("radius", source.radius);
      updateSliderValue("azimuth", source.azimuth);
      updateSliderValue("zenith", source.zenith);
    }
  }
}

