const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const CONSTANTS = @import("constants.zig");
const Allocator = std.mem.Allocator;
const BlockType = @import("BlockType.zig").BlockType;
const Vector2 = @import("Vector2.zig").Vector2;

const Stack = struct {
    item: BlockType,
    count: u8,
};

pub const MAX_HOTBAR_SLOTS = 9;
pub const MAX_STACK_SIZE = 5;

const Self = @This();

hotbarTexture: rl.Texture2D,
items: std.ArrayList(Stack),
alloc: Allocator,

pub fn init(alloc: Allocator) Self {
    const items = std.ArrayList(Stack).init(alloc);
    return .{
        .hotbarTexture = rl.loadTexture("assets/hotbar.png"),
        .items = items,
        .alloc = alloc,
    };
}

pub fn deinit(self: *Self) void {
    rl.unloadTexture(self.hotbarTexture);
    self.items.deinit();
}

pub fn isInventoryFull(self: *const Self) bool {
    for (self.items.items) |stack| {
        if (stack.count < MAX_STACK_SIZE) return false;
    }
    if (self.items.items.len < MAX_HOTBAR_SLOTS) return false;
    return true;
}

pub fn add(self: *Self, item: BlockType) !void {
    for (self.items.items) |*stack| {
        if (stack.item == item and stack.count < MAX_STACK_SIZE) {
            stack.count += 1;
            return;
        }
    }
    if (self.items.items.len >= MAX_HOTBAR_SLOTS) return;
    try self.items.append(.{ .item = item, .count = 1 });
}

pub fn remove(self: *Self, index: usize) ?BlockType {
    if (index >= self.items.items.len) return null;
    const stack = &self.items.items[index];
    if (stack.count == 1) {
        const block = stack.item;
        _ = self.items.orderedRemove(index);
        return block;
    }
    stack.count -= 1;
    return stack.item;
}

pub fn update(_: *Self) !void {}

pub fn drawHotbar(self: *const Self, base_pos: rl.Vector2, scale: f32) rl.Vector2 {
    const width = cast(f32, self.hotbarTexture.width) * scale;
    const height = cast(f32, self.hotbarTexture.height) * scale;
    const pos = base_pos.subtract(.{ .x = width / 2, .y = height });
    rl.drawTextureEx(self.hotbarTexture, pos, 0, scale, rl.Color.white);
    return pos;
}

pub fn draw(self: *const Self, selectedSlot: usize, camera: *rl.Camera2D) !void {
    const scale = 1;
    const font_size = 10 * scale;
    const pixels_between_slots = 10 * scale;
    const center_screen = utils.getCenterScreen().as(rl.Vector2);
    const size: rl.Vector2 = .{ .x = 32 * scale, .y = 32 * scale };
    var pos = rl.getScreenToWorld2D(center_screen, camera.*);
    pos = pos.add(.{ .x = 0, .y = center_screen.y });

    pos = self.drawHotbar(pos, scale);

    pos = pos.add(.{ .x = 10 * scale, .y = 10 * scale });
    const hotbar_pos = pos;
    const buf = try self.alloc.alloc(u8, 64);
    defer self.alloc.free(buf);

    // Draw items
    for (self.items.items) |stack| {
        rl.drawRectangleV(
            pos,
            size,
            stack.item.color(),
        );

        const text = try std.fmt.bufPrintZ(buf, "{}", .{stack.count});
        const text_size = rl.measureText(text, font_size);
        const x: i32 = @as(i32, @intFromFloat(pos.x + size.x)) - (text_size + 2);
        const y: i32 = @intFromFloat(pos.y + ((size.y / 3) * 2));
        rl.drawText(
            text,
            x,
            y,
            font_size,
            rl.Color.black,
        );

        pos.x += size.x + pixels_between_slots;
    }

    // Draw selected slot
    const line_thinkness = 2 * scale;
    const rect = rl.Rectangle{
        .x = (hotbar_pos.x + (size.x + pixels_between_slots) * cast(f32, selectedSlot)) - line_thinkness,
        .y = (hotbar_pos.y) - line_thinkness,
        .width = size.x + line_thinkness * 2,
        .height = size.y + line_thinkness * 2,
    };
    rl.drawRectangleLinesEx(
        rect,
        line_thinkness,
        rl.Color.black,
    );
}
