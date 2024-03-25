const std = @import("std");
const rl = @import("raylib.zig");
const Vector2 = rl.Vector2;

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
