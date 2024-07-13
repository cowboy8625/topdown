// TODO: change collision to check 3 blocks in a rectangle at a time.
const std = @import("std");
const print = std.debug.print;
const rl = @import("raylib_zig");
const cast = rl.utils.cast;
const Vector2 = rl.Vector2;
const Player = @import("Player.zig");
const Interpolation = @import("Interpolation.zig");
const CONSTANTS = @import("constants.zig");
const Chunk = @import("Chunk.zig");
const BlockType = @import("BlockType.zig").BlockType;
const World = @import("World.zig");

const Mode = enum { Game, Pause, Menu };

const State = struct {
    mode: Mode,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try std.fs.cwd().makePath("data");

    const screen_width = 1920;
    const screen_height = 1080;
    rl.InitWindow(screen_width, screen_height, "raylib zig template");
    defer rl.CloseWindow();

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetTraceLogLevel(rl.LOG_NONE);
    rl.SetExitKey(rl.KeyboardKey.NULL);

    // INIT
    const display_cords_buffer: []u8 = try allocator.alloc(u8, CONSTANTS.TEXT_BUFFER_SIZE);
    defer allocator.free(display_cords_buffer);

    var state = State{ .mode = .Game };
    var player = Player.init();
    var world = try World.init(allocator);
    defer world.deinit();

    var camera: rl.Camera2D = .{
        .offset = .{
            .x = screen_width / 2 + CONSTANTS.CELL_SIZE,
            .y = screen_height / 2 + CONSTANTS.CELL_SIZE,
        },
        .target = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        // UPDATE

        const cursor = rl.GetMousePosition();
        try keyboard_update(&cursor, &state, &player, &camera, &world);

        const deltaTime = rl.GetFrameTime();
        switch (state.mode) {
            .Game => {
                player.update(deltaTime);
                try world.update(player.current_pos);
            },
            .Pause => {},
            .Menu => {},
        }

        camera.target = player.getWorldPos().asRaylibVector2();
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(CONSTANTS.BACKGROUND_COLOR);
        rl.BeginMode2D(camera);
        defer rl.EndMode2D();

        world.draw();
        player.draw();
        switch (state.mode) {
            .Game => {},
            .Pause => {
                const center = get_center_screen();
                const text_width = rl.MeasureText("PAUSED", 20);
                const screen_center: rl.Vector2(f32) = .{
                    .x = center.x - cast(f32, @divFloor(text_width, 2)),
                    .y = center.y,
                };
                const pos = rl.GetScreenToWorld2D(screen_center, camera).as(i32);
                rl.DrawText("PAUSED", pos.x, pos.y, 20, rl.Color.red());
            },
            .Menu => {},
        }
        // draw_grid(&player, &camera, screen_width, screen_height);

        // UI DRAW ON TOP OF EVERYTHING
        try draw_info(&cursor, &camera, display_cords_buffer, &player);
    }
}

fn keyboard_update(
    cursor: *const rl.Vector2(f32),
    state: *State,
    player: *Player,
    camera: *rl.Camera2D,
    world: *World,
) !void {
    switch (state.mode) {
        .Game => try keyboard_update_game(cursor, state, player, camera, world),
        .Pause => try keyboard_update_pause(state),
        .Menu => {},
    }
}

fn keyboard_update_game(
    cursor: *const rl.Vector2(f32),
    state: *State,
    player: *Player,
    camera: *rl.Camera2D,
    world: *World,
) !void {
    const IS_LEFT_PRESSED = rl.IsKeyPressed(rl.KeyboardKey.LEFT) or rl.IsKeyPressed(rl.KeyboardKey.A);
    const IS_RIGHT_PRESSED = rl.IsKeyPressed(rl.KeyboardKey.RIGHT) or rl.IsKeyPressed(rl.KeyboardKey.D);
    const IS_UP_PRESSED = rl.IsKeyPressed(rl.KeyboardKey.UP) or rl.IsKeyPressed(rl.KeyboardKey.W);
    const IS_DOWN_PRESSED = rl.IsKeyPressed(rl.KeyboardKey.DOWN) or rl.IsKeyPressed(rl.KeyboardKey.S);

    const IS_LEFT_RELEASED = rl.IsKeyReleased(rl.KeyboardKey.LEFT) or rl.IsKeyReleased(rl.KeyboardKey.A);
    const IS_RIGHT_RELEASED = rl.IsKeyReleased(rl.KeyboardKey.RIGHT) or rl.IsKeyReleased(rl.KeyboardKey.D);
    const IS_UP_RELEASED = rl.IsKeyReleased(rl.KeyboardKey.UP) or rl.IsKeyReleased(rl.KeyboardKey.W);
    const IS_DOWN_RELEASED = rl.IsKeyReleased(rl.KeyboardKey.DOWN) or rl.IsKeyReleased(rl.KeyboardKey.S);

    if (IS_LEFT_PRESSED) {
        player.velocity.x = -1;
    } else if (IS_RIGHT_PRESSED) {
        player.velocity.x = 1;
    } else if (IS_LEFT_RELEASED or IS_RIGHT_RELEASED) {
        player.velocity.x = 0;
    }

    if (IS_UP_PRESSED) {
        player.velocity.y = -1;
    } else if (IS_DOWN_PRESSED) {
        player.velocity.y = 1;
    } else if (IS_UP_RELEASED or IS_DOWN_RELEASED) {
        player.velocity.y = 0;
    }

    var dir = rl.Vector2(i32).init(0, 0);

    const x = player.velocity.x;
    if (!world.isCollision(player.current_pos, .{ .x = x, .y = 0 }) and !player.isAnimating()) {
        dir.x = x;
    }

    const y = player.velocity.y;
    if (!world.isCollision(player.current_pos, .{ .x = 0, .y = y }) and !player.isAnimating()) {
        dir.y = y;
    }

    if (!dir.isZero() and world.isCollision(player.current_pos, dir)) {
        dir.y = 0;
    }

    player.move(dir);

    if (rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)) {
        state.mode = .Pause;
    }

    // PLACING BLOCK
    if (rl.IsMouseButtonPressed(rl.MouseButton.Left)) {
        const world_mouse_pos = rl.GetScreenToWorld2D(cursor.*, camera.*);
        const block_pos = get_grid_pos(f32, world_mouse_pos, CONSTANTS.CUBE.as(f32));
        if (block_pos.eq(player.current_pos)) return;
        try world.replaceBlock(block_pos.as(i32), .Stone);
    }

    // DESTROYING BLOCK
    if (rl.IsMouseButtonPressed(rl.MouseButton.Right)) {
        const world_mouse_pos = rl.GetScreenToWorld2D(cursor.*, camera.*);
        const block_pos = get_grid_pos(f32, world_mouse_pos, CONSTANTS.CUBE.as(f32));
        if (block_pos.eq(player.current_pos)) return;
        try world.deleteBlock(block_pos.as(i32));
    }
}

fn keyboard_update_pause(state: *State) !void {
    if (rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)) {
        state.mode = .Game;
    }
}

fn get_center_screen() Vector2(f32) {
    return .{ .x = cast(f32, rl.GetScreenWidth()) / 2, .y = cast(f32, rl.GetScreenHeight()) / 2 };
}

/// Takes a Vector(T) and returns the nearest point on the grid as Vector(i32)
fn get_grid_pos(comptime T: type, pos: rl.Vector2(T), cell: rl.Vector2(T)) rl.Vector2(i32) {
    return pos.div(cell).as(i32);
}

fn get_top_left_coner_of_grid_on_screen(player: rl.Vector2(i32), screen: rl.Vector2(i32)) rl.Vector2(i32) {
    return player.sub(screen.div(CONSTANTS.CUBE).div(.{ .x = 2, .y = 2 }));
}

fn get_direction(point: rl.Vector2(f32), cursor: *const rl.Vector2(f32), camera: *rl.Camera2D) rl.Vector2(f32) {
    const world_space_cursor = rl.GetScreenToWorld2D(cursor.*, camera.*);
    const radians = std.math.atan2(world_space_cursor.y - point.y, world_space_cursor.x - point.x);
    return .{ .x = std.math.cos(radians), .y = std.math.sin(radians) };
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
    rl.DrawText(display_cords, offset.x, offset.y, 30, CONSTANTS.UI_TEXT_COLOR);
    // ----Cursor Position-----
    const screen_mouse = rl.GetScreenToWorld2D(cursor.*, camera.*).as(i32);
    const cursor_at_block_pos = get_grid_pos(i32, screen_mouse, CONSTANTS.CUBE);
    const x = cursor_at_block_pos.x;
    const y = cursor_at_block_pos.y;
    const cursor_location = try std.fmt.bufPrintZ(buffer[0..], "cur: x: {d} y: {d}", .{ x, y });
    rl.DrawText(cursor_location, offset.x, offset.y + 35, 30, CONSTANTS.UI_TEXT_COLOR);
}

// fn draw_grid(player: *Player, camera: *rl.Camera2D, width: i32, height: i32) void {
//     const pos = Vector2(f32).init(
//         @mod(camera.offset.x, CONSTANTS.CELL_SIZE) - CONSTANTS.CELL_SIZE,
//         @mod(camera.offset.y, CONSTANTS.CELL_SIZE) - CONSTANTS.CELL_SIZE,
//     );
//     const player_offset = player.current_pos.sub(player.current_pos.div(CONSTANTS.CUBE).mul(CONSTANTS.CUBE)).as(i32);
//     const offset = rl.GetScreenToWorld2D(pos.mul(CONSTANTS.CUBE.as(f32)), camera.*).as(i32);
//
//     var x: i32 = 0;
//     while (x < width + CONSTANTS.CELL_SIZE) : (x += CONSTANTS.CELL_SIZE) {
//         rl.DrawLine(
//             x + offset.x - player_offset.x,
//             offset.y - CONSTANTS.CELL_SIZE - player_offset.y,
//             x + offset.x - player_offset.x,
//             offset.y + height + CONSTANTS.CELL_SIZE - player_offset.y,
//             CONSTANTS.GRID_COLOR,
//         );
//     }
//     var y: i32 = 0;
//     while (y < height + CONSTANTS.CELL_SIZE) : (y += CONSTANTS.CELL_SIZE) {
//         rl.DrawLine(
//             offset.x - CONSTANTS.CELL_SIZE - player_offset.x,
//             y + offset.y - player_offset.y,
//             offset.x + width + CONSTANTS.CELL_SIZE - player_offset.x,
//             y + offset.y - player_offset.y,
//             CONSTANTS.GRID_COLOR,
//         );
//     }
// }
