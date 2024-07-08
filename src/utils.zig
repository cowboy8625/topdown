const std = @import("std");
const rl = @import("raylib_zig");
const CONSTANTS = @import("constants.zig");

// Takes a grid position Vector(i32) and returns the world position as Vector2(f32)
pub fn get_world_pos_from_grid(comptime T: type, pos: rl.Vector2(T), cell: rl.Vector2(T)) rl.Vector2(f32) {
    return pos.mul(cell).as(f32);
}

pub fn get_top_left_coner_of_grid_on_screen(player: rl.Vector2(i32), screen: rl.Vector2(i32)) rl.Vector2(i32) {
    return player.sub(screen.div(CONSTANTS.CUBE).div(.{ .x = 2, .y = 2 }));
}
