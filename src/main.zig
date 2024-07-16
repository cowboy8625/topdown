// TODO: change collision to check 3 blocks in a rectangle at a time.
const std = @import("std");
const print = std.debug.print;
const rl = @import("raylib");
const utils = @import("utils.zig");
const cast = utils.cast;
const Vector2 = @import("Vector2.zig").Vector2;
const Player = @import("Player.zig");
const Interpolation = @import("Interpolation.zig");
const CONSTANTS = @import("constants.zig");
const Chunk = @import("Chunk.zig");
const BlockType = @import("BlockType.zig").BlockType;
const World = @import("World.zig");

const Mode = enum { Game, Pause, Menu };

const State = struct {
    mode: Mode,
    debug_mode: bool = false,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try std.fs.cwd().makePath("data");

    const screen_width = 1920;
    const screen_height = 1080;
    rl.initWindow(screen_width, screen_height, "raylib zig template");
    defer rl.closeWindow();

    // rl.setConfigFlags(@enumFromInt(@intFromEnum(rl.ConfigFlags.window_resizable)));
    rl.setTraceLogLevel(rl.TraceLogLevel.log_none);
    rl.setExitKey(rl.KeyboardKey.key_null);

    // INIT
    const display_cords_buffer: []u8 = try allocator.alloc(u8, CONSTANTS.TEXT_BUFFER_SIZE);
    defer allocator.free(display_cords_buffer);

    var state = State{ .mode = .Game };
    var player = Player.init(allocator);
    defer player.deinit();
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

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        // UPDATE

        const cursor = Vector2(f32).fromRaylibVevtor2(rl.getMousePosition());
        try keyboard_update(&cursor, &state, &player, &camera, &world);

        const deltaTime = rl.getFrameTime();
        switch (state.mode) {
            .Game => {
                player.update(deltaTime);
                try world.update(player.current_pos);
            },
            .Pause => {},
            .Menu => {},
        }

        camera.target = player.getWorldPos().asRaylibVector2();
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(CONSTANTS.BACKGROUND_COLOR);
        rl.beginMode2D(camera);
        defer rl.endMode2D();

        world.draw(.{ .showChunkBoards = state.debug_mode });
        player.draw(&camera);
        switch (state.mode) {
            .Game => {},
            .Pause => {
                const center = get_center_screen();
                const text_width = rl.measureText("PAUSED", 20);
                const screen_center = .{
                    .x = center.x - cast(f32, @divFloor(text_width, 2)),
                    .y = center.y,
                };
                const pos = rl.getScreenToWorld2D(screen_center, camera);
                rl.drawText("PAUSED", cast(i32, pos.x), cast(i32, pos.y), 20, rl.Color.red);
            },
            .Menu => {},
        }
        // draw_grid(&player, &camera, screen_width, screen_height);

        // UI DRAW ON TOP OF EVERYTHING
        if (state.debug_mode) {
            try draw_info(&cursor, &camera, display_cords_buffer, &player);
        }
    }
}

fn keyboard_update(
    cursor: *const Vector2(f32),
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
    cursor: *const Vector2(f32),
    state: *State,
    player: *Player,
    camera: *rl.Camera2D,
    world: *World,
) !void {
    const IS_LEFT_PRESSED = rl.isKeyPressed(rl.KeyboardKey.key_left) or rl.isKeyPressed(rl.KeyboardKey.key_a);
    const IS_RIGHT_PRESSED = rl.isKeyPressed(rl.KeyboardKey.key_right) or rl.isKeyPressed(rl.KeyboardKey.key_d);
    const IS_UP_PRESSED = rl.isKeyPressed(rl.KeyboardKey.key_up) or rl.isKeyPressed(rl.KeyboardKey.key_w);
    const IS_DOWN_PRESSED = rl.isKeyPressed(rl.KeyboardKey.key_down) or rl.isKeyPressed(rl.KeyboardKey.key_s);

    const IS_LEFT_RELEASED = rl.isKeyReleased(rl.KeyboardKey.key_left) or rl.isKeyReleased(rl.KeyboardKey.key_a);
    const IS_RIGHT_RELEASED = rl.isKeyReleased(rl.KeyboardKey.key_right) or rl.isKeyReleased(rl.KeyboardKey.key_d);
    const IS_UP_RELEASED = rl.isKeyReleased(rl.KeyboardKey.key_up) or rl.isKeyReleased(rl.KeyboardKey.key_w);
    const IS_DOWN_RELEASED = rl.isKeyReleased(rl.KeyboardKey.key_down) or rl.isKeyReleased(rl.KeyboardKey.key_s);

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

    var dir = Vector2(i32).init(0, 0);

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

    if (rl.isKeyPressed(rl.KeyboardKey.key_escape)) {
        state.mode = .Pause;
    }

    if (rl.isKeyPressed(rl.KeyboardKey.key_f3)) {
        state.debug_mode = !state.debug_mode;
    }

    // PLACING BLOCK
    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
        const world_mouse_pos = Vector2(f32).fromRaylibVevtor2(rl.getScreenToWorld2D(
            cursor.*.asRaylibVector2(),
            camera.*,
        ));
        const block_pos = get_grid_pos(f32, world_mouse_pos, CONSTANTS.CUBE.as(f32));
        if (block_pos.eq(player.current_pos)) return;
        if (player.getItemFromActiveSlot()) |block| {
            try world.replaceBlock(block_pos.as(i32), block);
        }
    }

    // DESTROYING BLOCK
    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_right)) {
        const world_mouse_pos = Vector2(f32).fromRaylibVevtor2(
            rl.getScreenToWorld2D(
                cursor.*.asRaylibVector2(),
                camera.*,
            ),
        );
        const block_pos = get_grid_pos(f32, world_mouse_pos, CONSTANTS.CUBE.as(f32));
        if (block_pos.eq(player.current_pos)) return;
        if (world.deleteBlock(block_pos.as(i32))) |block| {
            try player.addToInventory(block);
        }
    }
}

fn keyboard_update_pause(state: *State) !void {
    if (rl.isKeyPressed(rl.KeyboardKey.key_escape)) {
        state.mode = .Game;
    }
}

fn get_center_screen() Vector2(f32) {
    return .{ .x = cast(f32, rl.getScreenWidth()) / 2, .y = cast(f32, rl.getScreenHeight()) / 2 };
}

/// Takes a Vector(T) and returns the nearest point on the grid as Vector(i32)
fn get_grid_pos(comptime T: type, pos: Vector2(T), cell: Vector2(T)) Vector2(i32) {
    return pos.div(cell).as(i32);
}

fn get_top_left_coner_of_grid_on_screen(player: Vector2(i32), screen: Vector2(i32)) Vector2(i32) {
    return player.sub(screen.div(CONSTANTS.CUBE).div(.{ .x = 2, .y = 2 }));
}

fn get_direction(point: Vector2(f32), cursor: *const Vector2(f32), camera: *rl.Camera2D) Vector2(f32) {
    const world_space_cursor = rl.GetScreenToWorld2D(cursor.*, camera.*);
    const radians = std.math.atan2(world_space_cursor.y - point.y, world_space_cursor.x - point.x);
    return .{ .x = std.math.cos(radians), .y = std.math.sin(radians) };
}

fn draw_info(
    cursor: *const Vector2(f32),
    camera: *rl.Camera2D,
    buffer: []u8,
    player: *Player,
) !void {
    // -------Position---------
    const ui_pos = .{ .x = 30, .y = 10 };
    const offset = rl.getScreenToWorld2D(ui_pos, camera.*);
    const display_cords = try std.fmt.bufPrintZ(buffer[0..], "pos: x: {d} y: {d}", .{ player.current_pos.x, player.current_pos.y });
    rl.drawText(display_cords, cast(i32, offset.x), cast(i32, offset.y), 30, CONSTANTS.UI_TEXT_COLOR);
    // ----Cursor Position-----
    const screen_mouse = Vector2(f32).fromRaylibVevtor2(rl.getScreenToWorld2D(cursor.*.asRaylibVector2(), camera.*)).as(i32);
    const cursor_at_block_pos = get_grid_pos(i32, screen_mouse, CONSTANTS.CUBE);
    const x = cursor_at_block_pos.x;
    const y = cursor_at_block_pos.y;
    const cursor_location = try std.fmt.bufPrintZ(buffer[0..], "cur: x: {d} y: {d}", .{ x, y });
    rl.drawText(
        cursor_location,
        cast(i32, offset.x),
        cast(i32, offset.y) + 35,
        30,
        CONSTANTS.UI_TEXT_COLOR,
    );
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
