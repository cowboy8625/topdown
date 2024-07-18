const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig").Vector2;
const Allocator = std.mem.Allocator;
const utils = @import("utils.zig");
const Interpolation = @import("Interpolation.zig");
const CONSTANTS = @import("constants.zig");
const Chunk = @import("Chunk.zig");
const Inventory = @import("Inventory.zig");
const BlockType = @import("BlockType.zig").BlockType;

const Self = @This();

const CENTER: Vector2(f32) = CONSTANTS.CUBE.as(f32).div(2);
current_pos: Vector2(i32),
inventory: Inventory,
right_hand: usize = 0,
velocity: Vector2(i32) = .{ .x = 0, .y = 0 },
animation: ?Interpolation = null,

pub fn init(alloc: Allocator) Self {
    return .{
        .current_pos = .{ .x = 0, .y = 0 },
        .inventory = Inventory.init(alloc),
        .animation = null,
    };
}

pub fn deinit(self: *Self) void {
    self.inventory.deinit();
}

pub fn addToInventory(self: *Self, item: BlockType) !void {
    try self.inventory.add(item);
}

pub fn getItemFromActiveSlot(self: *Self) ?BlockType {
    return self.inventory.remove(self.right_hand);
}

pub fn getWorldPos(self: *const Self) Vector2(f32) {
    if (self.animation) |animation| {
        return animation.current;
    }
    return utils.get_world_pos_from_grid(i32, self.current_pos, CONSTANTS.CUBE);
}

pub fn move(self: *Self, dir: Vector2(i32)) void {
    if (dir.isZero()) return;
    const start = self.current_pos;
    const end = self.current_pos.add(dir);
    const world_start = start.mul(CONSTANTS.CUBE).as(f32);
    const world_end = end.mul(CONSTANTS.CUBE).as(f32);
    self.startAnimation(world_start, world_end, 0.2);
    self.current_pos = end;
}

// Center of Player
pub fn center(self: *const Self) Vector2(f32) {
    return self.current_pos.mul(CONSTANTS.CUBE).as(f32).add(Self.CENTER);
}

pub fn startAnimation(self: *Self, start: Vector2(f32), end: Vector2(f32), duration: f32) void {
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

pub fn draw(self: Self, camera: *rl.Camera2D) !void {
    try self.inventory.draw(camera);
    const dim = CONSTANTS.CUBE.as(f32).as(rl.Vector2);
    if (self.animation) |_| {
        const pos = self.getWorldPos().as(rl.Vector2);
        rl.drawRectangleV(pos, dim, rl.Color.red);
        return;
    }

    const pos = utils.get_world_pos_from_grid(i32, self.current_pos, CONSTANTS.CUBE).as(rl.Vector2);
    rl.drawRectangleV(pos, dim, rl.Color.red);
}
