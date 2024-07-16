const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig").Vector2;
const CONSTANTS = @import("constants.zig");

pub const BlockType = enum {
    Stone,
    Dirt,
    Grass,

    pub fn color(self: BlockType) rl.Color {
        return switch (self) {
            .Stone => rl.Color.light_gray,
            .Dirt => rl.Color.brown,
            .Grass => rl.Color.green,
        };
    }

    pub fn draw(self: *const BlockType, pos: Vector2(f32)) void {
        rl.drawRectangleV(
            pos.asRaylibVector2(),
            CONSTANTS.CUBE.as(f32).asRaylibVector2(),
            self.color(),
        );
    }
};
