const std = @import("std");
const rl = @import("raylib_zig");

// Takes a grid position Vector(i32) and returns the world position as Vector2(f32)
pub fn get_world_pos_from_grid(comptime T: type, pos: rl.Vector2(T), cell: rl.Vector2(T)) rl.Vector2(f32) {
    return pos.mul(cell).as(f32);
}
