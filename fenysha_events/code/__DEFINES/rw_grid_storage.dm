// Grid Storage System
// Each visual cell is 16x16 pixels.

#define GRID_CELL_SIZE 16

/// Default carry limits
#define DEFAULT_MAX_CARRY_WEIGHT 30 // kg
#define DEFAULT_MAX_CARRY_VOLUME 100

/// Short do_after durations (in deciseconds)
#define GRID_INSERT_DELAY 4   // 0.4s
#define GRID_REMOVE_DELAY 3   // 0.3s

/// Toolbar placement modes for grid panel buttons
#define GRID_TOOLBAR_RIGHT       1
#define GRID_TOOLBAR_TOP_RIGHT   2
#define GRID_TOOLBAR_BOTTOM_LEFT 3

/// Rotation helpers
#define GRID_ROT_0 0
#define GRID_ROT_90 90
#define GRID_ROT_180 180
#define GRID_ROT_270 270

/// Returns effective width/height after rotation
#define GRID_EFFECTIVE_WIDTH(item) (((item.grid_rotation % 180) == 0) ? item.grid_width : item.grid_height)
#define GRID_EFFECTIVE_HEIGHT(item) (((item.grid_rotation % 180) == 0) ? item.grid_height : item.grid_width)

