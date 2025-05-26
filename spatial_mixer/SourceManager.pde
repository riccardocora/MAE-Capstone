/**
 * SourceManager class
 * Manages the source controls area and displays track rectangles with source type indicators.
 * Now includes scrolling functionality.
 */
class SourceManager {
  Rectangle container; // Reference to the sourceControlsArea
  ArrayList<TrackSource> trackSources; // List of track sources
  ControlP5 cp5; // ControlP5 instance for UI elements
  Button addSourceButton; // Button to add new track source
  int selectedSource = 0; // Currently selected source index
  
  // Scrollbar properties
  Scrollbar scrollbar;
  float scrollY = 0; // Current scroll position
  float contentHeight = 0; // Total height of all content
  float visibleHeight = 0; // Visible height of the container
  
  // Constants
  float TRACK_HEIGHT = 70; // Height of each track rectangle
  float TRACK_SPACING = 10; // Spacing between rectangles
  float SCROLLBAR_WIDTH = 15; // Width of scrollbar
  
  // Constructor
  SourceManager(ControlP5 cp5, int numTracks) {
    this.cp5 = cp5;
    trackSources = new ArrayList<TrackSource>();

    // Initialize track sources
    for (int i = 0; i < numTracks; i++) {
      trackSources.add(new TrackSource("Track " + (i + 1), i, cp5, this));
    }

    // Add button (position will be set in setContainer)
    addSourceButton = cp5.addButton("Add Source")
      .setLabel("Add Source")
      .onClick(e -> addSourceCallback());
  }

  // Set the container reference and initialize scrollbar
  void setContainer(Rectangle container) {
    this.container = container;
    visibleHeight = container.height;

    // Update or recreate scrollbar with new height
    if (scrollbar == null) {
      scrollbar = new Scrollbar(
        (int)(container.x + container.width - SCROLLBAR_WIDTH), 
        (int)container.y, 
        (int)SCROLLBAR_WIDTH, 
        (int)container.height, 
        20 // Initial slider size, will be adjusted later
      );
    } else {
      scrollbar.x = (int)(container.x + container.width - SCROLLBAR_WIDTH);
      scrollbar.y = (int)container.y;
      scrollbar.width = (int)SCROLLBAR_WIDTH;
      scrollbar.height = (int)container.height;
    }

    updateTrackPositions();
    updateScrollbar();

    // Place the button at the bottom of the visible area
    if (addSourceButton != null && container != null) {
      addSourceButton.setPosition(container.x + 20, container.y + container.height - 50)
                     .setSize((int)container.width - 40 - (int)SCROLLBAR_WIDTH, 30);
    }
  }
  
  // Update scrollbar properties based on content
  void updateScrollbar() {
    if (container == null) return;
    
    // Calculate total content height
    contentHeight = trackSources.size() * (TRACK_HEIGHT + TRACK_SPACING) + TRACK_SPACING + 50; // +50 for button area
    
    // Only show scrollbar if content exceeds visible area
    boolean needsScrollbar = contentHeight > visibleHeight;
    
    if (needsScrollbar) {
      // Calculate thumb size relative to content
      float thumbRatio = min(1.0, visibleHeight / contentHeight);
      float thumbSize = max(20, visibleHeight * thumbRatio);
      
      scrollbar.setThumbSize((int)thumbSize);
      scrollbar.setRange(0, contentHeight - visibleHeight);
      
      // Ensure scroll position is within valid range
      scrollY = constrain(scrollY, 0, contentHeight - visibleHeight);
    } else {
      scrollY = 0;
    }
  }

  // Callback for the add source button
  void addSourceCallback() {
    addSource(); // Calls the global addSource() in the main sketch
  }

  // Add a new track source
  void addTrackSource() {
    int idx = trackSources.size();
    trackSources.add(new TrackSource("Track " + (idx + 1), idx, cp5, this));
    updateTrackPositions();
    updateScrollbar();
  }
  // Remove a track source
  void removeTrackSource(int idx) {
    if (idx >= 0 && idx < trackSources.size()) {
      // Remove UI elements for this track
      cp5.remove("TrackName_" + idx);
      // Remove the track source
      trackSources.remove(idx);
      // Update indices and names for remaining track sources
      for (int i = idx; i < trackSources.size(); i++) {
        trackSources.get(i).index = i;
        trackSources.get(i).name = "Track " + (i + 1);
        trackSources.get(i).nameField.setText(trackSources.get(i).name);
      }
      updateTrackPositions();
      updateScrollbar();
    }
  }
  // Update positions of track rectangles
  void updateTrackPositions() {
    if (container == null) return;

    float yOffset = container.y + TRACK_SPACING - scrollY; // Apply scroll offset

    for (int i = 0; i < trackSources.size(); i++) {
      TrackSource trackSource = trackSources.get(i);

      // Set rectangle position
      trackSource.x = container.x + 10;
      trackSource.y = yOffset;
      trackSource.width = container.width - 20 - SCROLLBAR_WIDTH;
      trackSource.height = TRACK_HEIGHT;

      // Update the position of the text field
      trackSource.nameField.setPosition(trackSource.x + 10, trackSource.y + 35);

      yOffset += TRACK_HEIGHT + TRACK_SPACING;
    }

    // Move the button - keep it fixed at the bottom of the container
    if (addSourceButton != null && container != null) {
      addSourceButton.setPosition(container.x + 20, container.y + container.height - 50)
                     .setSize((int)container.width - 40 - (int)SCROLLBAR_WIDTH, 30);
    }
  }
  
  // Handle scrolling
  void mouseWheel(MouseEvent event) {
    if (isMouseOverContainer()) {
      // Adjust scroll position based on wheel delta
      float delta = event.getCount() * 15; // Adjust sensitivity as needed
      scrollY += delta;
      scrollY = constrain(scrollY, 0, max(0, contentHeight - visibleHeight));
      updateTrackPositions();
    }
  }
  
  // Check if mouse is over the container
  boolean isMouseOverContainer() {
    return mouseX >= container.x && mouseX <= container.x + container.width &&
           mouseY >= container.y && mouseY <= container.y + container.height;
  }

  // Draw the source controls area
  void draw() {
    if (container == null) return; // Ensure container is valid

    // Draw the background of the source controls area (fills the whole container)
    fill(40, 45, 55, 200);
    noStroke();
    rect(container.x, container.y, container.width, container.height, 10);

    // Save current drawing state
    pushMatrix();

    // Create a clipping region for the container (for tracks only)
    clip((int)container.x, (int)container.y, (int)container.width, (int)container.height);    // Draw each track source rectangle
    for (TrackSource trackSource : trackSources) {
      // Only draw if within visible area (with some margin)
      if (trackSource.y + trackSource.height >= container.y - TRACK_HEIGHT && 
          trackSource.y <= container.y + container.height + TRACK_HEIGHT) {
        // Check if this is the selected source
        boolean isSelected = (trackSource.index == selectedSource);
        trackSource.draw(isSelected);
      }
      
      // Update visibility of text field based on visibility
      boolean isVisible = trackSource.y + trackSource.height >= container.y && 
                         trackSource.y <= container.y + container.height;
      trackSource.nameField.setVisible(isVisible);
    }

    // Reset the clipping region
    noClip();

    // Draw the scrollbar
    scrollbar.update();
    scrollbar.display();

    // Update scroll position based on scrollbar
    float newScrollY = scrollbar.getPos();
    if (newScrollY != scrollY) {
      scrollY = newScrollY;
      updateTrackPositions();
    }

    // Restore previous drawing state
    popMatrix();

    // Button is drawn by ControlP5
  }
  
  // Handle mouse events for scrollbar
  void mousePressed() {
    scrollbar.mousePressed();
  }
  
  void mouseDragged() {
    scrollbar.mouseDragged();
  }
  
  void mouseReleased() {
    scrollbar.mouseReleased();
  }

  void handleRenameTrack(int idx, String newName) {
    // Call the global renameSource in the main sketch
    renameSource(idx, newName);
  }

  void renameTrack(int idx, String newName) {
    if (idx >= 0 && idx < trackSources.size()) {
      trackSources.get(idx).name = newName;
      trackSources.get(idx).nameField.setText(newName);
      // Also update the corresponding Track in TrackManager
      if (idx < trackManager.tracks.size()) {
        trackManager.tracks.get(idx).name = newName;
      }
    }
  }  // Check if there's already an Ambi source (mode 1)
  boolean hasAmbiSource() {
    for (TrackSource source : trackSources) {
      if (source.mode == 1) { // 1 = Ambi
        return true;
      }
    }
    return false;
  }
    // Get the index of the current Ambi source, or -1 if none exists
  int getAmbiSourceIndex() {
    for (int i = 0; i < trackSources.size(); i++) {
      if (trackSources.get(i).mode == 1) { // 1 = Ambi
        return i;
      }
    }
    return -1; // No Ambi source found
  }
  
  void changeSourceMode(int idx, int newMode) {
    // Check if we're trying to set a source to Ambi mode
    if (newMode == 1) { // 1 = Ambi
      // Check if there's already an Ambi source that's not this one
      int currentAmbiIdx = getAmbiSourceIndex();
      if (currentAmbiIdx >= 0 && currentAmbiIdx != idx) {
        println("Cannot have multiple Ambi sources. Source " + currentAmbiIdx + 
                " is already in Ambi mode.");
                
        // Display a temporary notification
        uiManager.logMessage("ERROR: Only one Ambi source allowed. Source " + currentAmbiIdx + 
                " is already in Ambi mode.");
        return; // Exit without changing the mode
      }
    }
    
    // Update the mode of the specified track source
    if (idx >= 0 && idx < trackSources.size()) {
      trackSources.get(idx).mode = newMode;
      // Notify the main sketch/UI to update visible sliders
      onSourceModeChange(idx, newMode);
    }
  }
}

/**
 * TrackSource class
 * Represents a single track's rectangle and status display.
 */
class TrackSource {
  SourceManager parent;
  String name; // Track name
  int index; // Unique index for this track source
  float x, y, width, height; // Rectangle dimensions
  Textfield nameField; // Textfield for track name
  int mode = 0; // 0 = Mono/Stereo, 1 = Ambi, 2 = Send
  
  // Source type names
  String[] modeNames = {"Mono/Stereo", "Ambi", "Send"};
  color[] modeColors = {color(50, 200, 50), color(50, 50, 200), color(200, 50, 50)};

  // Constructor
  TrackSource(String name, int index, ControlP5 cp5, SourceManager parent) {
    this.name = name;
    this.index = index;
    this.parent = parent;
    
    // Create the textfield for track name
    nameField = cp5.addTextfield("TrackName_" + index)
                  .setText(name)
                  .setPosition(x + 10, y + 35) // Will be updated in updateTrackPositions
                  .setSize(80, 20)
                  .onChange(e -> parent.handleRenameTrack(index, nameField.getText()));
  }  // Draw the track rectangle
  void draw(boolean isSelected) {
    // Highlight selected source with yellow background
    if (isSelected) {
      fill(225, 140, 60);// Yellow highlight for selected track
    } else {
      fill(60, 65, 75);   // Regular color for non-selected tracks
    }
    
    stroke(100, 110, 130);
    strokeWeight(2);
    rect(x, y, width, height, 5);

    // Draw source type indicator circle
    float circleX = x + width - 30;
    float circleY = y + 20;
    float circleSize = 15;
    
    // Draw circle with color based on current mode
    fill(modeColors[mode]);
    stroke(255);
    strokeWeight(1);
    ellipse(circleX, circleY, circleSize, circleSize);
    
    // Draw mode name
    fill(255);
    textAlign(RIGHT);
    textSize(12);
    text(modeNames[mode], circleX - 10, circleY + 5);
    textAlign(LEFT);  // Reset text alignment
    
    // Draw the textfield (ControlP5 handles drawing)
    // Optionally, hide/show based on visibility
    nameField.setVisible(y + height >= parent.container.y && y <= parent.container.y + parent.container.height);
  }
}

/**
 * Scrollbar class
 * A simple vertical scrollbar for scrolling content
 */
class Scrollbar {
  int x, y;               // Position
  int width, height;      // Dimensions
  int thumbSize;          // Size of thumb
  float pos;              // Current position (0 to max range)
  float posMin, posMax;   // Range
  boolean over;           // Is the mouse over the scrollbar?
  boolean locked;         // Is the scrollbar thumb being dragged?
  float ratio;            // Ratio of visible area to total content

  Scrollbar(int x, int y, int width, int height, int thumbSize) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.thumbSize = thumbSize;
    posMin = 0;
    posMax = 0;  // Will be set by setRange()
    pos = 0;
    over = false;
    locked = false;
  }

  // Set the size of the thumb
  void setThumbSize(int size) {
    thumbSize = constrain(size, 20, height);
  }

  // Set the range of the scrollbar
  void setRange(float min, float max) {
    posMin = min;
    posMax = max;
    pos = constrain(pos, posMin, posMax);
  }

  void update() {
    if (posMax == 0) return; // Skip if no scrolling needed
    
    // Check if mouse is over thumb
    int thumbY = int(map(pos, posMin, posMax, y, y + height - thumbSize));
    over = overRect(x, thumbY, width, thumbSize);
    
    if (locked) {
      // Update position when dragging
      float mouseDiff = mouseY - y;
      pos = map(mouseDiff - thumbSize/2, 0, height - thumbSize, posMin, posMax);
      pos = constrain(pos, posMin, posMax);
    }
  }

  // Check if mouse is over thumb
  boolean overRect(int x, int y, int width, int height) {
    return mouseX >= x && mouseX <= x + width && mouseY >= y && mouseY <= y + height;
  }

  void mousePressed() {
    if (over) {
      locked = true;
    } else if (mouseX >= x && mouseX <= x + width && mouseY >= y && mouseY <= y + height) {
      // Click on the track - jump to position
      float thumbY = constrain(mouseY - y - thumbSize/2, 0, height - thumbSize);
      pos = map(thumbY, 0, height - thumbSize, posMin, posMax);
      locked = true;
    }
  }

  void mouseDragged() {
    if (locked) {
      float mouseDiff = mouseY - y;
      pos = map(mouseDiff - thumbSize/2, 0, height - thumbSize, posMin, posMax);
      pos = constrain(pos, posMin, posMax);
    }
  }

  void mouseReleased() {
    locked = false;
  }

  float getPos() {
    return pos;
  }

  void display() {
    if (posMax == 0) return; // Don't display if no scrolling needed
    
    // Track
    fill(80, 85, 95);
    rect(x, y, width, height, 5);
    
    // Thumb
    if (over || locked) {
      fill(190, 200, 210);
    } else {
      fill(120, 130, 140);
    }
    
    // Calculate thumb position
    int thumbY = int(map(pos, posMin, posMax, y, y + height - thumbSize));
    rect(x, thumbY, width, thumbSize, 5);
  }
}