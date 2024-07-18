const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");

pub fn Vector2(comptime T: type) type {
    return packed struct {
        x: T,
        y: T,

        const Self = @This();

        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            _: std.fmt.FormatOptions,
            out_stream: anytype,
        ) !void {
            if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
            try std.fmt.format(out_stream, "Vector2({d}, {d})", .{ self.x, self.y });
        }

        pub fn init(x: T, y: T) Vector2(T) {
            return .{ .x = x, .y = y };
        }

        pub fn fromRaylibVevtor2(vec: rl.Vector2) Vector2(T) {
            return .{ .x = vec.x, .y = vec.y };
        }

        pub fn isZero(self: Self) bool {
            return self.x == 0 and self.y == 0;
        }

        pub fn add(self: Self, other: anytype) Self {
            switch (@TypeOf(other)) {
                Self => {
                    return .{ .x = self.x + other.x, .y = self.y + other.y };
                },
                T, comptime_int => {
                    return .{ .x = self.x + other, .y = self.y + other };
                },
                else => @compileError("Unsupported type " ++ @typeName(@TypeOf(other))),
            }
        }

        pub fn sub(self: Self, other: Self) Self {
            switch (@TypeOf(other)) {
                Self => {
                    return .{ .x = self.x - other.x, .y = self.y - other.y };
                },
                T, comptime_int => {
                    return .{ .x = self.x + other, .y = self.y + other };
                },
                else => @compileError("Unsupported type " ++ @typeName(@TypeOf(other))),
            }
        }

        pub fn mul(self: Self, other: Self) Self {
            switch (@TypeOf(other)) {
                Self => {
                    return .{ .x = self.x * other.x, .y = self.y * other.y };
                },
                T, comptime_int => {
                    return .{ .x = self.x + other, .y = self.y + other };
                },
                else => @compileError("Unsupported type " ++ @typeName(@TypeOf(other))),
            }
        }

        pub fn div(self: Self, other: Self) Self {
            switch (@TypeOf(other)) {
                Self => {
                    return .{ .x = @divFloor(self.x, other.x), .y = @divFloor(self.y, other.y) };
                },
                T, comptime_int => {
                    return .{ .x = self.x + other, .y = self.y + other };
                },
                else => @compileError("Unsupported type " ++ @typeName(@TypeOf(other))),
            }
        }

        pub fn max(self: Self, other: Self) Self {
            return .{ .x = @max(self.x, other.x), .y = @max(self.y, other.y) };
        }

        pub fn min(self: Self, other: Self) Self {
            return .{ .x = @min(self.x, other.x), .y = @min(self.y, other.y) };
        }

        pub fn eq(self: Self, other: Self) bool {
            return std.meta.eql(self, other);
        }

        /// Returns a raylib Vector2 f32
        fn asRaylibVector2(self: Self) rl.Vector2 {
            const x: f32 = utils.numberCast(T, f32, self.x);
            const y: f32 = utils.numberCast(T, f32, self.y);
            return .{ .x = x, .y = y };
        }

        pub fn as(self: Self, comptime U: type) if (U == rl.Vector2) rl.Vector2 else Vector2(U) {
            switch (U) {
                rl.Vector2 => return self.asRaylibVector2(),
                else => {
                    const x: U = utils.numberCast(T, U, self.x);
                    const y: U = utils.numberCast(T, U, self.y);
                    return .{ .x = x, .y = y };
                },
            }
        }
    };
}

test "as rl.Vector2" {
    const vector = Vector2(i32).init(1, 2).as(rl.Vector2);
    const raylibVector = rl.Vector2.init(1, 2);
    try std.testing.expectEqualDeep(vector, raylibVector);
}
