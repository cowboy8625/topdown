const std = @import("std");
const rl = @import("raylib_zig");
const cast = std.math.cast;
const CONSTANTS = @import("constants.zig");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const BlockType = @import("BlockType.zig").BlockType;
const BlockMap = std.AutoHashMap(rl.Vector2(i32), BlockType);

pub const SIZE: i32 = 32;

const Self = @This();

pos: rl.Vector2(i32),
map: BlockMap,
alloc: Allocator,

pub fn init(alloc: Allocator, pos: rl.Vector2(i32)) !*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    var map = BlockMap.init(alloc);
    errdefer map.deinit();

    const dimension = rl.Vector2(i32).init(SIZE, SIZE);
    const world_pos = pos.mul(dimension);

    const image = rl.GenImagePerlinNoise(
        dimension.x,
        dimension.y,
        world_pos.x,
        world_pos.y,
        1.0,
    );
    defer rl.UnloadImage(image);

    for (0..cast(usize, image.width) orelse 0) |x| {
        for (0..cast(usize, image.height) orelse 0) |y| {
            const pixel = rl.Vector2(usize).init(x, y).as(i32);
            const color = rl.GetImageColorV(image, pixel);
            const r: bool = color.r > 128;
            const g: bool = color.g > 128;
            const b: bool = color.b > 128;
            const a: bool = color.a > 128;
            if (r and g and b and a) {
                try map.put(world_pos.add(pixel), .Stone);
            }
        }
    }

    self.* = .{
        .pos = pos,
        .map = map,
        .alloc = alloc,
    };

    return self;
}

pub fn deinit(self: *Self) void {
    self.map.deinit();
    self.alloc.destroy(self);
}

pub fn replaceBlock(self: *Self, pos: rl.Vector2(i32), block: BlockType) !void {
    try self.map.put(pos, block);
}

pub fn deleteBlock(self: *Self, pos: rl.Vector2(i32)) void {
    _ = self.map.remove(pos);
}

pub fn getBlock(self: *const Self, pos: rl.Vector2(i32)) ?BlockType {
    return self.map.get(pos);
}

pub fn draw(self: *const Self) void {
    const size = rl.Vector2(i32).init(SIZE, SIZE);
    var iter = self.map.iterator();
    while (iter.next()) |entry| {
        const block = entry.value_ptr.*;
        const block_pos = entry.key_ptr.*;
        block.draw(
            block_pos.mul(CONSTANTS.CUBE).as(f32),
        );
        // Outliner
        // rl.DrawRectangleLinesV(block_pos.mul(CONSTANTS.CUBE), CONSTANTS.CUBE, rl.Color.blue());
    }
    const world_chunk_pos = self.pos.mul(size).mul(CONSTANTS.CUBE).as(f32);
    rl.DrawRectangleLinesV(world_chunk_pos.as(i32), CONSTANTS.CUBE.mul(size), rl.Color.red());
}

fn getWorldPosOfChunk(position: rl.Vector2(i32)) rl.Vector2(f32) {
    return position.mul(.{ .x = SIZE, .y = SIZE }).mul(CONSTANTS.CUBE).as(f32);
}
