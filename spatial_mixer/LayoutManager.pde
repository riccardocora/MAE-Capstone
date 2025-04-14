/**
 * LayoutManager class
 * Handles the main layout partitioning and coordinates between interface sections
 */
class LayoutManager {
  // Container dimensions
  Rectangle mainViewArea;
  Rectangle trackControlsArea;
  Rectangle uiControlsArea;
  
  // Padding and sizing constants
  final int PADDING = 10;
  final int TRACK_AREA_HEIGHT = 200;
  final int UI_AREA_WIDTH = 280;
  
  LayoutManager(int windowWidth, int windowHeight) {
    updateLayout(windowWidth, windowHeight);
  }
  
  void updateLayout(int windowWidth, int windowHeight) {
    // Calculate dimensions for each container
    
    // Bottom track controls area
    trackControlsArea = new Rectangle(
      PADDING, 
      windowHeight - TRACK_AREA_HEIGHT - PADDING,
      windowWidth - 2 * PADDING, 
      TRACK_AREA_HEIGHT
    );
    
    // Right UI controls area
    uiControlsArea = new Rectangle(
      windowWidth - UI_AREA_WIDTH - PADDING,
      PADDING,
      UI_AREA_WIDTH,
      windowHeight - trackControlsArea.height - 3 * PADDING
    );
    
    // Main view area (takes remaining space)
    mainViewArea = new Rectangle(
      PADDING,
      PADDING,
      windowWidth - uiControlsArea.width - 3 * PADDING,
      windowHeight - trackControlsArea.height - 3 * PADDING
    );
  }
  
  void drawContainerBorders() {
    // Draw borders around each container
    stroke(70, 80, 100);
    strokeWeight(2);
    noFill();
    
    // Main view container
    rect(mainViewArea.x, mainViewArea.y, mainViewArea.width, mainViewArea.height, 10);
    
    // Track controls container
    rect(trackControlsArea.x, trackControlsArea.y, trackControlsArea.width, trackControlsArea.height, 10);
    
    // UI controls container
    rect(uiControlsArea.x, uiControlsArea.y, uiControlsArea.width, uiControlsArea.height, 10);
  }
}

