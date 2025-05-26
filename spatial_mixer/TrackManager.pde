
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

    // Calculate track height based on container height with padding
    float trackHeight = container.height - 20; // Subtract 10 padding from top and bottom
    float trackSpacing = 70;
    float initialX = container.x + 20;
    float trackY = container.y + 10; // Add top padding

    masterTrack.setPosition(initialX, trackY);
    masterTrack.setHeight(trackHeight); // Set height for master track

    // Position other tracks
    for (int i = 0; i < tracks.size(); i++) {
      tracks.get(i).setPosition(initialX + (i + 1) * trackSpacing, trackY);
      tracks.get(i).setHeight(trackHeight); // Set height for each track
    }
  }
  void draw(int selectedSource) {
    if (container == null) return;

    drawContainerBackground(container, "Mixer Channels");

    // Draw master track (never selected)
    masterTrack.draw(false);

    // Draw other tracks
    for (int i = 0; i < tracks.size(); i++) {
      // Pass true if this track matches the selected source index
      boolean isSelected = (i == selectedSource);
      tracks.get(i).draw(isSelected);
    }
  }

  void handleMousePressed(float mouseX, float mouseY) {
    // Check if the mouse is over any track's fader
    for (Track track : tracks) {
      if (track.isMouseOverFader(mouseX, mouseY)) {
        track.startDragging(mouseY);
      }
      else if(track.isMouseOverMuteButton(mouseX, mouseY)) {
        track.setMuted(!track.muted); // Toggle mute state
      }
      else if(track.isMouseOverSoloButton(mouseX, mouseY)) {
        track.setSoloed(!track.soloed); // Toggle solo state
      }
    }

    // Check for master track
    if (masterTrack.isMouseOverFader(mouseX, mouseY)) {
      masterTrack.startDragging(mouseY);
    } 
    else if(masterTrack.isMouseOverMuteButton(mouseX, mouseY)) {
        masterTrack.setMuted(!masterTrack.muted); // Toggle mute state
    }
    else if(masterTrack.isMouseOverSoloButton(mouseX, mouseY)) {
        masterTrack.setSoloed(!masterTrack.soloed); // Toggle solo state
    }
  }

  void handleMouseDragged(float mouseX, float mouseY) {
    // Update the fader position for any track being dragged
    for (Track track : tracks) {
      if (track.isDragging) {
        track.updateFader(mouseY);
      }
    }

    // Update master track if being dragged
    if (masterTrack.isDragging) {
      masterTrack.updateFader(mouseY);
    }
  }

  void handleMouseReleased() {
    // Stop dragging for all tracks
    for (Track track : tracks) {
      track.stopDragging();
    }

    // Stop dragging for master track
    masterTrack.stopDragging();
  }

  // Helper method to draw container background and title
  void drawContainerBackground(Rectangle container, String title) {
    fill(40, 45, 55, 200);
    noStroke();
    rect(container.x, container.y, container.width, container.height, 10);

    fill(255);
    textAlign(LEFT);
    textSize(14);
    text(title, container.x + 10, container.y + 15);
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
  boolean isDragging = false; // Whether the fader is being dragged
  int index; // Unique index for this track

  // Track dimensions
  float width = 60;
  float height = 120;

    // Layout constants - using proportions of total height for a more responsive design
  final float LABEL_RATIO = 0.10;       // Proportion of height for track name label (reduced further)
  final float BUTTON_RATIO = 0.08;      // Proportion of height for mute/solo buttons (reduced further)
  final float PADDING_RATIO = 0.015;    // Proportion of height for padding (reduced further)
  final float FADER_WIDTH = 28;         // Width of the fader track (increased)
  final float FADER_HANDLE_HEIGHT = 10; // Height of the fader handle (increased)
  

  OscHelper oscHelper; // Reference to the OscHelper instance
  Track(int id, String name, float x, float y, OscHelper oscHelper, int index) {
    this.id = id;
    this.name = name;
    this.x = x;
    this.y = y;
    this.oscHelper = oscHelper;
    this.index = index;
  }

  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void setVolume(float volume) {
    this.volume = constrain(volume, 0, 1);
    sendOscVolume(); // Send OSC message when volume changes
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

  void setHeight(float height) {
    this.height = height;
  }
  // void draw(boolean isSelected) {
  //   // Draw track background
  //   noStroke();
    
  //   // Highlight the selected track with yellow background
  //   if (isSelected) {
  //     fill(225, 140, 60); // Yellow for selected track
  //   } else {
  //     fill(50, 55, 65);   // Regular color for non-selected track
  //   }
    
  //   rect(x, y, width, height, 5);

  //   // Draw track label
  //   fill(255);
  //   textAlign(CENTER);
  //   textSize(12);
  //   text(name, x + width / 2, y + 15);

  //   // Draw volume fader background
  //   fill(30, 35, 45);
  //   float faderBgX = x + (width - 20) / 2; // Center the fader background horizontally
  //   rect(faderBgX, y + 25, 20, height - 50, 3);

  //   // Draw VU meter (behind volume fader)
  //   if (!muted) {
  //     float vuHeight = vuLevel * (height - 50);
  //     for (int i = 0; i < vuHeight; i++) {
  //       float position = i / (height - 50.0);
  //       color meterColor = lerpColor(
  //         lerpColor(color(0, 200, 0), color(255, 255, 0), min(position * 2, 1)),
  //         color(255, 0, 0),
  //         max((position - 0.5) * 2, 0)
  //       );
  //       stroke(meterColor);
  //       line(faderBgX + 2, y + height - 25 - i, faderBgX + 18, y + height - 25 - i);
  //     }
  //   }

  //   // Draw volume fader
  //   fill(muted ? color(100, 0, 0) : (soloed ? color(0, 100, 0) : color(180)));
  //   float faderY = y + height - 25 - (volume * (height - 50));
  //   rect(faderBgX - 2, faderY - 3, 24, 6, 2);

  //   // Draw mute/solo buttons
  //   fill(muted ? color(255, 0, 0) : color(100));
  //   rect(x + 10, y + height - 25, 15, 15, 3);
  //   fill(255);
  //   textSize(10);
  //   text("M", x + 18, y + height - 14);

  //   fill(soloed ? color(0, 255, 0) : color(100));
  //   rect(x + width - 25, y + height - 25, 15, 15, 3);
  //   fill(255);
  //   text("S", x + width - 17, y + height - 14);
  // }


  void draw(boolean isSelected) {
    // Calculate proportional dimensions based on current height
    float labelHeight = height * LABEL_RATIO;
    float buttonHeight = height * BUTTON_RATIO;
    float padding = height * PADDING_RATIO;
    
    // Calculate positions
    float labelY = y + labelHeight/2;
    float buttonY = y + height - buttonHeight - padding;
    float faderTop = y + labelHeight + padding;
    float faderBottom = buttonY - padding;
    float faderHeight = faderBottom - faderTop;
      // Determine background color based on source type
    color bgColor = color(50, 55, 65); // Default background color
    // Highlight the selected track with yellow background
    if (isSelected) {
      bgColor = color(225, 140, 60); // Yellow for selected track
    } else {
      bgColor = color(50, 55, 65);   // Regular color for non-selected track
    }
    // Draw track background with type-specific color
    noStroke();
    fill(bgColor);
    rect(x, y, width, height, 5);
    
    // Add outer border for track
    stroke(70, 75, 85);
    strokeWeight(1);
    noFill();
    rect(x, y, width, height, 5);
    noStroke();

    // Draw track label
    fill(255);
    textAlign(CENTER);
    textSize(min(12, labelHeight * 0.7)); // Scale text size with label height
    text(name, x + width / 2, labelY + textAscent()/2);
    
    // Draw volume fader background with depth effect
    fill(25, 30, 40);
    float faderBgX = x + (width - FADER_WIDTH) / 2; // Center the fader background horizontally
    rect(faderBgX, faderTop, FADER_WIDTH, faderHeight, 5);
    
    // Add inner shadow effect to fader track
    stroke(20, 25, 35, 100);
    strokeWeight(1);
    noFill();
    rect(faderBgX + 1, faderTop + 1, FADER_WIDTH - 2, faderHeight - 2, 4);
    noStroke();    // Draw scale lines for better visibility with db markings
    stroke(70, 75, 85);
    strokeWeight(1);
    float numLines = 12; // Increased number of scale lines for more precision
    
    // Draw db scale with special emphasis on specific levels
    for (int i = 0; i <= numLines; i++) {
      float lineY = faderTop + (i * (faderHeight / numLines));
      float lineWidth;
      
      // Make special emphasis on key db levels
      if (i == 0) { // 0 dB
          lineWidth = FADER_WIDTH * 0.8;
          stroke(100, 200, 100, 180); // Green for 0dB
      } else if (i == numLines) { // -∞ dB
          lineWidth = FADER_WIDTH * 0.8;
          stroke(200, 100, 100, 180); // Red for -inf
      } else if (i == numLines / 2) { // -6dB (middle)
          lineWidth = FADER_WIDTH * 0.7;
          stroke(200, 200, 100, 180); // Yellow for middle
      } else if (i % 3 == 0) { // Other major markers
          lineWidth = FADER_WIDTH * 0.5;
          stroke(100, 120, 140, 160);
      } else { // Minor markers
          lineWidth = FADER_WIDTH * 0.3;
          stroke(70, 75, 85, 140);
      }
      
      line(faderBgX + (FADER_WIDTH - lineWidth)/2, lineY, 
          faderBgX + (FADER_WIDTH + lineWidth)/2, lineY);
    }
    
    stroke(60, 65, 75); // Reset stroke    // Draw VU meter (behind volume fader) with enhanced visualization
    noStroke();
    if (!muted) {
      float vuHeight = vuLevel * faderHeight;
      float segment = faderHeight / 24.0; // More segments for smoother gradient
      
      // Draw VU meter background for better visibility when level is low
      fill(40, 45, 55, 100);
      rect(faderBgX + 2, faderTop, FADER_WIDTH - 4, faderHeight);
      
      // Draw the actual VU meter with improved gradient
      for (int i = 0; i < 24; i++) {
        float segmentTop = faderBottom - (i+1) * segment;
        float segmentHeight = min(segment - 1, vuHeight - i * segment); // Gap between segments
        
        if (segmentHeight <= 0) break;
        
        float position = i / 24.0;
        color meterColor;
        
        // Enhanced color gradient for better visual feedback
        if (position < 0.6) {
          // Green to yellow gradient for lower levels
          meterColor = lerpColor(color(0, 180, 0), color(220, 220, 0), position / 0.6);
        } else if (position < 0.8) {
          // Yellow to orange transition
          meterColor = lerpColor(color(220, 220, 0), color(255, 140, 0), (position - 0.6) / 0.2);
        } else {
          // Orange to red for peaks
          meterColor = lerpColor(color(255, 140, 0), color(255, 30, 30), (position - 0.8) / 0.2);
        }
        
        // Add pulsing effect when near peak
        float alpha = 220;
        if (position > 0.9 && vuLevel > 0.9) {
          // Create a pulsing effect for peaks
          alpha = 180 + sin(frameCount * 0.2) * 40;
        }
        
        fill(meterColor, alpha);
        // Rounded corners for segments
        rect(faderBgX + 3, segmentTop, FADER_WIDTH - 6, segmentHeight, 1);
      }
      
      // Peak indicator that stays visible longer
      if (vuLevel > 0.95) {
        fill(255, 20, 20, 220);
        rect(faderBgX + 3, faderTop, FADER_WIDTH - 6, segment, 2);
      }
    }
    
    // Draw db markings
    fill(200);
    textSize(8);
    textAlign(RIGHT);
    text("0", faderBgX - 2, faderTop + 10);
    text("-∞", faderBgX - 2, faderBottom - 2);

    // Draw volume fader handle (more prominent)
    strokeWeight(1);
    stroke(120, 120, 140);
    float faderY = faderBottom - (volume * faderHeight);
    
    // Fader handle color based on state
    color handleColor = muted ? color(200, 30, 30) : 
                      (soloed ? color(30, 200, 30) : color(180, 180, 220));
    
    fill(handleColor);
    // Wider fader handle for better visibility and usability
    rect(faderBgX - 4, faderY - FADER_HANDLE_HEIGHT/2, 
        FADER_WIDTH + 8, FADER_HANDLE_HEIGHT, 3);
        
    // Add grip lines on the fader handle for a more professional look
    stroke(muted ? color(150, 20, 20) : 
          (soloed ? color(20, 150, 20) : color(100, 100, 140)));
    for (int i = 1; i < 4; i++) {
      line(faderBgX + i * (FADER_WIDTH/4), faderY - FADER_HANDLE_HEIGHT/3,
          faderBgX + i * (FADER_WIDTH/4), faderY + FADER_HANDLE_HEIGHT/3);
    }
    
    noStroke(); // Reset stroke for next elements

    // Calculate button positions and sizes
    float buttonSize = min(buttonHeight, width/4);
    float muteX = x + width * 0.25 - buttonSize/2;
    float soloX = x + width * 0.75 - buttonSize/2;
    
    // Draw mute/solo buttons
    fill(muted ? color(255, 0, 0) : color(100));
    rect(muteX, buttonY, buttonSize, buttonSize, 3);
    fill(255);
    textSize(min(10, buttonSize * 0.7));
    text("M", muteX + buttonSize/2, buttonY + buttonSize/2 + textAscent()/3);

    fill(soloed ? color(0, 255, 0) : color(100));
    rect(soloX, buttonY, buttonSize, buttonSize, 3);
    fill(255);
    text("S", soloX + buttonSize/2, buttonY + buttonSize/2 + textAscent()/3);
  }


  boolean isMouseOverFader(float mouseX, float mouseY) {
    // Calculate positions using proportional layout
    float labelHeight = height * LABEL_RATIO;
    float buttonHeight = height * BUTTON_RATIO;
    float padding = height * PADDING_RATIO;
    float buttonY = y + height - buttonHeight - padding;
    float faderTop = y + labelHeight + padding;
    float faderBottom = buttonY - padding;
    
    float faderBgX = x + (width - FADER_WIDTH) / 2;
    
    // Make entire fader track area clickable for better user experience
    // This allows users to click anywhere on the track to set the volume
    return mouseX >= faderBgX - 4 && mouseX <= faderBgX + FADER_WIDTH + 4 && 
          mouseY >= faderTop && mouseY <= faderBottom;
  }

   boolean isMouseOverMuteButton(float mouseX, float mouseY) {
    // Calculate button positions using proportional layout
    float buttonHeight = height * BUTTON_RATIO;
    float padding = height * PADDING_RATIO;
    float buttonY = y + height - buttonHeight - padding;
    float buttonSize = min(buttonHeight, width/4);
    float muteX = x + width * 0.25 - buttonSize/2;
    
    return mouseX >= muteX && mouseX <= muteX + buttonSize && 
           mouseY >= buttonY && mouseY <= buttonY + buttonSize;
  }
  
  boolean isMouseOverSoloButton(float mouseX, float mouseY) {
    // Calculate button positions using proportional layout
    float buttonHeight = height * BUTTON_RATIO;
    float padding = height * PADDING_RATIO;
    float buttonY = y + height - buttonHeight - padding;
    float buttonSize = min(buttonHeight, width/4);
    float soloX = x + width * 0.75 - buttonSize/2;
    
    return mouseX >= soloX && mouseX <= soloX + buttonSize && 
           mouseY >= buttonY && mouseY <= buttonY + buttonSize;
  }

  void startDragging(float mouseY) {
    isDragging = true;
    updateFader(mouseY);
  }

  void updateFader(float mouseY) {
    float faderHeight = height - 50;
    float newVolume = constrain((y + height - 25 - mouseY) / faderHeight, 0, 1);
    setVolume(newVolume);
  }

  void stopDragging() {
    isDragging = false;
  }

  void sendOscVolume() {
    if (oscHelper != null) {
      oscHelper.sendOscVolume(id, volume); // Use OscHelper to send the volume message
    } else {
      println("Error: OscHelper is not initialized.");
    }
  }
}
