const std = @import("std");
const io = @import("io.zig");

const render = @import("render.zig");
const Editor = @import("editor.zig");

pub fn draw_editor(editor: Editor, _: u32, height: u32) void {
    const char_distance = 2;
    const line_height = 24;
    const line_width: i32 = @intCast(render.get_symbol_width(line_height) + char_distance);

    for (editor.lines.items, 0..) |line, idx| {
        const y = height - (idx + 1) * line_height;
        render.draw_text(line.items, 0, @intCast(y), line_height, char_distance);
    }

    const time = std.time.milliTimestamp();

    if (@mod(@divFloor(time, 500), 2) == 0) {
        const cursor_x: i32 = @as(i32, @intCast(editor.cursor_x)) * line_width + 1;
        const cursor_y: i32 = @intCast(height - (editor.cursor_y + 1) * line_height - 2);
        const color = render.Color.white;
        render.draw_rect(cursor_x, cursor_y, 1, line_height + 2, color);
    }
}

pub fn main() !void {
    io.init();
    defer io.deinit();

    try render.init();
    defer render.deinit();

    var editor = Editor.init();

    while (!io.window_should_close()) {
        render.start_frame(io.window_width, io.window_height);

        draw_editor(editor, io.window_width, io.window_height);

        if (io.text_input_last_frame.items.len > 0) {
            editor.write_text(io.text_input_last_frame.items);
        }

        if (io.released_last_frame[io.gl.GLFW_KEY_ENTER]) {
            editor.add_new_line();
        }

        io.update();
    }
}
