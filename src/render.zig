const gl = @cImport({
    @cInclude("GL/glew.h");
    @cInclude("GL/gl.h");
});

const std = @import("std");

const common = @import("common.zig");
const FontMng = @import("font_mng.zig");

const Render = @This();

const check_gl_err = common.check_gl_err;

shader_program: u32 = undefined,
rect_vao: u32 = undefined,
font_mng: FontMng = undefined,
cur_width: u32 = 0,
cur_height: u32 = 0,

fn load_shader(path: []const u8, gl_type: gl.GLenum) !u32 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var content = std.ArrayList(u8).init(common.allocator);
    defer content.deinit();

    try file.reader().readAllArrayList(&content, std.math.maxInt(usize));
    content.append(0) catch unreachable;

    const shader = gl.__glewCreateShader.?(gl_type);

    gl.__glewShaderSource.?(shader, 1, &@as([*c]u8, @ptrCast(@alignCast(content.items))), null);
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

pub fn init() !Render {
    const err = gl.glewInit();
    if (err != gl.GLEW_OK) {
        const err_str = gl.glewGetErrorString(err);
        std.debug.print("glew init error {s}\n", .{err_str});
        return error.GlGlewInitError;
    }
    //gl.glEnable(gl.GL_DEPTH_TEST);

    const vertex_shader = try load_shader("shaders/shader.vert", gl.GL_VERTEX_SHADER);
    const fragment_shader = try load_shader("shaders/shader.frag", gl.GL_FRAGMENT_SHADER);

    const shader_program = gl.__glewCreateProgram.?();

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

    const rect_vao = try generate_rect_vao();

    return Render{
        .shader_program = shader_program,
        .rect_vao = rect_vao,
        .font_mng = FontMng.init(),
    };
}

pub fn deinit(self: *Render) void {
    self.glyph_mng.deinit();
    gl.glewShutdown();
}

pub fn start_frame(self: *Render, width: u32, height: u32) void {
    gl.glViewport(0, 0, @intCast(width), @intCast(height));
    gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
    self.cur_width = width;
    self.cur_height = height;
}

pub fn draw_text(self: *Render, text: []const u8, x: i32, y: i32, height: i32) void {
    var offset_x = x;

    const scale_x: f32 = 2.0 / @as(f32, @floatFromInt(self.cur_width));
    const scale_y: f32 = 2.0 / @as(f32, @floatFromInt(self.cur_height));

    for (text) |char| {
        const glyph = self.font_mng.get_glyph(char, @intCast(height));

        const glyph_x: f32 = @floatFromInt(offset_x + glyph.tex_left);
        const glyph_y: f32 = @floatFromInt(y + glyph.tex_top - @as(i32, @intCast(glyph.tex_height)));

        const glyph_width: f32 = @floatFromInt(glyph.tex_width);
        const glyph_height: f32 = @floatFromInt(glyph.tex_height);

        const transform = [_]f32{
            glyph_width * scale_x, 0.0,                    0.0, glyph_x * scale_x - 1.0,
            0.0,                   glyph_height * scale_y, 0.0, glyph_y * scale_y - 1.0,
            0.0,                   0.0,                    1.0, 0.0,
            0.0,                   0.0,                    0.0, 1.0,
        };

        offset_x += @intCast(glyph.advance);

        gl.__glewUseProgram.?(self.shader_program);

        gl.glBindTexture(gl.GL_TEXTURE_2D, glyph.texture);

        const transform_loc = gl.__glewGetUniformLocation.?(self.shader_program, "transform");
        gl.__glewUniformMatrix4fv.?(transform_loc, 1, gl.GL_TRUE, @ptrCast(&transform));

        // const color_loc = gl.__glewGetUniformLocation.?(self.shader_program, "color");
        // gl.__glewUniform4fv.?(color_loc, 1, @ptrCast(&color));

        gl.__glewBindVertexArray.?(self.rect_vao);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 6);
    }

    check_gl_err();
}
