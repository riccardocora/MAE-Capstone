/**
 * SourceManager class
 * Manages the source controls area and displays track rectangles with source type indicators.
 * Now includes scrolling functionality.
 */
class SourceManager {
  Rectangle container; // Reference to the sourceControlsArea
  ArrayList<TrackSource> trackSources; // List of track sources
  int selectedSource = 0; // Currently selected source index
  
  // Scrollbar properties
  Scrollbar scrollbar;
  float scrollY = 0; // Current scroll position
  float contentHeight = 0; // Total height of all content
  float visibleHeight = 0; // Visible height of the container
  
// UI constants
  final int HEADER_HEIGHT = 30;
  final int ENTRY_HEIGHT = 80;
  final int ENTRY_PADDING = 5;
  final int ADD_BUTTON_SIZE = 24;
  final color BG_COLOR = color(50, 55, 65);
  final color HEADER_COLOR = color(60, 65, 75);
  final color ENTRY_COLOR = color(40, 45, 55);
  final color TEXT_COLOR = color(220, 220, 220);
  final color BUTTON_COLOR = color(70, 100, 150);
  final color HOVER_COLOR = color(80, 120, 180);

  // Hover states
  boolean addButtonHover = false;
  
  // Constructor
  SourceManager(int numTracks) {
    trackSources = new ArrayList<TrackSource>();

    // Initialize track sources
    for (int i = 0; i < numTracks; i++) {
      trackSources.add(new TrackSource("Track " + (i + 1), i, this));
    }
    // Initialize with default values, will be properly set in setContainer
    // Initialize scrollbar with default values (will be properly set in setContainer)
    this.scrollbar = new Scrollbar(0, 0, 10, 100, 20);
   
  }

  // Set the container reference and initialize scrollbar
  void setContainer(Rectangle container) {
    this.container = container;
    updateTrackPositions();
    
    // Configure scrollbar
    int scrollHeight = (int)(container.height - HEADER_HEIGHT);
    scrollbar.setDimensions(
      (int)(container.x + container.width - 15), 
      (int)(container.y + HEADER_HEIGHT), 
      10, 
      scrollHeight
    );
    
    // Calculate total content height
    int contentHeight = trackSources.size() * (ENTRY_HEIGHT + ENTRY_PADDING);
    scrollbar.setContentHeight(contentHeight);
    scrollbar.setViewportHeight(scrollHeight);
  }
  
  // void updateEntryPositions() {
  //   if (container == null) return;
    
  //   // Clear previous entries
  //   sourceEntries.clear();
    
  // // Create entry views for each source
  //   for (int i = 0; i < mixerModel.soundSources.size(); i++) {
  //     SoundSourceModel source = mixerModel.soundSources.get(i);
  //     TrackModel track = mixerModel.tracks.get(i);
      
  //     // Create entry view
  //     SourceEntryView entryView = new SourceEntryView(source, track, eventManager);
  //     entryView.setParentManager(this); // Set parent reference
  //     sourceEntries.add(entryView);
  //   }
    
  //   // Position entry views
  //   updateScrollPositions();
  // }
  // Update scrollbar properties based on content
  void updateScrollbar() {
    // if (container == null) return;
    
    // // Calculate total content height
    // contentHeight = trackSources.size() * (ENTRY_HEIGHT + TRACK_SPACING) + TRACK_SPACING + 50; // +50 for button area
    
    // // Only show scrollbar if content exceeds visible area
    // boolean needsScrollbar = contentHeight > visibleHeight;
    
    // if (needsScrollbar) {
    //   // Calculate thumb size relative to content
    //   float thumbRatio = min(1.0, visibleHeight / contentHeight);
    //   float thumbSize = max(20, visibleHeight * thumbRatio);
      
    //   scrollbar.setThumbSize((int)thumbSize);
    //   scrollbar.setRange(0, contentHeight - visibleHeight);
      
    //   // Ensure scroll position is within valid range
    //   scrollY = constrain(scrollY, 0, contentHeight - visibleHeight);
    // } else {
    //   scrollY = 0;
    // }
  }

  // Callback for the add source button
  void addSourceCallback() {
    addSource(); // Calls the global addSource() in the main sketch
  }

  // Add a new track source
  void addTrackSource() {
    int idx = trackSources.size();
    trackSources.add(new TrackSource("Track " + (idx + 1), idx, this));
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
        //trackSources.get(i).nameField.setText(trackSources.get(i).name);
      }
      updateTrackPositions();
      updateScrollbar();
    }
  }
  // Update positions of track rectangles
  void updateTrackPositions() {
    if (container == null) return;
    
    // Calculate visible area
    int visibleHeight = (int)container.height - HEADER_HEIGHT;
    
    // Update scrollbar max if needed
    int contentHeight = trackSources.size() * (ENTRY_HEIGHT + ENTRY_PADDING);
    scrollbar.setContentHeight(contentHeight);
    
    // Calculate scroll offset
    float scrollOffset = scrollbar.getScrollPosition();
    for (int i = 0; i < trackSources.size(); i++) {
      TrackSource trackSource = trackSources.get(i);

      float entryY = container.y + HEADER_HEIGHT + i * (ENTRY_HEIGHT + ENTRY_PADDING) - scrollOffset;
        // Only set position for visible entries
      if (entryY + ENTRY_HEIGHT > container.y + HEADER_HEIGHT && 
          entryY < container.y + container.height) {    
        // Set rectangle position
        trackSource.x = container.x + ENTRY_PADDING;
        trackSource.y = entryY;
        trackSource.width = container.width - 2 * ENTRY_PADDING - 15;
        trackSource.height = ENTRY_HEIGHT;
      }
    }


  }
  
  // Handle scrolling
  void mouseWheel(MouseEvent event) {
        if (container == null) return;
    
    // Check if mouse is over the container
    if (mouseX > container.x && mouseX < container.x + container.width &&
        mouseY > container.y && mouseY < container.y + container.height) {
      scrollbar.handleMouseWheel(event);
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
    
    // Draw background
    noStroke();
    fill(BG_COLOR);
    rect(container.x, container.y, container.width, container.height, 10);
    
    // Draw header
    fill(HEADER_COLOR);
    rect(container.x, container.y, container.width, HEADER_HEIGHT);
    
    // Draw title
    fill(TEXT_COLOR);
    textAlign(LEFT, CENTER);
    textSize(16);
    text("Source Manager", container.x + 10, container.y + HEADER_HEIGHT/2);
    
    // Draw add button
    color buttonColor = addButtonHover ? HOVER_COLOR : BUTTON_COLOR;
    fill(buttonColor);
    rect(container.x + container.width - ADD_BUTTON_SIZE - 10, 
         container.y + (HEADER_HEIGHT - ADD_BUTTON_SIZE)/2, 
         ADD_BUTTON_SIZE, ADD_BUTTON_SIZE, 3);
         
    // Add + symbol
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(18);
    text("+", container.x + container.width - ADD_BUTTON_SIZE/2 - 10, 
         container.y + HEADER_HEIGHT/2 - 1);
    
    // Draw scrollbar
    scrollbar.draw();
    
    // Draw source entries
    pushMatrix();
    clip(container.x, container.y + HEADER_HEIGHT, 
         container.width, container.height - HEADER_HEIGHT);    // Draw each track source rectangle
    for (TrackSource trackSource : trackSources) {
      // Only draw if within visible area (with some margin)
      if (trackSource.y + trackSource.height > container.y + HEADER_HEIGHT && 
          trackSource.y < container.y + container.height) {
        // Check if this is the selected source
        boolean isSelected = (trackSource.index == selectedSource);
        trackSource.draw(isSelected);
      }
      
    }

        
    popMatrix();
    noClip();
  }
  
  // Handle mouse events for scrollbar
  void mousePressed() {
    scrollbar.handleMousePressed();
  }
  
  void mouseDragged() {
    scrollbar.handleMouseDragged();
  }
  
  void mouseReleased() {
    scrollbar.handleMouseReleased();
  }

  void handleRenameTrack(int idx, String newName) {
    // Call the global renameSource in the main sketch
    renameSource(idx, newName);
  }

  void renameTrack(int idx, String newName) {
    if (idx >= 0 && idx < trackSources.size()) {
      trackSources.get(idx).name = newName;
      //trackSources.get(idx).nameField.setText(newName);
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
  int mode = 0; // 0 = Mono/Stereo, 1 = Ambi, 2 = Send
  
  // Source type names
  String[] modeNames = {"Mono/Stereo", "Ambi", "Send"};
  color[] modeColors = {color(50, 200, 50), color(50, 50, 200), color(200, 50, 50)};

  // Button states
  boolean removeButtonHover = false;
  boolean editButtonHover = false;
  boolean isEditing = false;
  
  final color ENTRY_BG = color(40, 45, 55);
  final color BUTTON_COLOR = color(70, 100, 150);
  final color HOVER_COLOR = color(80, 120, 180);
  final color REMOVE_COLOR = color(200, 60, 60);
  final color REMOVE_HOVER = color(220, 80, 80);

  // Constructor
  TrackSource(String name, int index, SourceManager parent) {
    this.name = name;
    this.index = index;
    this.parent = parent;
    
    // // Create the textfield for track name
    // nameField = cp5.addTextfield("TrackName_" + index)
    //               .setText(name)
    //               .setPosition(x + 10, y + 35) // Will be updated in updateTrackPositions
    //               .setSize(80, 20)
    //               .onChange(e -> parent.handleRenameTrack(index, nameField.getText()));
  }  // Draw the track rectangle
  void draw(boolean isSelected) {



    // Draw background
    noStroke();
      // Highlight selected source with yellow background
    if (isSelected) {
      fill(225, 140, 60);// Yellow highlight for selected track
    } else {
      fill(ENTRY_BG);  // Regular color for non-selected tracks
    }
    
    
    
    stroke(100, 110, 130);
    strokeWeight(2);
    rect(x, y, width, height, 5);
    
  
    
    // Draw custom name text field
    fill(30, 35, 45);
    rect(x + 10, y + 8, width - 80, 20, 3);
    
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(12);
    text(name, x + 15, y + 18);
    
    // Draw remove button
    float buttonX = x + width - 25;
    float buttonY = y + 8;
    float buttonSize = 20;
    
    fill(removeButtonHover ? REMOVE_HOVER : REMOVE_COLOR);
    rect(buttonX, buttonY, buttonSize, buttonSize, 3);
    
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(14);
    text("×", buttonX + buttonSize/2, buttonY + buttonSize/2 - 1);
    

    // Draw source type indicator circle
    float circleX = x + 20;
    float circleY = y + height - 20;
    float circleSize = 15;
    
    // Draw circle with color based on current mode
    fill(modeColors[mode]);
    stroke(255);
    strokeWeight(1);
    ellipse(circleX, circleY, circleSize, circleSize);
    
    // Draw mode name
    fill(255);
    textAlign(LEFT);
    textSize(12);
    text(modeNames[mode], circleX + 15, circleY + 5);
  }



  
  boolean handleMousePressed(float mx, float my) {
    // Check if click is within entry bounds
    if (mx < x || mx > x + width || my < y || my > y + height) {
      return false;
    }
    
    // Check if the mouse is over the remove button
    float buttonX = x + width - 25;
    float buttonY = y + 8;
    float buttonSize = 20;
    
    if (mx > buttonX && mx < buttonX + buttonSize &&
        my > buttonY && my < buttonY + buttonSize) {
      // Remove this source
      
     
      
      return true;
    }
    
    return false;
  }
  
  void handleMouseDragged(float mx, float my) {
    // Nothing to drag
  }
  
  void handleMouseReleased() {
    // Nothing to release
  }
  
  void handleMouseMoved(float mx, float my) {
    // Check if the mouse is over the remove button
    float buttonX = x + width - 25;
    float buttonY = y + 8;
    float buttonSize = 20;
    
    removeButtonHover = (mx > buttonX && mx < buttonX + buttonSize &&
                          my > buttonY && my < buttonY + buttonSize);
  }
    
  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }

   void setDimensions(float width, float height) {
    this.width = width;
    this.height = height;
  }
}

/**
 * Scrollbar class
 * A simple vertical scrollbar for scrolling content
 */
class Scrollbar {
  // Position and dimensions
  int x, y, width, height;
  
  // Scrollbar properties
  float valueMin = 0;     // Minimum value
  float valueMax = 100;   // Maximum value 
  float valueRange = 100; // Range (max - min)
  float value = 0;        // Current value
  
  // Thumb properties
  int thumbSize = 20;     // Size of the scrollbar thumb
  boolean isDragging = false;
  
  // Content properties for scroll area
  float contentHeight = 0;   // Total content height
  float viewportHeight = 0;  // Visible viewport height
  
  // Constructor
  Scrollbar(int x, int y, int width, int height, int thumbSize) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.thumbSize = thumbSize;
    this.valueRange = valueMax - valueMin;
  }
  
  // Set new dimensions
  void setDimensions(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
  
  // Set content height (the total scrollable height)
  void setContentHeight(float height) {
    contentHeight = max(0, height);
    updateScrollRange();
  }
  
  // Set viewport height (visible area height)
  void setViewportHeight(float height) {
    viewportHeight = max(0, height);
    updateScrollRange();
  }
  
  // Update scroll range based on content and viewport heights
  private void updateScrollRange() {
    if (contentHeight <= viewportHeight) {
      // Content fits in viewport, no scrolling needed
      setRange(0, 0);
    } else {
      // Content exceeds viewport, enable scrolling
      setRange(0, contentHeight - viewportHeight);
    }
  }
  
  // Get scroll position
  float getScrollPosition() {
    return value;
  }
  
  // Set the thumb size
  void setThumbSize(int size) {
    thumbSize = constrain(size, 10, height);
  }
  
  // Set the value range
  void setRange(float min, float max) {
    valueMin = min;
    valueMax = max;
    valueRange = max - min;
    value = constrain(value, valueMin, valueMax);
  }
  
  // Get the normalized position of the thumb (0-1)
  float getNormalizedValue() {
    return map(value, valueMin, valueMax, 0, 1);
  }
  
  // Set the value directly
  void setValue(float newValue) {
    value = constrain(newValue, valueMin, valueMax);
  }
    // Check if the mouse is over the scrollbar
  boolean isOver(float mouseX, float mouseY) {
    return (mouseX >= x && mouseX <= x + width && 
            mouseY >= y && mouseY <= y + height);
  }
  
  // Check if the mouse is over the thumb
  boolean isOverThumb(float mouseX, float mouseY) {
    float thumbY = map(value, valueMin, valueMax, y, y + height - thumbSize);
    return (mouseX >= x && mouseX <= x + width && 
            mouseY >= thumbY && mouseY <= thumbY + thumbSize);
  }
  
  // Handle mouse pressed event
  boolean handleMousePressed() {
    if (isOverThumb(mouseX, mouseY)) {
      isDragging = true;
      return true;
    } else if (isOver(mouseX, mouseY)) {
      // Jump to clicked position
      float newY = constrain(mouseY - y, 0, height - thumbSize);
      value = map(newY, 0, height - thumbSize, valueMin, valueMax);
      return true;
    }
    return false;
  }
  
  // Handle mouse dragged event
  boolean handleMouseDragged() {
    if (isDragging) {
      float newY = constrain(mouseY - y, 0, height - thumbSize);
      value = map(newY, 0, height - thumbSize, valueMin, valueMax);
      return true;
    }
    return false;
  }
  
  // Handle mouse released event
  void handleMouseReleased() {
    isDragging = false;
  }
  
  // Handle mouse wheel event
  void handleMouseWheel(MouseEvent event) {
    float e = event.getCount();
    // Adjust scroll position based on wheel direction
    value = constrain(value + e * 20, valueMin, valueMax);
  }
  
  // Draw the scrollbar
  void draw() {
    // Draw background
    fill(60, 60, 70);
    rect(x, y, width, height);
    
    // Draw thumb
    if (isDragging) {
      fill(200, 200, 220);
    } else {
      fill(120, 120, 140);
    }
    
    float thumbY = map(value, valueMin, valueMax, y, y + height - thumbSize);
    rect(x, thumbY, width, thumbSize);
  }
}
