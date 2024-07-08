const std = @import("std");
const rl = @import("raylib_zig");
const BlockType = @import("BlockType.zig").BlockType;
const Chunk = @import("Chunk.zig");

const Self = @This();

pub const ChunkId = enum {
    One,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
};

const ChunkMap = std.EnumArray(ChunkId, Chunk);

map: ChunkMap,

pub fn init(alloc: std.mem.Allocator) !Self {
    return .{
        .map = ChunkMap.init(.{
            .One = try Chunk.init(alloc, .{ .x = -1, .y = -1 }),
            .Two = try Chunk.init(alloc, .{ .x = 0, .y = -1 }),
            .Three = try Chunk.init(alloc, .{ .x = 1, .y = -1 }),
            .Four = try Chunk.init(alloc, .{ .x = -1, .y = 0 }),
            .Five = try Chunk.init(alloc, .{ .x = 0, .y = 0 }),
            .Six = try Chunk.init(alloc, .{ .x = 1, .y = 0 }),
            .Seven = try Chunk.init(alloc, .{ .x = -1, .y = 1 }),
            .Eight = try Chunk.init(alloc, .{ .x = 0, .y = 1 }),
            .Nine = try Chunk.init(alloc, .{ .x = 1, .y = 1 }),
        }),
    };
}

pub fn deinit(self: *Self) void {
    var iter = self.map.iterator();
    while (iter.next()) |entry| {
        entry.value.*.deinit();
    }
}

pub fn contains(self: *Self, pos: rl.Vector2(i32)) bool {
    const chunk = self.getChunkFromPos(pos);
    return chunk.map.contains(pos);
}

pub fn replaceBlock(self: *Self, pos: rl.Vector2(i32), block: BlockType) !void {
    const chunk = self.getChunkFromPos(pos);
    try chunk.replaceBlock(pos, block);
}

pub fn deleteBlock(self: *Self, pos: rl.Vector2(i32)) !void {
    const chunk = self.getChunkFromPos(pos);
    chunk.deleteBlock(pos);
}

fn getChunkFromPos(self: *Self, pos: rl.Vector2(i32)) *Chunk {
    var iter = self.map.iterator();
    const size = rl.Vector2(i32).init(Chunk.SIZE, Chunk.SIZE);
    const p = pos.div(size);
    while (iter.next()) |*entry| {
        const chunk_pos = entry.value.*.pos;
        if (chunk_pos.x == p.x and chunk_pos.y == p.y) {
            return entry.value;
        }
    }
    unreachable;
}

pub fn update(_: *Self) void {}

pub fn draw(self: *Self) void {
    var iter = self.map.iterator();
    while (iter.next()) |entry| {
        entry.value.*.draw();
    }
}
