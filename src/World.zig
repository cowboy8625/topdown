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

const ChunkMap = std.EnumArray(ChunkId, *Chunk);

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
    while (iter.next()) |*entry| {
        entry.value.*.deinit();
    }
}

pub fn isCollision(self: *Self, player: rl.Vector2(i32), direction: rl.Vector2(i32)) bool {
    const location = player.add(direction);
    return self.contains(location);
}

pub fn contains(self: *Self, pos: rl.Vector2(i32)) bool {
    const chunk = self.getChunkFromPos(pos) orelse return false;
    return chunk.value.map.contains(pos);
}

pub fn replaceBlock(self: *Self, pos: rl.Vector2(i32), block: BlockType) !void {
    const chunk = self.getChunkFromPos(pos) orelse return;
    try chunk.value.replaceBlock(pos, block);
}

pub fn deleteBlock(self: *Self, pos: rl.Vector2(i32)) !void {
    const chunk = self.getChunkFromPos(pos) orelse return;
    chunk.value.deleteBlock(pos);
}

fn getChunkFromPos(self: *Self, pos: rl.Vector2(i32)) ?struct { key: ChunkId, value: *Chunk } {
    var iter = self.map.iterator();
    const size = rl.Vector2(i32).init(Chunk.SIZE, Chunk.SIZE);
    const p = pos.div(size);
    while (iter.next()) |*entry| {
        const chunk_pos = entry.value.*.pos;
        if (chunk_pos.x == p.x and chunk_pos.y == p.y) {
            return .{ .key = entry.key, .value = entry.value.* };
        }
    }

    return null;
}

fn generateNextChunk(
    self: *Self,
    current: ChunkId,
    to: ChunkId,
    pos: rl.Vector2(i32),
) !struct { chunk: *Chunk, unload: bool } {
    const unload = switch (current) {
        .One => switch (to) {
            .Three, .Six, .Nine, .Seven, .Eight => true,
            else => false,
        },
        .Two => switch (to) {
            .Seven, .Eight, .Nine => true,
            else => false,
        },
        .Three => switch (to) {
            .One, .Four, .Seven, .Eight, .Nine => true,
            else => false,
        },
        .Four => switch (to) {
            .Three, .Six, .Nine => true,
            else => false,
        },
        .Six => switch (to) {
            .One, .Four, .Seven => true,
            else => false,
        },
        .Seven => switch (to) {
            .One, .Two, .Three, .Six, .Nine => true,
            else => false,
        },
        .Eight => switch (to) {
            .One, .Two, .Three => true,
            else => false,
        },
        .Nine => switch (to) {
            .Seven, .Four, .One, .Two, .Three => true,
            else => false,
        },
        else => false,
    };

    const new = switch (current) {
        .One => switch (to) {
            // FIXME: all these need to be adjusted
            .One, .Two, .Three, .Four, .Seven => try createNewChunk(self.alloc, to, pos),
            .Five => self.map.get(.One),
            .Six => self.map.get(.Two),
            .Eight => self.map.get(.Four),
            .Nine => self.map.get(.Five),
        },
        .Two => switch (to) {
            .One, .Two, .Three => try createNewChunk(self.alloc, to, pos),
            .Four => self.map.get(.One),
            .Five => self.map.get(.Two),
            .Six => self.map.get(.Three),
            .Seven => self.map.get(.Four),
            .Eight => self.map.get(.Five),
            .Nine => self.map.get(.Six),
        },
        .Three => switch (to) {
            .One, .Two, .Three, .Six, .Nine => try createNewChunk(self.alloc, to, pos),
            .Four => self.map.get(.Two),
            .Five => self.map.get(.Three),
            .Seven => self.map.get(.Five),
            .Eight => self.map.get(.Six),
        },
        .Four => switch (to) {
            .One, .Four, .Seven => try createNewChunk(self.alloc, to, pos),
            .Two => self.map.get(.One),
            .Three => self.map.get(.Two),
            .Five => self.map.get(.Four),
            .Six => self.map.get(.Five),
            .Eight => self.map.get(.Seven),
            .Nine => self.map.get(.Eight),
        },
        .Six => switch (to) {
            .Three, .Six, .Nine => try createNewChunk(self.alloc, to, pos),
            .Two => self.map.get(.Three),
            .One => self.map.get(.Two),
            .Five => self.map.get(.Six),
            .Four => self.map.get(.Five),
            .Eight => self.map.get(.Nine),
            .Seven => self.map.get(.Eight),
        },
        .Seven => switch (to) {
            .One, .Four, .Seven, .Eight, .Nine => try createNewChunk(self.alloc, to, pos),
            .Two => self.map.get(.Four),
            .Three => self.map.get(.Five),
            .Five => self.map.get(.Seven),
            .Six => self.map.get(.Eight),
        },
        .Eight => switch (to) {
            .Seven, .Eight, .Nine => try createNewChunk(self.alloc, to, pos),
            .One => self.map.get(.Four),
            .Two => self.map.get(.Five),
            .Three => self.map.get(.Six),
            .Four => self.map.get(.Seven),
            .Five => self.map.get(.Eight),
            .Six => self.map.get(.Nine),
        },
        .Nine => switch (to) {
            .Three, .Six, .Seven, .Eight, .Nine => try createNewChunk(self.alloc, to, pos),
            .One => self.map.get(.Five),
            .Two => self.map.get(.Six),
            .Four => self.map.get(.Eight),
            .Five => self.map.get(.Nine),
        },
        else => unreachable,
    };

    return .{ .chunk = new, .unload = unload };
}

pub fn update(self: *Self, pos: rl.Vector2(i32)) !void {
    const chunk = self.getChunkFromPos(pos) orelse return;
    if (chunk.key == .Five) {
        return;
    }

    var new_chunks = std.EnumArray(ChunkId, *Chunk).initUndefined();
    var chunks_to_unload = std.EnumArray(ChunkId, bool).initFill(false);

    var i = new_chunks.iterator();
    while (i.next()) |*entry| {
        const next = try self.generateNextChunk(chunk.key, entry.key, chunk.value.pos);
        entry.value.* = next.chunk;
        chunks_to_unload.set(entry.key, next.unload);
    }

    var iter = chunks_to_unload.iterator();
    while (iter.next()) |unload| {
        if (unload.value.*) {
            self.map.get(unload.key).deinit();
        }
    }

    var new_iter = new_chunks.iterator();
    while (new_iter.next()) |entry| {
        self.map.set(entry.key, entry.value.*);
    }
}

pub fn draw(self: *Self) void {
    var iter = self.map.iterator();
    while (iter.next()) |entry| {
        entry.value.*.draw();
    }
}

fn createNewChunk(alloc: Allocator, id: ChunkId, pos: rl.Vector2(i32)) !*Chunk {
    return try Chunk.init(alloc, getChunkPosFromBase(id, pos));
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
