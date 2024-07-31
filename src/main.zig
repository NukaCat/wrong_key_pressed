const std = @import("std");

const gl = @cImport({
    @cInclude("GL/glew.h");
    @cInclude("GL/gl.h");
    @cInclude("GLFW/glfw3.h");
});

const common = @import("common.zig");
const render = @import("render.zig");

pub fn glfw_error_callback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.debug.print("GLFW Error: {} {s}\n", .{ err, description });
}

pub fn main() !void {
    const window_width = 1280;
    const window_height = 720;

    _ = gl.glfwSetErrorCallback(glfw_error_callback);

    const succes = gl.glfwInit();
    if (succes == 0) {
        return error.GlfwInitError;
    }
    defer gl.glfwTerminate();

    const wind = gl.glfwCreateWindow(window_width, window_height, "WKP", null, null);
    if (wind == null) {
        return error.GlfwCreateWindowError;
    }
    defer gl.glfwDestroyWindow(wind);

    gl.glfwMakeContextCurrent(wind);

    var rend = try render.init();

    while (gl.glfwWindowShouldClose(wind) == 0) {
        rend.start_frame(window_width, window_height);
        rend.draw_text("Hello, World!", 100, 100, 24);
        rend.draw_text("Hello, Second!ggg", 100, 132, 24);

        gl.glfwSwapBuffers(wind);
        gl.glfwPollEvents();
    }
}
