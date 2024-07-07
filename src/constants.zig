const std = @import("std");
const rl = @import("raylib_zig");

pub const BACKGROUND_COLOR = rl.Color.init(40, 40, 40, 255);
pub const GRID_COLOR = rl.Color.black();
pub const UI_TEXT_COLOR = rl.Color.rayWhite();
pub const TEXT_BUFFER_SIZE = 256;
pub const POINT_BUFFER_SIZE = 9;
pub const CELL_SIZE = 32;
pub const CUBE: rl.Vector2(i32) = .{ .x = CELL_SIZE, .y = CELL_SIZE };
