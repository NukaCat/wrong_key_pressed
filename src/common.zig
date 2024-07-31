const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

var prng = std.rand.DefaultPrng.init(0);
pub var random = prng.random();

pub fn check_gl_err() void {
    const gl = @cImport({
        @cInclude("GL/glew.h");
        @cInclude("GL/gl.h");
    });

    const err = gl.glGetError();
    if (err != gl.GL_NO_ERROR) {
        std.debug.print("gl error {}\n", .{err});
        unreachable;
    }
}
