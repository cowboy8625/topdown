const std = @import("std");
const inner = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});
const utils = @import("utils.zig");

pub const Camera2D = inner.Camera2D;
pub const Image = inner.Image;

pub const FLAG_WINDOW_RESIZABLE = inner.FLAG_WINDOW_RESIZABLE;
pub const LOG_NONE = inner.LOG_NONE;
pub const SetConfigFlags = inner.SetConfigFlags;
pub const SetTraceLogLevel = inner.SetTraceLogLevel;

pub const Color = struct {
    const Self = @This();

    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn black() Self {
        return .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    }
    pub fn white() Self {
        return .{ .r = 255, .g = 255, .b = 255, .a = 255 };
    }
    pub fn lightGray() Self {
        return .{ .r = 200, .g = 200, .b = 200, .a = 255 };
    }
    pub fn gray() Self {
        return .{ .r = 130, .g = 130, .b = 130, .a = 255 };
    }
    pub fn darkGray() Self {
        return .{ .r = 80, .g = 80, .b = 80, .a = 255 };
    }
    pub fn yellow() Self {
        return .{ .r = 253, .g = 249, .b = 0, .a = 255 };
    }
    pub fn gold() Self {
        return .{ .r = 255, .g = 203, .b = 0, .a = 255 };
    }
    pub fn orange() Self {
        return .{ .r = 255, .g = 161, .b = 0, .a = 255 };
    }
    pub fn pink() Self {
        return .{ .r = 255, .g = 109, .b = 194, .a = 255 };
    }
    pub fn red() Self {
        return .{ .r = 230, .g = 41, .b = 55, .a = 255 };
    }
    pub fn maroon() Self {
        return .{ .r = 190, .g = 33, .b = 55, .a = 255 };
    }
    pub fn green() Self {
        return .{ .r = 0, .g = 228, .b = 48, .a = 255 };
    }
    pub fn lime() Self {
        return .{ .r = 0, .g = 158, .b = 47, .a = 255 };
    }
    pub fn darkGreen() Self {
        return .{ .r = 0, .g = 117, .b = 44, .a = 255 };
    }
    pub fn skyBlue() Self {
        return .{ .r = 102, .g = 191, .b = 255, .a = 255 };
    }
    pub fn blue() Self {
        return .{ .r = 0, .g = 121, .b = 241, .a = 255 };
    }
    pub fn darkBlue() Self {
        return .{ .r = 0, .g = 82, .b = 172, .a = 255 };
    }
    pub fn purple() Self {
        return .{ .r = 200, .g = 122, .b = 255, .a = 255 };
    }
    pub fn violet() Self {
        return .{ .r = 135, .g = 60, .b = 190, .a = 255 };
    }
    pub fn darkPurple() Self {
        return .{ .r = 112, .g = 31, .b = 126, .a = 255 };
    }
    pub fn beige() Self {
        return .{ .r = 211, .g = 176, .b = 131, .a = 255 };
    }
    pub fn brown() Self {
        return .{ .r = 127, .g = 106, .b = 79, .a = 255 };
    }
    pub fn darkBrown() Self {
        return .{ .r = 76, .g = 63, .b = 47, .a = 255 };
    }
    pub fn blank() Self {
        return .{ .r = 0, .g = 0, .b = 0, .a = 0 };
    }
    pub fn magenta() Self {
        return .{ .r = 255, .g = 0, .b = 255, .a = 255 };
    }
    pub fn rayWhite() Self {
        return .{ .r = 245, .g = 245, .b = 245, .a = 255 };
    }

    pub fn init(r: u8, g: u8, b: u8, a: u8) Self {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn fromRaylibColor(color: inner.Color) Self {
        return .{
            .r = color.r,
            .g = color.g,
            .b = color.b,
            .a = color.a,
        };
    }

    pub fn asRaylibColor(self: Self) inner.Color {
        return .{
            .r = self.r,
            .g = self.g,
            .b = self.b,
            .a = self.a,
        };
    }

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        _: std.fmt.FormatOptions,
        out_stream: anytype,
    ) !void {
        if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);
        var color: []const u8 = undefined;
        if (std.meta.eql(self, Self.black())) {
            color = "Black";
        } else if (std.meta.eql(self, Self.white())) {
            color = "White";
        } else if (std.meta.eql(self, Self.lightGray())) {
            color = "Lightgray";
        } else if (std.meta.eql(self, Self.gray())) {
            color = "Gray";
        } else if (std.meta.eql(self, Self.darkGray())) {
            color = "Darkgray";
        } else if (std.meta.eql(self, Self.yellow())) {
            color = "Yellow";
        } else if (std.meta.eql(self, Self.gold())) {
            color = "Gold";
        } else if (std.meta.eql(self, Self.orange())) {
            color = "Orange";
        } else if (std.meta.eql(self, Self.pink())) {
            color = "Pink";
        } else if (std.meta.eql(self, Self.red())) {
            color = "Red";
        } else if (std.meta.eql(self, Self.maroon())) {
            color = "Maroon";
        } else if (std.meta.eql(self, Self.Green())) {
            color = "Green";
        } else if (std.meta.eql(self, Self.lime())) {
            color = "Lime";
        } else if (std.meta.eql(self, Self.darkGreen())) {
            color = "Darkgreen";
        } else if (std.meta.eql(self, Self.skyBlue())) {
            color = "Skyblue";
        } else if (std.meta.eql(self, Self.blue())) {
            color = "Blue";
        } else if (std.meta.eql(self, Self.darkBlue())) {
            color = "Darkblue";
        } else if (std.meta.eql(self, Self.purple())) {
            color = "Purple";
        } else if (std.meta.eql(self, Self.violet())) {
            color = "Violet";
        } else if (std.meta.eql(self, Self.darkPurple())) {
            color = "Darkpurple";
        } else if (std.meta.eql(self, Self.beige())) {
            color = "Beige";
        } else if (std.meta.eql(self, Self.brown())) {
            color = "Brown";
        } else if (std.meta.eql(self, Self.darkBrown())) {
            color = "Darkbrown";
        } else if (std.meta.eql(self, Self.blank())) {
            color = "Blank";
        } else if (std.meta.eql(self, Self.magenta())) {
            color = "Magenta";
        } else if (std.meta.eql(self, Self.rayWhite())) {
            color = "Raywhite";
        } else {
            return try std.fmt.format(
                out_stream,
                "Color(r: {d}, g: {d}, b: {d}, a: {d})",
                .{
                    self.r,
                    self.g,
                    self.b,
                    self.a,
                },
            );
        }
        try std.fmt.format(out_stream, "{s}", .{color});
    }
};

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

        pub fn fromRaylibVevtor2(vec: inner.Vector2) Vector2(T) {
            return .{ .x = vec.x, .y = vec.y };
        }

        pub fn as(self: Self, comptime U: type) Vector2(U) {
            const x: U = utils.numberCast(T, U, self.x);
            const y: U = utils.numberCast(T, U, self.y);
            return .{ .x = x, .y = y };
        }

        pub fn add(self: Self, other: Self) Self {
            return .{ .x = self.x + other.x, .y = self.y + other.y };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{ .x = self.x - other.x, .y = self.y - other.y };
        }

        pub fn mul(self: Self, other: Self) Self {
            return .{ .x = self.x * other.x, .y = self.y * other.y };
        }

        pub fn div(self: Self, other: Self) Self {
            return .{ .x = @divFloor(self.x, other.x), .y = @divFloor(self.y, other.y) };
        }

        pub fn divFromNum(self: Self, comptime other: comptime_int) Self {
            return .{ .x = @divFloor(self.x, other), .y = @divFloor(self.y, other) };
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
        pub fn asRaylibVector2(self: Self) inner.Vector2 {
            const x: f32 = utils.numberCast(T, f32, self.x);
            const y: f32 = utils.numberCast(T, f32, self.y);
            return .{ .x = x, .y = y };
        }
    };
}

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

        pub fn asRaylibRectangle(self: Self) inner.Rectangle {
            const x: f32 = utils.numberCast(f32, T, self.x);
            const y: f32 = utils.numberCast(f32, T, self.y);
            const width: f32 = utils.numberCast(f32, T, self.width);
            const height: f32 = utils.numberCast(f32, T, self.height);
            return .{ .x = x, .y = y, .width = width, .height = height };
        }
    };
}

// THIS IS STRAIGHT OUT OF RAYLIB
// Keyboard keys (US keyboard layout)
// NOTE: Use GetKeyPressed() to allow redefining
// required keys for alternative layouts
pub const KeyboardKey = enum(u32) {
    NULL = 0, // Key: NULL, used for no key pressed
    // Alphanumeric keys
    APOSTROPHE = 39, // Key: '
    COMMA = 44, // Key: ,
    MINUS = 45, // Key: -
    PERIOD = 46, // Key: .
    SLASH = 47, // Key: /
    ZERO = 48, // Key: 0
    ONE = 49, // Key: 1
    TWO = 50, // Key: 2
    THREE = 51, // Key: 3
    FOUR = 52, // Key: 4
    FIVE = 53, // Key: 5
    SIX = 54, // Key: 6
    SEVEN = 55, // Key: 7
    EIGHT = 56, // Key: 8
    NINE = 57, // Key: 9
    SEMICOLON = 59, // Key: ;
    EQUAL = 61, // Key: =
    A = 65, // Key: A | a
    B = 66, // Key: B | b
    C = 67, // Key: C | c
    D = 68, // Key: D | d
    E = 69, // Key: E | e
    F = 70, // Key: F | f
    G = 71, // Key: G | g
    H = 72, // Key: H | h
    I = 73, // Key: I | i
    J = 74, // Key: J | j
    K = 75, // Key: K | k
    L = 76, // Key: L | l
    M = 77, // Key: M | m
    N = 78, // Key: N | n
    O = 79, // Key: O | o
    P = 80, // Key: P | p
    Q = 81, // Key: Q | q
    R = 82, // Key: R | r
    S = 83, // Key: S | s
    T = 84, // Key: T | t
    U = 85, // Key: U | u
    V = 86, // Key: V | v
    W = 87, // Key: W | w
    X = 88, // Key: X | x
    Y = 89, // Key: Y | y
    Z = 90, // Key: Z | z
    LEFT_BRACKET = 91, // Key: [
    BACKSLASH = 92, // Key: '\'
    RIGHT_BRACKET = 93, // Key: ]
    GRAVE = 96, // Key: `
    // Function keys
    SPACE = 32, // Key: Space
    ESCAPE = 256, // Key: Esc
    ENTER = 257, // Key: Enter
    TAB = 258, // Key: Tab
    BACKSPACE = 259, // Key: Backspace
    INSERT = 260, // Key: Ins
    DELETE = 261, // Key: Del
    RIGHT = 262, // Key: Cursor right
    LEFT = 263, // Key: Cursor left
    DOWN = 264, // Key: Cursor down
    UP = 265, // Key: Cursor up
    PAGE_UP = 266, // Key: Page up
    PAGE_DOWN = 267, // Key: Page down
    HOME = 268, // Key: Home
    END = 269, // Key: End
    CAPS_LOCK = 280, // Key: Caps lock
    SCROLL_LOCK = 281, // Key: Scroll down
    NUM_LOCK = 282, // Key: Num lock
    PRINT_SCREEN = 283, // Key: Print screen
    PAUSE = 284, // Key: Pause
    F1 = 290, // Key: F1
    F2 = 291, // Key: F2
    F3 = 292, // Key: F3
    F4 = 293, // Key: F4
    F5 = 294, // Key: F5
    F6 = 295, // Key: F6
    F7 = 296, // Key: F7
    F8 = 297, // Key: F8
    F9 = 298, // Key: F9
    F10 = 299, // Key: F10
    F11 = 300, // Key: F11
    F12 = 301, // Key: F12
    LEFT_SHIFT = 340, // Key: Shift left
    LEFT_CONTROL = 341, // Key: Control left
    LEFT_ALT = 342, // Key: Alt left
    LEFT_SUPER = 343, // Key: Super left
    RIGHT_SHIFT = 344, // Key: Shift right
    RIGHT_CONTROL = 345, // Key: Control right
    RIGHT_ALT = 346, // Key: Alt right
    RIGHT_SUPER = 347, // Key: Super right
    KB_MENU = 348, // Key: KB menu
    // Keypad keys
    KP_0 = 320, // Key: Keypad 0
    KP_1 = 321, // Key: Keypad 1
    KP_2 = 322, // Key: Keypad 2
    KP_3 = 323, // Key: Keypad 3
    KP_4 = 324, // Key: Keypad 4
    KP_5 = 325, // Key: Keypad 5
    KP_6 = 326, // Key: Keypad 6
    KP_7 = 327, // Key: Keypad 7
    KP_8 = 328, // Key: Keypad 8
    KP_9 = 329, // Key: Keypad 9
    KP_DECIMAL = 330, // Key: Keypad .
    KP_DIVIDE = 331, // Key: Keypad /
    KP_MULTIPLY = 332, // Key: Keypad *
    KP_SUBTRACT = 333, // Key: Keypad -
    KP_ADD = 334, // Key: Keypad +
    KP_ENTER = 335, // Key: Keypad Enter
    KP_EQUAL = 336, // Key: Keypad =
    // Android key buttons
    BACK = 4, // Key: Android back button
    MENU = 5, // Key: Android menu button
    VOLUME_UP = 24, // Key: Android volume up button
    VOLUME_DOWN = 25, // Key: Android volume down button
};

// Mouse buttons
pub const MouseButton = enum(c_int) {
    Left = 0, // Mouse button left
    Right = 1, // Mouse button right
    Middle = 2, // Mouse button middle (pressed wheel)
    Side = 3, // Mouse button side (advanced mouse device)
    Extra = 4, // Mouse button extra (advanced mouse device)
    Forward = 5, // Mouse button forward (advanced mouse device)
    Back = 6, // Mouse button back (advanced mouse device)
};

pub fn IsMouseButtonPressed(button: MouseButton) bool {
    return inner.IsMouseButtonPressed(@intFromEnum(button));
}

pub fn IsMouseButtonReleased(button: MouseButton) bool {
    return inner.IsMouseButtonReleased(@intFromEnum(button));
}

pub fn IsKeyPressed(key: KeyboardKey) bool {
    return inner.IsKeyPressed(@intCast(@intFromEnum(key)));
}

pub fn IsKeyDown(key: KeyboardKey) bool {
    return inner.IsKeyDown(@intCast(@intFromEnum(key)));
}

pub fn IsKeyReleased(key: KeyboardKey) bool {
    return inner.IsKeyReleased(@intCast(@intFromEnum(key)));
}

pub fn GetKeyPressed() ?KeyboardKey {
    const key = inner.GetKeyPressed();
    if (key == 0) {
        return null;
    }
    return @enumFromInt(key);
}

pub fn ClearBackground(color: Color) void {
    inner.ClearBackground(color.asRaylibColor());
}

pub fn BeginDrawing() void {
    inner.BeginDrawing();
}

pub fn EndDrawing() void {
    inner.EndDrawing();
}

pub fn BeginMode2D(camera: Camera2D) void {
    inner.BeginMode2D(camera);
}

pub fn EndMode2D() void {
    inner.EndMode2D();
}

pub fn InitWindow(width: i32, height: i32, title: []const u8) void {
    const ctitle: [*c]u8 = @constCast(title.ptr);
    inner.InitWindow(@intCast(width), @intCast(height), ctitle);
}

pub fn CloseWindow() void {
    inner.CloseWindow();
}

pub fn WindowShouldClose() bool {
    return inner.WindowShouldClose();
}

pub fn SetTargetFPS(fps: i32) void {
    inner.SetTargetFPS(@intCast(fps));
}

pub fn LoadTexture(name: []const u8) inner.Texture2D {
    const cname: [*c]u8 = @constCast(name.ptr);
    return inner.LoadTexture(cname);
}

pub fn MeasureTextEx(
    font: inner.Font,
    text: []const u8,
    font_size: f32,
    spacing: f32,
) Vector2(f32) {
    const ctext: [*c]u8 = @constCast(text.ptr);
    const rl_vec = inner.MeasureTextEx(font, ctext, font_size, spacing);
    return Vector2(f32).init(rl_vec.x, rl_vec.y);
}

pub fn MeasureText(text: []const u8, font_size: i32) i32 {
    const ctext: [*c]u8 = @constCast(text.ptr);
    return inner.MeasureText(ctext, @intCast(font_size));
}

pub fn DrawTexture(texture: *const inner.Texture2D, x: i32, y: i32, color: Color) void {
    inner.DrawTexture(texture.*, @intCast(x), @intCast(y), color.asRaylibColor());
}

pub fn DrawTextureRect(
    texture: *const inner.Texture2D,
    rect: Rectangle(f32),
    pos: Vector2(f32),
    color: Color,
) void {
    inner.DrawTextureRec(
        texture.*,
        rect.asRaylibRectangle(),
        pos.asRaylibVector2(),
        color.asRaylibColor(),
    );
}

pub fn DrawText(text: []const u8, x: i32, y: i32, fontSize: i32, color: Color) void {
    const ctext: [*c]u8 = @constCast(text.ptr);
    inner.DrawText(ctext, @intCast(x), @intCast(y), @intCast(fontSize), color.asRaylibColor());
}

pub fn DrawLine(x1: i32, y1: i32, x2: i32, y2: i32, color: Color) void {
    inner.DrawLine(@intCast(x1), @intCast(y1), @intCast(x2), @intCast(y2), color.asRaylibColor());
}

pub fn DrawLineV(start: Vector2(f32), end: Vector2(f32), color: Color) void {
    inner.DrawLineV(start.asRaylibVector2(), end.asRaylibVector2(), color.asRaylibColor());
}

pub fn DrawRectangle(x: i32, y: i32, width: i32, height: i32, color: Color) void {
    inner.DrawRectangle(@intCast(x), @intCast(y), @intCast(width), @intCast(height), color.asRaylibColor());
}

pub fn DrawRectangleLines(x: i32, y: i32, width: i32, height: i32, color: Color) void {
    inner.DrawRectangleLines(
        @intCast(x),
        @intCast(y),
        @intCast(width),
        @intCast(height),
        color.asRaylibColor(),
    );
}

pub fn DrawRectangleLinesEx(rec: Rectangle(f32), thickness: f32, color: Color) void {
    inner.DrawRectangleLinesEx(rec.asRaylibRectangle(), thickness, color.asRaylibColor());
}

pub fn DrawRectangleV(position: Vector2(f32), size: Vector2(f32), color: Color) void {
    inner.DrawRectangleV(position.asRaylibVector2(), size.asRaylibVector2(), color.asRaylibColor());
}

pub fn DrawRectanglePro(rec: Rectangle(f32), origin: Vector2(f32), rotation: f32, color: Color) void {
    inner.DrawRectanglePro(rec.asRaylibRectangle(), origin.asRaylibVector2(), rotation, color.asRaylibColor());
}

pub fn DrawRectangleRoundedLines(rec: Rectangle(f32), roundness: f32, segments: i32, lineThick: f32, color: Color) void {
    inner.DrawRectangleRoundedLines(
        rec.asRaylibRectangle(),
        roundness,
        @intCast(segments),
        lineThick,
        color.asRaylibColor(),
    );
}

pub fn DrawRectangleRounded(rec: Rectangle(f32), roundness: f32, segments: i32, color: Color) void {
    inner.DrawRectangleRounded(rec.asRaylibRectangle(), roundness, @intCast(segments), color.asRaylibColor());
}

pub fn DrawCircleLinesV(center: Vector2(f32), radius: f32, color: Color) void {
    inner.DrawCircleLinesV(center.asRaylibVector2(), radius, color.asRaylibColor());
}

pub fn rlTranslatef(x: f32, y: f32, z: f32) void {
    inner.rlTranslatef(x, y, z);
}

pub fn rlRotatef(angle: f32, x: f32, y: f32, z: f32) void {
    inner.rlRotatef(angle, x, y, z);
}

pub fn CheckCollisionPointRec(point: Vector2(f32), rec: Rectangle(f32)) bool {
    return inner.CheckCollisionPointRec(point.asRaylibVector2(), rec.asRaylibRectangle());
}

pub fn GetMousePosition() Vector2(f32) {
    const mouse = inner.GetMousePosition();
    return .{ .x = mouse.x, .y = mouse.y };
}

pub fn GetWorldToScreen2D(position: Vector2(f32), camera: Camera2D) Vector2(f32) {
    const mouse = inner.GetWorldToScreen2D(position.asRaylibVector2(), camera);
    return .{ .x = mouse.x, .y = mouse.y };
}

pub fn GetScreenToWorld2D(position: Vector2(f32), camera: Camera2D) Vector2(f32) {
    const mouse = inner.GetScreenToWorld2D(position.asRaylibVector2(), camera);
    return .{ .x = mouse.x, .y = mouse.y };
}

pub fn GetScreenWidth() i32 {
    return inner.GetScreenWidth();
}

pub fn GetScreenHeight() i32 {
    return inner.GetScreenHeight();
}

pub fn SetExitKey(key: KeyboardKey) void {
    inner.SetExitKey(utils.cast(c_int, @intFromEnum(key)));
}

pub fn GenImagePerlinNoise(width: i32, height: i32, offsetX: i32, offsetY: i32, scale: f32) Image {
    return inner.GenImagePerlinNoise(
        @intCast(width),
        @intCast(height),
        @intCast(offsetX),
        @intCast(offsetY),
        scale,
    );
}

pub fn UnloadImage(image: Image) void {
    inner.UnloadImage(image);
}

pub fn GetImageColor(image: Image, x: i32, y: i32) Color {
    const color = inner.GetImageColor(image, x, y);
    return Color.fromRaylibColor(color);
}

pub fn GetImageColorV(image: Image, position: Vector2(i32)) Color {
    const color = inner.GetImageColor(image, position.x, position.y);
    return Color.fromRaylibColor(color);
}

pub fn CheckCollisionCircleRec(center: Vector2(f32), radius: f32, rec: Rectangle(f32)) bool {
    return inner.CheckCollisionCircleRec(center.asRaylibVector2(), radius, rec.asRaylibRectangle());
}
