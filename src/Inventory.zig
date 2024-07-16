const std = @import("std");
const rl = @import("raylib");
const CONSTANTS = @import("constants.zig");
const Allocator = std.mem.Allocator;
const BlockType = @import("BlockType.zig").BlockType;
const Vector2 = @import("Vector2.zig").Vector2;

const Self = @This();

items: std.ArrayList(BlockType),

pub fn init(alloc: Allocator) Self {
    const items = std.ArrayList(BlockType).init(alloc);
    return .{
        .items = items,
    };
}

pub fn deinit(self: *Self) void {
    self.items.deinit();
}

pub fn add(self: *Self, item: BlockType) !void {
    try self.items.append(item);
}

pub fn remove(self: *Self, index: usize) ?BlockType {
    if (index >= self.items.items.len) return null;
    return self.items.orderedRemove(index);
}

pub fn update(_: *Self) !void {}

pub fn draw(self: *const Self, camera: *rl.Camera2D) void {
    var pos = rl.getScreenToWorld2D(.{ .x = 0, .y = 0 }, camera.*);
    const size = CONSTANTS.CUBE.as(f32).add(10).asRaylibVector2();
    for (self.items.items) |item| {
        rl.drawRectangleV(
            pos,
            size,
            item.color(),
        );

        pos.x += size.x + 10;
    }
}
