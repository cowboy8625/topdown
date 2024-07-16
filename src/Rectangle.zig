const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig");
const utils = @import("utils.zig");

pub fn Rectangle(comptime T: type) type {
    return extern struct {
        x: T,
        y: T,
        width: T,
        height: T,

        const Self = @This();

        pub fn init(x: T, y: T, width: T, height: T) Rectangle(T) {
            return .{ .x = x, .y = y, .width = width, .height = height };
        }

        pub fn from2vec2(point: Vector2(T), size: Vector2(T)) Rectangle(T) {
            return .{ .x = point.x, .y = point.y, .width = size.x, .height = size.y };
        }

        pub fn contains(self: Self, point: Vector2(T)) bool {
            return point.x >= self.x and point.x <= self.x + self.width and point.y >= self.y and point.y <= self.y + self.height;
        }

        pub fn eq(self: Self, other: Self) bool {
            return std.meta.eql(self, other);
        }

        pub fn as(self: Self, comptime U: type) Rectangle(U) {
            const x: U = utils.numberCast(T, U, self.x);
            const y: U = utils.numberCast(T, U, self.y);
            const width: U = utils.numberCast(T, U, self.width);
            const height: U = utils.numberCast(T, U, self.height);
            return .{ .x = x, .y = y, .width = width, .height = height };
        }

        pub fn asRaylibRectangle(self: Self) rl.Rectangle {
            const x: f32 = utils.numberCast(f32, T, self.x);
            const y: f32 = utils.numberCast(f32, T, self.y);
            const width: f32 = utils.numberCast(f32, T, self.width);
            const height: f32 = utils.numberCast(f32, T, self.height);
            return .{ .x = x, .y = y, .width = width, .height = height };
        }
    };
}
