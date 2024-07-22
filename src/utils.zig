const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig").Vector2;
const CONSTANTS = @import("constants.zig");

// Takes a grid position Vector(i32) and returns the world position as Vector2(f32)
pub fn get_world_pos_from_grid(comptime T: type, pos: Vector2(T), cell: Vector2(T)) Vector2(f32) {
    return pos.mul(cell).as(f32);
}

pub fn get_top_left_coner_of_grid_on_screen(player: Vector2(i32), screen: Vector2(i32)) Vector2(i32) {
    return player.sub(screen.div(CONSTANTS.CUBE).div(.{ .x = 2, .y = 2 }));
}

pub fn genEnumFromStringArray(comptime args: []const []const u8) type {
    var decls = [_]std.builtin.Type.Declaration{};
    var enumDecls: [args.len]std.builtin.Type.EnumField = undefined;
    inline for (args, 0..) |field, i| {
        enumDecls[i] = .{ .name = field ++ "", .value = i };
    }

    return @Type(.{
        .Enum = .{
            .tag_type = std.math.IntFittingRange(0, args.len - 1),
            .fields = &enumDecls,
            .decls = &decls,
            .is_exhaustive = true,
        },
    });
}

pub fn numberCast(comptime T: type, comptime U: type, num: T) U {
    if (T == U) return num;
    return switch (@typeInfo(T)) {
        .Int => if (@typeInfo(U) == .Float) @as(U, @floatFromInt(num)) else @as(U, @intCast(num)),
        .Float => if (@typeInfo(U) == .Int) @as(U, @intFromFloat(num)) else @as(U, @floatCast(num)),
        else => @compileError("Unsupported type"),
    };
}

pub fn cast(comptime T: type, item: anytype) T {
    switch (@typeInfo(@TypeOf(item))) {
        .Int, .Float => return numberCast(@TypeOf(item), T, item),
        else => @compileError("Unsupported type"),
    }
}

fn snapToGrid(vec: Vector2(f32), cell: Vector2(f32)) Vector2(f32) {
    return .{ .x = @floor(vec.x / cell.x) * cell.x, .y = @floor(vec.y / cell.y) * cell.y };
}

pub fn dbg(item: anytype) @TypeOf(item) {
    std.debug.print("{any}\n", .{item});
    return item;
}

pub fn getCenterScreen() Vector2(f32) {
    return .{ .x = cast(f32, rl.getScreenWidth()) / 2, .y = cast(f32, rl.getScreenHeight()) / 2 };
}

pub fn indexFromVec(comptime T: type, pos: Vector2(T), cell: i32) usize {
    const p = pos.as(i32);
    var is_neg = false;
    const chunkX = @divFloor(p.x, cell);
    const chunkY = @divFloor(p.y, cell);
    if (chunkX < 0 or chunkY < 0) {
        is_neg = true;
    }
    const localX = @mod(p.x, cell);
    const localY = @mod(p.y, cell);
    return indexFromCord(localX, localY, cell, cell, is_neg);
}

pub fn indexFromCord(x: i32, y: i32, w: i32, h: i32, is_neg: bool) usize {
    if (is_neg) return @intCast((w * h) - 1);
    const xx = if (x < 0) w + x - 1 else x;
    const yy = if (y < 0) h + y - 1 else y;
    return cast(usize, yy * w + xx);
}
