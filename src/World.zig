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
            return .{ .key = entry.key, .value = entry.value.* };
        }
    }
    unreachable;
}

fn generateNextChunk(
    self: *Self,
    current: ChunkId,
    to: ChunkId,
    pos: rl.Vector2(i32),
    out: *std.EnumArray(ChunkId, bool),
) !*Chunk {
    switch (current) {
        .One => switch (to) {
            .One, .Two, .Three, .Four, .Seven => out.set(to, true),
            else => {},
        },
        .Two => switch (to) {
            .One, .Two, .Three => out.set(to, true),
            else => {},
        },
        .Three => switch (to) {
            .One, .Two, .Three, .Six, .Nine => out.set(to, true),
            else => {},
        },
        .Four => {},
        .Five => {},
        .Six => {},
        .Seven => {},
        .Eight => {},
        .Nine => {},
    }
    // This function needs to return the chunk that will be generated next weather it be a new
    // or old chunk.  Chunks are now pointers.  We also need to skip deinit'ing the chunks that
    // are not being generated.
    // 1 | 2 | 3
    // 4 | 5 | 6
    // 7 | 8 | 9
    return switch (current) {
        .One => switch (to) {
            .One, .Two, .Three, .Four, .Seven => try Chunk.init(self.alloc, .{ .x = -1 + pos.x, .y = -1 + pos.y }),
            .Five => self.map.get(.One),
            .Six => self.map.get(.Two),
            .Eight => self.map.get(.Four),
            .Nine => self.map.get(.Five),
        },
        .Two => switch (to) {
            .One, .Two, .Three => try Chunk.init(self.alloc, .{ .x = 0 + pos.x, .y = -1 + pos.y }),
            .Four => self.map.get(.One),
            .Five => self.map.get(.Two),
            .Six => self.map.get(.Three),
            .Seven => self.map.get(.Four),
            .Eight => self.map.get(.Five),
            .Nine => self.map.get(.Six),
        },
        .Three => switch (to) {
            .One, .Two, .Three, .Six, .Nine => try Chunk.init(self.alloc, .{ .x = 1 + pos.x, .y = -1 + pos.y }),
            .Four => self.map.get(.Two),
            .Five => self.map.get(.Three),
            .Seven => self.map.get(.Five),
            .Eight => self.map.get(.Six),
        },
        .Four => unreachable,
        .Five => unreachable,
        .Six => unreachable,
        .Seven => unreachable,
        .Eight => unreachable,
        .Nine => unreachable,
    };
}

pub fn update(self: *Self, pos: rl.Vector2(i32)) !void {
    const chunk = self.getChunkFromPos(pos);
    if (chunk.key == .Five) {
        return;
    }

    var chunks_to_unload = std.EnumArray(ChunkId, bool).init(.{
        .One = false,
        .Two = false,
        .Three = false,
        .Four = false,
        .Five = false,
        .Six = false,
        .Seven = false,
        .Eight = false,
        .Nine = false,
    });

    const one = try self.generateNextChunk(chunk.key, .One, chunk.value.pos, &chunks_to_unload);
    const two = try self.generateNextChunk(chunk.key, .Two, chunk.value.pos, &chunks_to_unload);
    const three = try self.generateNextChunk(chunk.key, .Three, chunk.value.pos, &chunks_to_unload);
    const four = try self.generateNextChunk(chunk.key, .Four, chunk.value.pos, &chunks_to_unload);
    const five = try self.generateNextChunk(chunk.key, .Five, chunk.value.pos, &chunks_to_unload);
    const six = try self.generateNextChunk(chunk.key, .Six, chunk.value.pos, &chunks_to_unload);
    const seven = try self.generateNextChunk(chunk.key, .Seven, chunk.value.pos, &chunks_to_unload);
    const eight = try self.generateNextChunk(chunk.key, .Eight, chunk.value.pos, &chunks_to_unload);
    const nine = try self.generateNextChunk(chunk.key, .Nine, chunk.value.pos, &chunks_to_unload);

    var iter = chunks_to_unload.iterator();
    while (iter.next()) |unload| {
        if (unload.value.*) {
            self.map.get(unload.key).deinit();
            std.debug.print("{any}: {any}\n", .{ unload.key, unload.value.* });
        }
    }

    self.map.set(.One, one);
    self.map.set(.Two, two);
    self.map.set(.Three, three);
    self.map.set(.Four, four);
    self.map.set(.Five, five);
    self.map.set(.Six, six);
    self.map.set(.Seven, seven);
    self.map.set(.Eight, eight);
    self.map.set(.Nine, nine);
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
