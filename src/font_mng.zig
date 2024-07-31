const std = @import("std");

const gl = @cImport({
    @cInclude("GL/glew.h");
    @cInclude("GL/gl.h");
});

const ft = @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
});

const common = @import("common.zig");
const check_gl_err = common.check_gl_err;

const FontManager = @This();

const GlyphKey = struct {
    char_code: u32,
    pixel_height: u32,
};

pub const Glyph = struct {
    texture: u32,
    tex_width: u32,
    tex_height: u32,
    tex_left: i32,
    tex_top: i32,
    advance: u32,
};

ft_lib: ft.FT_Library,
face: ft.FT_Face,

glyphs: std.AutoHashMap(GlyphKey, Glyph),

pub fn init() FontManager {
    var ft_lib: ft.FT_Library = undefined;
    var err = ft.FT_Init_FreeType(@ptrCast(&ft_lib));
    if (err != 0) {
        unreachable;
    }

    const font_data = @embedFile("fonts/consolas.ttf");
    var face: ft.FT_Face = undefined;

    err = ft.FT_New_Memory_Face(ft_lib, font_data, @intCast(font_data.len), 0, @ptrCast(&face));
    if (err != 0) {
        unreachable;
    }

    return FontManager{
        .ft_lib = ft_lib,
        .face = face,
        .glyphs = std.AutoHashMap(GlyphKey, Glyph).init(common.allocator),
    };
}

pub fn deinit(self: FontManager) void {
    ft.FT_Done_Face(self.face);
    ft.FT_Done_FreeType(self.ft_lib);

    var iter = self.glyphs.valueIterator();
    while (iter.next()) |item| {
        gl.glDeleteTextures(1, item);
    }
}

pub fn get_glyph(self: *FontManager, char_code: u32, pixel_height: u32) Glyph {
    const key = GlyphKey{ .char_code = char_code, .pixel_height = pixel_height };
    if (self.glyphs.get(key)) |val| {
        return val;
    }

    var err = ft.FT_Set_Pixel_Sizes(self.face, 0, pixel_height);
    if (err != 0) {
        unreachable;
    }

    const glyph_index = ft.FT_Get_Char_Index(self.face, char_code);

    err = ft.FT_Load_Glyph(self.face, glyph_index, ft.FT_LOAD_RENDER);
    if (err != 0) {
        unreachable;
    }

    err = ft.FT_Render_Glyph(self.face.*.glyph, 0);
    if (err != 0) {
        unreachable;
    }

    const bitmap = self.face.*.glyph.*.bitmap;

    var texture: u32 = undefined;
    gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);
    gl.glGenTextures(1, &texture);
    gl.glBindTexture(gl.GL_TEXTURE_2D, texture);

    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);

    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_LUMINANCE, @intCast(bitmap.width), @intCast(bitmap.rows), 0, gl.GL_LUMINANCE, gl.GL_UNSIGNED_BYTE, bitmap.buffer);
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0);
    check_gl_err();

    const ft_glyph = self.face.*.glyph;

    const glyph = Glyph{
        .texture = texture,
        .tex_width = bitmap.width,
        .tex_height = bitmap.rows,
        .tex_left = ft_glyph.*.bitmap_left,
        .tex_top = ft_glyph.*.bitmap_top,
        .advance = @intCast(@divFloor(self.face.*.glyph.*.advance.x, 72)),
    };

    self.glyphs.put(key, glyph) catch unreachable;
    return glyph;
}
