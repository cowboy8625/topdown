// TODO: change collision to check 3 blocks in a rectangle at a time.
const std = @import("std");
const print = std.debug.print;
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
const Vector2 = rl.Vector2;

const BACKGROUND_COLOR = rl.Color.init(40, 40, 40, 255);
const GRID_COLOR = rl.Color.black();
const UI_TEXT_COLOR = rl.Color.rayWhite();
const TEXT_BUFFER_SIZE = 256;
const POINT_BUFFER_SIZE = 9;
const CELL_SIZE = 32;
const CUBE: Vector2(i32) = .{ .x = CELL_SIZE, .y = CELL_SIZE };
const BlockType = enum {
    Stone,

    fn color(self: BlockType) rl.Color {
        return switch (self) {
            .Stone => rl.Color.lightGray(),
        };
    }
};

const BlockMap = std.AutoHashMap(Vector2(i32), BlockType);

const Mode = enum { Game, Pause, Menu };

const State = struct {
    mode: Mode,
};

const Player = struct {
    const Self = @This();
    const CENTER: rl.Vector2(f32) = CUBE.as(f32).divFromNum(2);
    current_pos: rl.Vector2(i32),
    animation: ?Animation = null,

    fn init() Self {
        return .{
            .current_pos = .{ .x = 0, .y = 0 },
            .animation = null,
        };
    }

    pub fn getWorldPos(self: *const Self) rl.Vector2(f32) {
        if (self.animation) |animation| {
            return animation.current;
        }
        return get_world_pos_from_grid(i32, self.current_pos, CUBE);
    }

    pub fn move(self: *Self, dir: rl.Vector2(i32)) void {
        if (dir.isZero()) return;
        const start = self.current_pos;
        const end = self.current_pos.add(dir);
        const world_start = start.mul(CUBE).as(f32);
        const world_end = end.mul(CUBE).as(f32);
        self.startAnimation(world_start, world_end, 0.2);
        self.current_pos = end;
    }

    pub fn center(self: *const Self) Vector2(f32) {
        return self.current_pos.mul(CUBE).as(f32).add(Self.CENTER);
    }

    pub fn startAnimation(self: *Self, start: rl.Vector2(f32), end: rl.Vector2(f32), duration: f32) void {
        self.animation = Animation{
            .start = start,
            .end = end,
            .current = start,
            .time = 0.0,
            .elapsedTime = 0.0,
            .duration = duration,
        };
    }

    pub fn isAnimating(self: *const Self) bool {
        return self.animation != null;
    }

    pub fn update(self: *Self, deltaTime: f32) void {
        if (self.animation) |*animation| {
            if (animation.isDone()) {
                self.animation = null;
                return;
            }
            animation.update(deltaTime);
            return;
        }
    }

    pub fn draw(self: Self) void {
        if (self.animation) |_| {
            const pos = self.getWorldPos();
            rl.DrawRectangleV(pos, CUBE.as(f32), rl.Color.red());
            return;
        }

        const pos = get_world_pos_from_grid(i32, self.current_pos, CUBE);
        rl.DrawRectangleV(pos, CUBE.as(f32), rl.Color.red());
    }
};

const Animation = struct {
    const Self = @This();
    start: rl.Vector2(f32),
    end: rl.Vector2(f32),
    current: rl.Vector2(f32),
    time: f32,
    elapsedTime: f32,
    duration: f32,

    fn isDone(self: Self) bool {
        return self.elapsedTime >= self.duration;
    }

    fn update(self: *Self, deltaTime: f32) void {
        self.elapsedTime += deltaTime; // Update the elapsed time

        var interpolationFactor = self.elapsedTime / self.duration;

        if (interpolationFactor > 1.0) {
            interpolationFactor = 1.0;
        }

        // Linear interpolation (LERP)
        self.current.x = self.start.x + interpolationFactor * (self.end.x - self.start.x);
        self.current.y = self.start.y + interpolationFactor * (self.end.y - self.start.y);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const screen_width = 1920;
    const screen_height = 1080;
    rl.InitWindow(screen_width, screen_height, "raylib zig template");
    defer rl.CloseWindow();

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetTraceLogLevel(rl.LOG_NONE);
    rl.SetExitKey(rl.KeyboardKey.NULL);

    // INIT
    const display_cords_buffer: []u8 = try allocator.alloc(u8, TEXT_BUFFER_SIZE);
    defer allocator.free(display_cords_buffer);
    var block_map = BlockMap.init(allocator);
    defer block_map.deinit();
    var mangaled = BlockMap.init(allocator);
    defer mangaled.deinit();

    var state = State{ .mode = .Game };
    var player = Player.init();

    var camera: rl.Camera2D = .{
        .offset = .{ .x = screen_width / 2 + CELL_SIZE, .y = screen_height / 2 + CELL_SIZE },
        .target = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        // UPDATE
        const cursor = rl.GetMousePosition();
        try keyboard_update(&cursor, &state, &player, &camera, &block_map, &mangaled);
        try update_world(screen_width, screen_height, player.current_pos, &block_map, &mangaled);
        update(&state, &player, &block_map);

        camera.target = player.getWorldPos().asRaylibVector2();
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(BACKGROUND_COLOR);
        rl.BeginMode2D(camera);
        defer rl.EndMode2D();

        // DRAW
        try draw(
            &cursor,
            display_cords_buffer,
            &player,
            &state,
            &camera,
            &block_map,
            screen_width,
            screen_height,
        );
    }
}

fn update(state: *State, player: *Player, block_map: *BlockMap) void {
    _ = block_map;
    const deltaTime = rl.GetFrameTime();
    switch (state.mode) {
        .Game => {
            // apply_velocity_to(player, block_map, block_buffer);
            player.update(deltaTime);
        },
        .Pause => {},
        .Menu => {},
    }
}

fn is_collision(player: rl.Vector2(i32), direction: rl.Vector2(i32), block_map: *BlockMap) bool {
    const location = player.add(direction);
    return block_map.contains(location);
}

/// Get the blocks surrounding the point
/// | 0 | 1 | 2 |
/// | 3 | 4 | 5 |
/// | 6 | 7 | 8 |
/// index 4 is the point passed in
// fn get_blocks_surrounding(point: rl.Vector2(f32), block_map: *BlockMap, out: []?rl.Vector2(i32)) void {
//     const grid_pos = get_grid_pos(f32, point, CUBE.as(f32));
//     var index: usize = 0;
//     var x = grid_pos.x - 1;
//     while (x <= grid_pos.x + 1) : (x += 1) {
//         var y = grid_pos.y - 1;
//         while (y <= grid_pos.y + 1) : (y += 1) {
//             const block_pos: Vector2(i32) = .{ .x = x, .y = y };
//             if (block_map.contains(block_pos)) {
//                 out[index] = block_pos;
//                 index += 1;
//             }
//         }
//     }
// }
//
// fn apply_velocity_to(player: *Player, block_map: *BlockMap, block_buffer: []?rl.Vector2(i32)) void {
//     const player_pos = player.pos.add(player.vel);
//     get_blocks_surrounding(player.center(), block_map, block_buffer);
//     if (block_buffer.len != 0) {
//         for (block_buffer) |block_pos| {
//             if (block_pos) |pos| {
//                 const block = rl.Rectangle(f32).from2vec2(pos.mul(CUBE).as(f32), CUBE.as(f32));
//                 if (rl.CheckCollisionCircleRec(player.center(), player.radius, block)) {
//                     player.pos = player.pos.sub(player.vel);
//                     player.vel = .{ .x = 0, .y = 0 };
//                     return;
//                 }
//             }
//         }
//     }
//     player.pos = player_pos;
// }

fn update_world(width: i32, height: i32, player_pos: rl.Vector2(i32), block_map: *BlockMap, mangaled: *BlockMap) !void {
    block_map.*.clearRetainingCapacity();
    const offset = get_top_left_coner_of_grid_on_screen(player_pos, Vector2(i32).init(width, height));
    const size = Vector2(i32).init(width, height).div(CUBE);
    const image = rl.GenImagePerlinNoise(
        size.x,
        size.y,
        offset.x,
        offset.y,
        1.0,
    );
    defer rl.UnloadImage(image);
    for (0..cast(usize, image.width)) |x| {
        for (0..cast(usize, image.height)) |y| {
            const pixel = Vector2(usize).init(x, y).as(i32);
            const color = rl.GetImageColorV(image, pixel);
            const r: bool = color.r > 128;
            const g: bool = color.g > 128;
            const b: bool = color.b > 128;
            const a: bool = color.a > 128;
            if (r and g and b and a) {
                try block_map.*.put(pixel.add(offset).sub(.{ .x = 1, .y = 2 }), .Stone);
            }
        }
    }
    var iter = mangaled.*.iterator();
    while (iter.next()) |entry| {
        try block_map.*.put(entry.key_ptr.*, entry.value_ptr.*);
    }
}

fn keyboard_update(
    cursor: *const rl.Vector2(f32),
    state: *State,
    player: *Player,
    camera: *rl.Camera2D,
    block_map: *BlockMap,
    mangaled: *BlockMap,
) !void {
    switch (state.mode) {
        .Game => try keyboard_update_game(cursor, state, player, camera, block_map, mangaled),
        .Pause => try keyboard_update_pause(state),
        .Menu => {},
    }
}

fn keyboard_update_game(
    cursor: *const rl.Vector2(f32),
    state: *State,
    player: *Player,
    camera: *rl.Camera2D,
    block_map: *BlockMap,
    mangaled: *BlockMap,
) !void {
    var dir = Vector2(i32).init(0, 0);
    if (rl.IsKeyPressed(rl.KeyboardKey.LEFT) or rl.IsKeyPressed(rl.KeyboardKey.A)) {
        dir.x -= 1;
    } else if (rl.IsKeyPressed(rl.KeyboardKey.RIGHT) or rl.IsKeyPressed(rl.KeyboardKey.D)) {
        dir.x += 1;
    } else {}
    if (rl.IsKeyPressed(rl.KeyboardKey.UP) or rl.IsKeyPressed(rl.KeyboardKey.W)) {
        dir.y -= 1;
    } else if (rl.IsKeyPressed(rl.KeyboardKey.DOWN) or rl.IsKeyPressed(rl.KeyboardKey.S)) {
        dir.y += 1;
    } else {}

    if (!is_collision(player.current_pos, dir, block_map) and !player.isAnimating()) {
        player.move(dir);
    }

    if (rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)) {
        state.mode = .Pause;
    }

    // PLACING BLOCK
    if (rl.IsMouseButtonPressed(rl.MouseButton.Left)) {
        const world_mouse_pos = rl.GetScreenToWorld2D(cursor.*, camera.*);
        const block_pos = get_grid_pos(f32, world_mouse_pos, CUBE.as(f32));
        if (block_pos.eq(player.current_pos)) return;
        try mangaled.put(block_pos.as(i32), .Stone);
    }

    // DESTROYING BLOCK
    if (rl.IsMouseButtonPressed(rl.MouseButton.Right)) {
        const world_mouse_pos = rl.GetScreenToWorld2D(cursor.*, camera.*);
        const block_pos = get_grid_pos(f32, world_mouse_pos, CUBE.as(f32));
        if (block_pos.eq(player.current_pos)) return;
        _ = mangaled.remove(block_pos.as(i32));
    }
}

fn keyboard_update_pause(state: *State) !void {
    if (rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)) {
        state.mode = .Game;
    }
}

fn draw(
    cursor: *const rl.Vector2(f32),
    buffer: []u8,
    player: *Player,
    state: *State,
    camera: *rl.Camera2D,
    block_map: *BlockMap,
    screen_width: i32,
    screen_height: i32,
) !void {
    _ = screen_height;
    _ = screen_width;
    player.draw();
    draw_placed_blocks(block_map);
    // draw_grid(player, camera, screen_width, screen_height);
    // PAUSE MENU
    if (state.mode == .Pause) {
        const center = get_center_screen();
        const text_width = rl.MeasureText("PAUSED", 20);
        const screen_center: rl.Vector2(f32) = .{
            .x = center.x - cast(f32, @divFloor(text_width, 2)),
            .y = center.y,
        };
        const pos = rl.GetScreenToWorld2D(screen_center, camera.*).as(i32);
        rl.DrawText("PAUSED", pos.x, pos.y, 20, rl.Color.red());
    }

    // UI DRAW ON TOP OF EVERYTHING
    try draw_info(cursor, camera, buffer, player);
}

fn get_center_screen() Vector2(f32) {
    return .{ .x = cast(f32, rl.GetScreenWidth()) / 2, .y = cast(f32, rl.GetScreenHeight()) / 2 };
}

/// Takes a Vector(T) and returns the nearest point on the grid as Vector(i32)
fn get_grid_pos(comptime T: type, pos: rl.Vector2(T), cell: rl.Vector2(T)) rl.Vector2(i32) {
    return pos.div(cell).as(i32);
}

// Takes a grid position Vector(i32) and returns the world position as Vector2(f32)
fn get_world_pos_from_grid(comptime T: type, pos: rl.Vector2(T), cell: rl.Vector2(T)) rl.Vector2(f32) {
    return pos.mul(cell).as(f32);
}

fn get_top_left_coner_of_grid_on_screen(player: rl.Vector2(i32), screen: rl.Vector2(i32)) rl.Vector2(i32) {
    return player.sub(screen.div(CUBE).div(.{ .x = 2, .y = 2 }));
}

fn get_direction(point: rl.Vector2(f32), cursor: *const rl.Vector2(f32), camera: *rl.Camera2D) rl.Vector2(f32) {
    const world_space_cursor = rl.GetScreenToWorld2D(cursor.*, camera.*);
    const radians = std.math.atan2(world_space_cursor.y - point.y, world_space_cursor.x - point.x);
    return .{ .x = std.math.cos(radians), .y = std.math.sin(radians) };
}

fn draw_block(pos: rl.Vector2(i32), color: rl.Color) void {
    rl.DrawRectangleV(pos.mul(CUBE).as(f32), CUBE.as(f32), color);
}

fn draw_placed_blocks(block_map: *BlockMap) void {
    var iter = block_map.iterator();
    while (iter.next()) |entry| {
        const block_pos = entry.key_ptr;
        const color = entry.value_ptr.color();
        draw_block(block_pos.*, color);
    }
}

fn draw_info(
    cursor: *const rl.Vector2(f32),
    camera: *rl.Camera2D,
    buffer: []u8,
    player: *Player,
) !void {
    // -------Position---------
    const ui_pos = Vector2(f32).init(30, 10);
    const offset = rl.GetScreenToWorld2D(ui_pos, camera.*).as(i32);
    const display_cords = try std.fmt.bufPrintZ(buffer[0..], "pos: x: {d} y: {d}", .{ player.current_pos.x, player.current_pos.y });
    rl.DrawText(display_cords, offset.x, offset.y, 30, UI_TEXT_COLOR);
    // ----Cursor Position-----
    const screen_mouse = rl.GetScreenToWorld2D(cursor.*, camera.*).as(i32);
    const cursor_at_block_pos = get_grid_pos(i32, screen_mouse, CUBE);
    const x = cursor_at_block_pos.x;
    const y = cursor_at_block_pos.y;
    const cursor_location = try std.fmt.bufPrintZ(buffer[0..], "cur: x: {d} y: {d}", .{ x, y });
    rl.DrawText(cursor_location, offset.x, offset.y + 35, 30, UI_TEXT_COLOR);
}

fn draw_grid(player: *Player, camera: *rl.Camera2D, width: i32, height: i32) void {
    // const pos = Vector2(f32).fromRaylibVevtor2(camera.offset);
    const pos = Vector2(f32).init(
        @mod(camera.offset.x, CELL_SIZE) - CELL_SIZE,
        @mod(camera.offset.y, CELL_SIZE) - CELL_SIZE,
    );
    const player_offset = player.current_pos.sub(player.get_pos_snap_to_grid()).as(i32);
    const offset = rl.GetScreenToWorld2D(pos.mul(CUBE), camera.*).as(i32);
    var x: i32 = 0;
    while (x < width + CELL_SIZE) : (x += CELL_SIZE) {
        rl.DrawLine(
            x + offset.x - player_offset.x,
            offset.y - CELL_SIZE - player_offset.y,
            x + offset.x - player_offset.x,
            offset.y + height + CELL_SIZE - player_offset.y,
            GRID_COLOR,
        );
    }
    var y: i32 = 0;
    while (y < height + CELL_SIZE) : (y += CELL_SIZE) {
        rl.DrawLine(
            offset.x - CELL_SIZE - player_offset.x,
            y + offset.y - player_offset.y,
            offset.x + width + CELL_SIZE - player_offset.x,
            y + offset.y - player_offset.y,
            GRID_COLOR,
        );
    }
}
