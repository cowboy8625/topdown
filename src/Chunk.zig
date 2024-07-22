const std = @import("std");
const rl = @import("raylib");
const CONSTANTS = @import("constants.zig");
const utils = @import("utils.zig");
const cast = utils.cast;
const indexFromVec = utils.indexFromVec;
const Allocator = std.mem.Allocator;
const BlockType = @import("BlockType.zig").BlockType;
const BlockMap = std.AutoHashMap(Vector2(i32), BlockType);
const Vector2 = @import("Vector2.zig").Vector2;
const DrawOptions = @import("World.zig").DrawOptions;

pub const SIZE = 32;
pub const VOLUME = SIZE * SIZE;

const Self = @This();

const ChunkData = struct {
    x: i32,
    y: i32,
    data: [VOLUME]BlockType,
};

pos: Vector2(i32),
blocks: [VOLUME]BlockType,
alloc: Allocator,
isDirty: bool = false,

pub fn init(alloc: Allocator, pos: Vector2(i32)) !*Self {
    return loadChunk(alloc, pos) catch try generateChunk(alloc, pos);
}

fn loadChunk(alloc: Allocator, pos: Vector2(i32)) !*Self {
    const name_buffer = try alloc.alloc(u8, 32);
    defer alloc.free(name_buffer);
    const name = try std.fmt.bufPrint(name_buffer, "data/chunk_{d}_{d}.json", .{ pos.x, pos.y });
    var file = try std.fs.cwd().openFile(name, .{});
    defer file.close();

    // Not sure what jsonParse needs string or Scanner;
    const string = try alloc.alloc(u8, try file.getEndPos());
    defer alloc.free(string);
    _ = try file.readAll(string);

    return try jsonParse(alloc, string, .{});
}

fn generateChunk(alloc: Allocator, pos: Vector2(i32)) !*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    const dimension = Vector2(i32).init(SIZE, SIZE);
    const world_pos = pos.mul(dimension);

    const image = rl.genImagePerlinNoise(
        dimension.x,
        dimension.y,
        world_pos.x,
        world_pos.y,
        1.0,
    );
    defer rl.unloadImage(image);

    var blocks = [_]BlockType{.Air} ** VOLUME;

    for (0..cast(usize, image.width)) |x| {
        for (0..cast(usize, image.height)) |y| {
            const pixel = Vector2(usize).init(x, y).as(i32);
            const color = rl.getImageColor(image, pixel.x, pixel.y);
            const r: bool = color.r > 128;
            const g: bool = color.g > 128;
            const b: bool = color.b > 128;
            const a: bool = color.a > 128;
            if (!(r and g and b and a)) {
                continue;
            }

            const index = y * SIZE + x;
            if (color.g > 195 and color.b > 195 and color.a > 195) {
                blocks[index] = .Grass;
            } else if (color.r > 185 and color.g > 185 and color.b > 185 and color.a > 185) {
                blocks[index] = .Dirt;
            } else {
                blocks[index] = .Stone;
            }
        }
    }

    self.* = .{
        .pos = pos,
        .blocks = blocks,
        .alloc = alloc,
    };

    return self;
}

pub fn deinit(self: *Self) void {
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
    const chunk_data = ChunkData{
        .x = self.pos.x,
        .y = self.pos.y,
        .data = self.blocks,
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

    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    self.* = .{
        .pos = Vector2(i32).init(chunk.x, chunk.y),
        .blocks = chunk.data,
        .alloc = allocator,
    };

    return self;
}

pub fn setBlock(self: *Self, pos: Vector2(i32), block: BlockType) BlockType {
    const index = indexFromVec(i32, pos, SIZE);
    const old = self.blocks[index];
    self.blocks[index] = block;
    self.isDirty = true;
    return old;
}

pub fn getBlock(self: *const Self, pos: Vector2(i32)) BlockType {
    const index = indexFromVec(i32, pos, SIZE);
    return self.blocks[index];
}

pub fn drawOutline(self: *const Self) void {
    const size = Vector2(i32).init(SIZE, SIZE);
    const world_chunk_pos = self.pos.mul(size).mul(CONSTANTS.CUBE).as(f32);
    const pos = world_chunk_pos.as(i32);
    const dim = CONSTANTS.CUBE.mul(size);
    rl.drawRectangleLines(pos.x, pos.y, dim.x, dim.y, rl.Color.red);
}

pub fn getBlockPosFromIndex(index: usize) Vector2(i32) {
    const x: i32 = @intCast(@mod(index, SIZE));
    const y: i32 = @intCast(@divFloor(index, SIZE));
    return Vector2(i32).init(x, y);
}

pub fn draw(self: *const Self, options: DrawOptions) void {
    for (0.., self.blocks) |i, block| {
        const local_pos = Self.getBlockPosFromIndex(i);
        const pos = self.pos.mul(SIZE).add(local_pos);
        block.draw(
            pos.mul(CONSTANTS.CUBE).as(f32),
        );
    }
    const is_even = @mod(self.pos.x, 2) == 0 and @mod(self.pos.y, 2) == 0;
    if (options.showChunkBoards and is_even) {
        self.drawOutline();
    }
}
