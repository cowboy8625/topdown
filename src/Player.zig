const std = @import("std");
const rl = @import("raylib_zig");
const utils = @import("utils.zig");
const Interpolation = @import("Interpolation.zig");
const CONSTANTS = @import("constants.zig");
const Chunk = @import("Chunk.zig");

const Self = @This();

const CENTER: rl.Vector2(f32) = CONSTANTS.CUBE.as(f32).divFromNum(2);
current_pos: rl.Vector2(i32),
animation: ?Interpolation = null,

pub fn init() Self {
    return .{
        .current_pos = .{ .x = 0, .y = 0 },
        .animation = null,
    };
}

pub fn getWorldPos(self: *const Self) rl.Vector2(f32) {
    if (self.animation) |animation| {
        return animation.current;
    }
    return utils.get_world_pos_from_grid(i32, self.current_pos, CONSTANTS.CUBE);
}

pub fn getChunkPos(self: *const Self) rl.Vector2(i32) {
    return self.current_pos.divFromNum(Chunk.SIZE);
}

pub fn move(self: *Self, dir: rl.Vector2(i32)) void {
    if (dir.isZero()) return;
    const start = self.current_pos;
    const end = self.current_pos.add(dir);
    const world_start = start.mul(CONSTANTS.CUBE).as(f32);
    const world_end = end.mul(CONSTANTS.CUBE).as(f32);
    self.startAnimation(world_start, world_end, 0.2);
    self.current_pos = end;
}

pub fn center(self: *const Self) rl.Vector2(f32) {
    return self.current_pos.mul(CONSTANTS.CUBE).as(f32).add(Self.CENTER);
}

pub fn startAnimation(self: *Self, start: rl.Vector2(f32), end: rl.Vector2(f32), duration: f32) void {
    self.animation = Interpolation{
        .start = start,
        .end = end,
        .current = start,
        .time = 0.0,
        .elapsedTime = 0.0,
        .duration = duration,
    };
}

pub fn isAnimating(self: *const Self) bool {
    return self.animation != null;
}

pub fn update(self: *Self, deltaTime: f32) void {
    if (self.animation) |*animation| {
        if (animation.isDone()) {
            self.animation = null;
            return;
        }
        animation.update(deltaTime);
        return;
    }
}

pub fn draw(self: Self) void {
    if (self.animation) |_| {
        const pos = self.getWorldPos();
        rl.DrawRectangleV(pos, CONSTANTS.CUBE.as(f32), rl.Color.red());
        return;
    }

    const pos = utils.get_world_pos_from_grid(i32, self.current_pos, CONSTANTS.CUBE);
    rl.DrawRectangleV(pos, CONSTANTS.CUBE.as(f32), rl.Color.red());
}
