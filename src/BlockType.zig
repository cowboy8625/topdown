const std = @import("std");
const rl = @import("raylib_zig");
const CONSTANTS = @import("constants.zig");

pub const BlockType = enum {
    Stone,

    pub fn color(self: BlockType) rl.Color {
        return switch (self) {
            .Stone => rl.Color.lightGray(),
        };
    }

    pub fn draw(_: *const BlockType, pos: rl.Vector2(f32)) void {
        rl.DrawRectangleV(
            pos,
            CONSTANTS.CUBE.as(f32),
            rl.Color.lightGray(),
        );
    }
};
