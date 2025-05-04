class UIManager {
  ControlP5 cp5;
  float width, height;
  Rectangle container; // Reference to the UI container
  ArrayList<String> messageLog = new ArrayList<String>(); // Log for incoming messages
  int maxLogSize = 50; // Maximum number of messages to store
  int visibleLogLines = 10; // Number of visible lines in the log window
  int logScrollOffset = 0; // Scroll offset for the log window
  DropdownList midiDeviceDropdown;

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
    if (container == null) return;

    sliderX = container.x + 20;

    // Update ControlP5 element positions dynamically
    String[] sliders = { "radius", "azimuth", "zenith" };
    for (int i = 0; i < sliders.length; i++) {
      if (cp5.getController(sliders[i]) != null) {
        cp5.getController(sliders[i])
           .setPosition(sliderX, container.y + 250 + i * 50);
      }
    }

    // Update dropdown position
    if (midiDeviceDropdown != null) {
      midiDeviceDropdown
        .setPosition(container.x + 20, container.y + 200)
        .setSize((int)(container.width - 40), 150); // Update size dynamically
    }
  }

  // Setup control sliders
  void setupControls(float radius, float azimuth, float zenith, float boundarySize, ArrayList<String> availableDevices) {
    cp5.addSlider("radius")
       .setPosition(sliderX, container.y + 250)
       .setSize((int)(container.width - 40), 30) // Cast width to int
       .setRange(50, boundarySize - 20)
       .setValue(radius)
       .setCaptionLabel("Radius")
       .setColorCaptionLabel(color(255, 255, 200))
       .setColorBackground(color(100, 100, 120))
       .setColorForeground(color(150, 150, 200))
       .setColorActive(color(255, 255, 255))
       .onChange(event -> {
        println("Selected source: " + selectedSource);
         if (selectedSource >= 0 && selectedSource < soundSources.size()) {
           SoundSource source = soundSources.get(selectedSource);
           source.radius = event.getController().getValue();
           source.updatePosition(); // Update the position of the sound source
         }
       });

    cp5.addSlider("azimuth")
       .setPosition(sliderX, container.y + 300)
       .setSize((int)(container.width - 40), 30) // Cast width to int
       .setRange(0, TWO_PI)
       .setValue(azimuth)
       .setCaptionLabel("Azimuth")
       .setColorCaptionLabel(color(255, 255, 200))
       .setColorBackground(color(100, 100, 120))
       .setColorForeground(color(150, 150, 200))
       .setColorActive(color(255, 255, 255))
       .onChange(event -> {
         println("Selected source: " + selectedSource);
         if (selectedSource >= 0 && selectedSource < soundSources.size()) {
           SoundSource source = soundSources.get(selectedSource);
           source.azimuth = event.getController().getValue();
           source.updatePosition(); // Update the position of the sound source
         }
       });

    cp5.addSlider("zenith")
       .setPosition(sliderX, container.y + 350)
       .setSize((int)(container.width - 40), 30) // Cast width to int
       .setRange(0, PI)
       .setValue(zenith)
       .setCaptionLabel("Zenith")
       .setColorCaptionLabel(color(255, 255, 200))
       .setColorBackground(color(100, 100, 120))
       .setColorForeground(color(150, 150, 200))
       .setColorActive(color(255, 255, 255))
       .onChange(event -> {
         println("Selected source: " + selectedSource);
         if (selectedSource >= 0 && selectedSource < soundSources.size()) {
           SoundSource source = soundSources.get(selectedSource);
           source.zenith = event.getController().getValue();
           println("Zenith: " + source.zenith);
           source.updatePosition(); // Update the position of the sound source
         }
       });

    // Add dropdown for MIDI device selection
    midiDeviceDropdown = cp5.addDropdownList("MIDI Device")
      .setPosition(container.x + 20, container.y + 200)
      .setSize((int)(container.width - 40), 150)
      .setBarHeight(30)
      .setItemHeight(20)
      .setColorBackground(color(100, 100, 120))
      .setColorForeground(color(150, 150, 200))
      .setColorActive(color(255, 255, 255));

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
    }

    // Draw instructions above the log window
    float instructionsY = container.y + container.height - 375;
    fill(200);
    textSize(12);
    textAlign(LEFT);
    text("Instructions:", container.x + 20, instructionsY);
    text("- Use sliders to position sound sources", container.x + 20, instructionsY + 20);
    text("- Press 1-7 to select sources", container.x + 20, instructionsY + 40);
    text("- Press V to toggle view mode", container.x + 20, instructionsY + 60);

    // Draw message log window
    drawMessageLog();



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
}
