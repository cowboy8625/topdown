const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const CONSTANTS = @import("constants.zig");
const Allocator = std.mem.Allocator;
const BlockType = @import("BlockType.zig").BlockType;
const Vector2 = @import("Vector2.zig").Vector2;

const Stack = struct {
    item: BlockType,
    count: u8,
};

const Self = @This();

items: std.ArrayList(Stack),
alloc: Allocator,

pub fn init(alloc: Allocator) Self {
    const items = std.ArrayList(Stack).init(alloc);
    return .{
        .items = items,
        .alloc = alloc,
    };
}

pub fn deinit(self: *Self) void {
    self.items.deinit();
}

pub fn add(self: *Self, item: BlockType) !void {
    for (self.items.items) |*stack| {
        if (stack.item == item and stack.count < 64) {
            stack.count += 1;
            return;
        }
    }
    try self.items.append(.{ .item = item, .count = 1 });
}

pub fn remove(self: *Self, index: usize) ?BlockType {
    if (index >= self.items.items.len) return null;
    const stack = &self.items.items[index];
    if (stack.count == 1) {
        _ = self.items.orderedRemove(index);
        return stack.item;
    }
    stack.count -= 1;
    std.debug.print("removing {d}\n", .{stack.count});
    return stack.item;
}

pub fn update(_: *Self) !void {}

pub fn draw(self: *const Self, camera: *rl.Camera2D) !void {
    const center_screen = utils.getCenterScreen().as(rl.Vector2);
    const size = CONSTANTS.CUBE.as(f32).add(10).as(rl.Vector2);
    const y_offset = center_screen.y - 10 - size.y;
    var pos = rl.getScreenToWorld2D(center_screen.add(.{ .x = 0, .y = y_offset }), camera.*);
    const buf = try self.alloc.alloc(u8, 64);
    defer self.alloc.free(buf);
    for (self.items.items) |stack| {
        rl.drawRectangleV(
            pos,
            size,
            stack.item.color(),
        );

        const text = try std.fmt.bufPrintZ(buf, "{}", .{stack.count});
        rl.drawText(text, @intFromFloat(pos.x + size.x - 5), @intFromFloat(pos.y + size.y / 2), 10, rl.Color.orange);

        pos.x += size.x + 10;
    }
}
