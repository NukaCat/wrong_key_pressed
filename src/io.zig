const std = @import("std");

const common = @import("common.zig");

pub const gl = @cImport({
    @cInclude("GL/glew.h");
    @cInclude("GL/gl.h");
    @cInclude("GLFW/glfw3.h");
});

const key_count = gl.GLFW_KEY_LAST + 1;
pub const window_width = 1280;
pub const window_height = 720;

pub var pressed_keys: [key_count]bool = [_]bool{false} ** key_count;
pub var released_last_frame: [key_count]bool = [_]bool{false} ** key_count;
pub var text_input_last_frame: std.ArrayList(u8) = undefined;

var main_window: ?*gl.GLFWwindow = null;

pub fn glfw_key_callback(_: ?*gl.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
    const key_idx: usize = @intCast(key);
    if (action == gl.GLFW_PRESS) {
        pressed_keys[key_idx] = true;
    } else if (action == gl.GLFW_RELEASE) {
        pressed_keys[key_idx] = false;
    }

    if (action == gl.GLFW_RELEASE) {
        released_last_frame[key_idx] = true;
    }
}

pub fn glfw_unicode_callback(_: ?*gl.GLFWwindow, codepoint: u32) callconv(.C) void {
    if (codepoint > 255) {
        return;
    }
    const codepoint_u8: u8 = @intCast(codepoint);
    text_input_last_frame.append(codepoint_u8) catch unreachable;
}

pub fn glfw_error_callback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.debug.print("GLFW Error: {} {s}\n", .{ err, description });
    unreachable;
}

pub fn init() void {
    text_input_last_frame = std.ArrayList(u8).init(common.allocator);

    _ = gl.glfwSetErrorCallback(glfw_error_callback);

    const succes = gl.glfwInit();
    if (succes == 0) {
        unreachable;
    }

    main_window = gl.glfwCreateWindow(window_width, window_height, "WKP", null, null);
    if (main_window == null) {
        unreachable;
    }

    gl.glfwMakeContextCurrent(main_window);
    _ = gl.glfwSetKeyCallback(main_window, glfw_key_callback);
    _ = gl.glfwSetCharCallback(main_window, glfw_unicode_callback);
}

pub fn deinit() void {
    gl.glfwDestroyWindow(main_window);
    gl.glfwTerminate();
}

pub fn update() void {
    text_input_last_frame.clearAndFree();
    released_last_frame = [_]bool{false} ** key_count;
    gl.glfwSwapBuffers(main_window);
    gl.glfwPollEvents();
}

pub fn window_should_close() bool {
    return gl.glfwWindowShouldClose(main_window) != 0;
}
