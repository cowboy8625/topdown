const std = @import("std");
const Allocator = std.mem.Allocator;
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
alloc: Allocator,

pub fn init(alloc: Allocator) !Self {
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
        .alloc = alloc,
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
    return chunk.value.map.contains(pos);
}

pub fn replaceBlock(self: *Self, pos: rl.Vector2(i32), block: BlockType) !void {
    const chunk = self.getChunkFromPos(pos);
    try chunk.value.replaceBlock(pos, block);
}

pub fn deleteBlock(self: *Self, pos: rl.Vector2(i32)) !void {
    const chunk = self.getChunkFromPos(pos);
    chunk.value.deleteBlock(pos);
}

fn getChunkFromPos(self: *Self, pos: rl.Vector2(i32)) struct { key: ChunkId, value: *Chunk } {
    var iter = self.map.iterator();
    const size = rl.Vector2(i32).init(Chunk.SIZE, Chunk.SIZE);
    const p = pos.div(size);
    while (iter.next()) |*entry| {
        const chunk_pos = entry.value.*.pos;
        if (chunk_pos.x == p.x and chunk_pos.y == p.y) {
            return .{ .key = entry.key, .value = entry.value };
        }
    }
    unreachable;
}

fn unloadChunks(self: *Self, chunk_ids: []const ChunkId) void {
    for (chunk_ids) |chunk_id| {
        var chunk = self.map.get(chunk_id);
        chunk.deinit();
    }
}

fn generateChunks(self: *Self, chunk_ids: []const ChunkId) !void {
    const base = self.map.get(.Five).pos;
    for (chunk_ids) |chunk_id| {
        const chunk = self.map.getPtr(chunk_id);
        const pos = getChunkPosFromBase(chunk_id, base);
        chunk.* = try Chunk.init(chunk.alloc, pos);
    }
}

fn moveChunk(self: *Self, from: ChunkId, to: ChunkId) void {
    const from_chunk = self.map.getPtr(from);
    const to_chunk = self.map.getPtr(to);
    const temp = to_chunk.*;
    to_chunk.* = from_chunk.*;
    from_chunk.* = temp;
}

pub fn update(self: *Self, pos: rl.Vector2(i32)) !void {
    const chunk = self.getChunkFromPos(pos);
    if (chunk.key == .Five) {
        return;
    }

    var iter = self.map.iterator();
    while (iter.next()) |entry| {
        entry.value.*.deinit();
    }

    const x = chunk.value.pos.x;
    const y = chunk.value.pos.y;

    self.map = ChunkMap.init(.{
        .One = try Chunk.init(self.alloc, .{ .x = -1 + x, .y = -1 + y }),
        .Two = try Chunk.init(self.alloc, .{ .x = 0 + x, .y = -1 + y }),
        .Three = try Chunk.init(self.alloc, .{ .x = 1 + x, .y = -1 + y }),
        .Four = try Chunk.init(self.alloc, .{ .x = -1 + x, .y = 0 + y }),
        .Five = try Chunk.init(self.alloc, .{ .x = 0 + x, .y = 0 + y }),
        .Six = try Chunk.init(self.alloc, .{ .x = 1 + x, .y = 0 + y }),
        .Seven = try Chunk.init(self.alloc, .{ .x = -1 + x, .y = 1 + y }),
        .Eight = try Chunk.init(self.alloc, .{ .x = 0 + x, .y = 1 + y }),
        .Nine = try Chunk.init(self.alloc, .{ .x = 1 + x, .y = 1 + y }),
    });
}

pub fn draw(self: *Self) void {
    var iter = self.map.iterator();
    while (iter.next()) |entry| {
        entry.value.*.draw();
    }
}

fn getChunkPosFromBase(chunk_id: ChunkId, pos: rl.Vector2(i32)) rl.Vector2(i32) {
    const offset: rl.Vector2(i32) = switch (chunk_id) {
        .One => .{ .x = -1, .y = -1 },
        .Two => .{ .x = 0, .y = -1 },
        .Three => .{ .x = 1, .y = -1 },
        .Four => .{ .x = -1, .y = 0 },
        .Five => .{ .x = 0, .y = 0 },
        .Six => .{ .x = 1, .y = 0 },
        .Seven => .{ .x = -1, .y = 1 },
        .Eight => .{ .x = 0, .y = 1 },
        .Nine => .{ .x = 1, .y = 1 },
    };

    return pos.add(offset);
}
