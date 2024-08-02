const std = @import("std");
const io = @import("io.zig");

const Renderer = @import("render.zig");
const Editor = @import("editor.zig");

pub fn draw_editor(render: *Renderer, editor: Editor, _: u31, height: u31) void {
    const line_height = 24;

    for (editor.lines.items, 0..) |line, idx| {
        const y = height - (idx + 1) * line_height;
        render.draw_text(line.items, 0, @intCast(y), line_height);
    }
}

pub fn main() !void {
    io.init();
    defer io.deinit();

    var render = try Renderer.init();
    defer render.deinit();

    var editor = Editor.init();

    while (!io.window_should_close()) {
        render.start_frame(io.window_width, io.window_height);

        draw_editor(&render, editor, io.window_width, io.window_height);

        if (io.text_input_last_frame.items.len > 0) {
            editor.write_text(io.text_input_last_frame.items);
        }

        if (io.released_last_frame[io.gl.GLFW_KEY_ENTER]) {
            editor.add_new_line();
        }

        io.update();
    }
}
