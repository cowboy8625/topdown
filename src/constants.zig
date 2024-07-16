const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig").Vector2;

pub const BACKGROUND_COLOR = rl.Color.init(40, 40, 40, 255);
pub const GRID_COLOR = rl.Color.black;
pub const UI_TEXT_COLOR = rl.Color.ray_white;
pub const TEXT_BUFFER_SIZE = 256;
pub const POINT_BUFFER_SIZE = 9;
pub const CELL_SIZE = 32;
pub const CUBE: Vector2(i32) = .{ .x = CELL_SIZE, .y = CELL_SIZE };
