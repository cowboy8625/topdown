const std = @import("std");
const rl = @import("raylib");
const Vector2 = @import("Vector2.zig").Vector2;

const Self = @This();
start: Vector2(f32),
end: Vector2(f32),
current: Vector2(f32),
time: f32,
elapsedTime: f32,
duration: f32,

pub fn isDone(self: Self) bool {
    return self.elapsedTime >= self.duration;
}

pub fn update(self: *Self, deltaTime: f32) void {
    self.elapsedTime += deltaTime; // Update the elapsed time

    var interpolationFactor = self.elapsedTime / self.duration;

    if (interpolationFactor > 1.0) {
        interpolationFactor = 1.0;
    }

    // Linear interpolation (LERP)
    self.current.x = self.start.x + interpolationFactor * (self.end.x - self.start.x);
    self.current.y = self.start.y + interpolationFactor * (self.end.y - self.start.y);
}
