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

pub fn update(self: *Self) !void {
    if (!self.isDirty) {
        return;
    }
    try self.saveChunkToFile();
}

fn saveChunkToFile(self: *Self) !void {
    const name_buffer = try self.alloc.alloc(u8, 32);
    defer self.alloc.free(name_buffer);
    const name = try std.fmt.bufPrint(name_buffer, "data/chunk_{d}_{d}.json", .{ self.pos.x, self.pos.y });
    var file = try std.fs.cwd().createFile(name, .{});
    defer file.close();

    const options = std.json.StringifyOptions{
        .whitespace = .indent_2,
    };

    try std.json.stringify(self, options, file.writer());

    self.isDirty = false;
}

pub fn jsonStringify(self: Self, stream: anytype) !void {
    const data = self.alloc.alloc(BlockData, self.map.count()) catch unreachable;
    defer self.alloc.free(data);
    var iter = self.map.iterator();
    var i: usize = 0;
    while (iter.next()) |entry| {
        data[i] = .{
            .x = entry.key_ptr.x,
            .y = entry.key_ptr.y,
            .blockType = entry.value_ptr.*,
        };
        i += 1;
    }
    const chunk_data = ChunkData{
        .x = self.pos.x,
        .y = self.pos.y,
        .data = data,
    };
    try stream.write(chunk_data);
}

pub fn jsonParse(allocator: Allocator, source: anytype, options: std.json.ParseOptions) !*Self {
    const parsed = std.json.parseFromSlice(ChunkData, allocator, source, options) catch |err| {
        std.debug.print("Error: {any}", .{err});
        return err;
    };
    defer parsed.deinit();
    const chunk = parsed.value;
    const chunk_pos = rl.Vector2(i32).init(chunk.x, chunk.y);

    var map = BlockMap.init(allocator);
    errdefer map.deinit();
    for (chunk.data) |data| {
        const pos = rl.Vector2(i32).init(data.x, data.y);
        try map.put(pos, data.blockType);
    }

    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    self.* = .{
        .pos = chunk_pos,
        .map = map,
        .alloc = allocator,
    };

    return self;
}

pub fn replaceBlock(self: *Self, pos: rl.Vector2(i32), block: BlockType) !void {
    try self.map.put(pos, block);
    self.isDirty = true;
}

pub fn deleteBlock(self: *Self, pos: rl.Vector2(i32)) void {
    _ = self.map.remove(pos);
    self.isDirty = true;
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
