const gl = @cImport({
    @cInclude("GL/glew.h");
    @cInclude("GL/gl.h");
});

const std = @import("std");

const common = @import("common.zig");
const FontMng = @import("font_mng.zig");

const Render = @This();

const check_gl_err = common.check_gl_err;

var shader_program: u32 = undefined;
var rect_vao: u32 = undefined;
var font_mng: FontMng = undefined;
var cur_width: u32 = 0;
var cur_height: u32 = 0;

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const white = make(255, 255, 255, 255);
    pub const black = make(0, 0, 0, 255);
    pub const red = make(255, 0, 0, 255);
    pub const green = make(0, 255, 0, 255);
    pub const blue = make(0, 0, 255, 255);
    pub const none = make(0, 0, 0, 0);

    pub fn make(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }
};

fn compile_shader(shader_str: []const u8, gl_type: gl.GLenum) !u32 {
    const shader = gl.__glewCreateShader.?(gl_type);

    gl.__glewShaderSource.?(shader, 1, &@as([*c]u8, @constCast(@alignCast(shader_str))), null);
    gl.__glewCompileShader.?(shader);

    var success: c_int = 0;
    gl.__glewGetShaderiv.?(shader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        var error_str: [512:0]u8 = undefined;
        gl.__glewGetShaderInfoLog.?(shader, error_str.len, null, @ptrCast(@alignCast(&error_str)));
        std.debug.print("shader compilation error: {s}", .{@as([*:0]const u8, &error_str)});
        return error.GlShaderCompilationError;
    }
    return shader;
}

fn generate_rect_vao() !u32 {
    // zig fmt: off
    const vertices = [_]f32{
        // point        //texture
        0.0, 0.0, 0.0, 0.0, 1.0,
        1.0, 0.0, 0.0, 1.0, 1.0,
        1.0, 1.0, 0.0, 1.0, 0.0,

        0.0, 0.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        1.0, 1.0, 0.0, 1.0, 0.0,
    };
    // zig fmt: on

    var vao: u32 = undefined;
    var vbo: u32 = undefined;

    gl.__glewGenVertexArrays.?(1, &vao);
    gl.__glewGenBuffers.?(1, &vbo);

    gl.__glewBindVertexArray.?(vao);

    gl.__glewBindBuffer.?(gl.GL_ARRAY_BUFFER, vbo);
    gl.__glewBufferData.?(gl.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), @ptrCast(&vertices), gl.GL_STATIC_DRAW);

    gl.__glewVertexAttribPointer.?(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(0));
    gl.__glewEnableVertexAttribArray.?(0);

    gl.__glewVertexAttribPointer.?(1, 2, gl.GL_FLOAT, gl.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    gl.__glewEnableVertexAttribArray.?(1);

    gl.__glewBindBuffer.?(gl.GL_ARRAY_BUFFER, 0);
    gl.__glewBindVertexArray.?(0);

    check_gl_err();
    return vao;
}

pub fn init() !void {
    const err = gl.glewInit();
    if (err != gl.GLEW_OK) {
        const err_str = gl.glewGetErrorString(err);
        std.debug.print("glew init error {s}\n", .{err_str});
        return error.GlGlewInitError;
    }
    //gl.glEnable(gl.GL_DEPTH_TEST);

    const vertex_shader_str = @embedFile("shaders/shader.vert");
    const fragment_shader_str = @embedFile("shaders/shader.frag");

    const vertex_shader = try compile_shader(vertex_shader_str, gl.GL_VERTEX_SHADER);
    const fragment_shader = try compile_shader(fragment_shader_str, gl.GL_FRAGMENT_SHADER);

    shader_program = gl.__glewCreateProgram.?();

    gl.__glewAttachShader.?(shader_program, vertex_shader);
    gl.__glewAttachShader.?(shader_program, fragment_shader);
    gl.__glewLinkProgram.?(shader_program);

    var success: c_int = 0;
    gl.__glewGetProgramiv.?(shader_program, gl.GL_LINK_STATUS, &success);
    if (success == 0) {
        var error_str: [512:0]u8 = undefined;
        gl.__glewGetShaderInfoLog.?(shader_program, error_str.len, null, @ptrCast(@alignCast(&error_str)));
        std.debug.print("shader compilation error: {s}", .{@as([*:0]const u8, &error_str)});
        return error.GlShaderCompilationError;
    }

    rect_vao = try generate_rect_vao();

    font_mng = FontMng.init();
}

pub fn deinit() void {
    font_mng.deinit();
}

pub fn start_frame(width: u32, height: u32) void {
    gl.glViewport(0, 0, @intCast(width), @intCast(height));
    gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
    cur_width = width;
    cur_height = height;
}

pub fn get_symbol_width(height: u32) u32 {
    return font_mng.get_glyph('A', height).advance;
}

fn render_rect(x: i32, y: i32, width: i32, height: i32, color: Color, texture: u32) void {
    const scale_x: f32 = 2.0 / @as(f32, @floatFromInt(cur_width));
    const scale_y: f32 = 2.0 / @as(f32, @floatFromInt(cur_height));

    const width_f32: f32 = @floatFromInt(width);
    const height_f32: f32 = @floatFromInt(height);
    const x_f32: f32 = @floatFromInt(x);
    const y_f32: f32 = @floatFromInt(y);

    const color_array = [_]f32{
        @as(f32, @floatFromInt(color.r)) / 255.0,
        @as(f32, @floatFromInt(color.g)) / 255.0,
        @as(f32, @floatFromInt(color.b)) / 255.0,
        @as(f32, @floatFromInt(color.a)) / 255.0,
    };

    const transform = [_]f32{
        width_f32 * scale_x, 0.0,                  0.0, x_f32 * scale_x - 1.0,
        0.0,                 height_f32 * scale_y, 0.0, y_f32 * scale_y - 1.0,
        0.0,                 0.0,                  1.0, 0.0,
        0.0,                 0.0,                  0.0, 1.0,
    };

    gl.__glewUseProgram.?(shader_program);

    gl.glBindTexture(gl.GL_TEXTURE_2D, texture);

    const transform_loc = gl.__glewGetUniformLocation.?(shader_program, "transform");
    gl.__glewUniformMatrix4fv.?(transform_loc, 1, gl.GL_TRUE, @ptrCast(&transform));

    const color_loc = gl.__glewGetUniformLocation.?(shader_program, "aColor");
    gl.__glewUniform4fv.?(color_loc, 1, @ptrCast(&color_array));

    gl.__glewBindVertexArray.?(rect_vao);
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, 6);

    check_gl_err();
}

pub fn draw_text(text: []const u8, x: i32, y: i32, height: i32, char_distance: u32) void {
    var offset_x = x;

    for (text) |char| {
        const glyph = font_mng.get_glyph(char, @intCast(height));

        const glyph_x = offset_x + glyph.tex_left;
        const glyph_y = y + glyph.tex_top - @as(i32, @intCast(glyph.tex_height));

        render_rect(glyph_x, glyph_y, @intCast(glyph.tex_width), @intCast(glyph.tex_height), Color.none, glyph.texture);

        offset_x += @intCast(glyph.advance + char_distance);

        // const transform = [_]f32{
        //     glyph_width * scale_x, 0.0,                    0.0, glyph_x * scale_x - 1.0,
        //     0.0,                   glyph_height * scale_y, 0.0, glyph_y * scale_y - 1.0,
        //     0.0,                   0.0,                    1.0, 0.0,
        //     0.0,                   0.0,                    0.0, 1.0,
        // };

        // offset_x += @intCast(glyph.advance);

        // gl.__glewUseProgram.?(shader_program);

        // gl.glBindTexture(gl.GL_TEXTURE_2D, glyph.texture);

        // const transform_loc = gl.__glewGetUniformLocation.?(shader_program, "transform");
        // gl.__glewUniformMatrix4fv.?(transform_loc, 1, gl.GL_TRUE, @ptrCast(&transform));

        // // const color_loc = gl.__glewGetUniformLocation.?(self.shader_program, "color");
        // // gl.__glewUniform4fv.?(color_loc, 1, @ptrCast(&color));

        // gl.__glewBindVertexArray.?(rect_vao);
        // gl.glDrawArrays(gl.GL_TRIANGLES, 0, 6);
    }

    // check_gl_err();
}

pub fn draw_rect(x: i32, y: i32, width: i32, height: i32, color: Color) void {
    render_rect(x, y, width, height, color, 0);
}
