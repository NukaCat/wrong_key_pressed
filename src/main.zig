const std = @import("std");

const sdl = @cImport({
    @cInclude("SDL3/sdl.h");
});

const gl = @cImport({
    @cInclude("GL/glew.h");
    @cInclude("GL/gl.h");
});

const common = @import("common.zig");
const render = @import("render.zig");

pub fn main() !void {
    const result = sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_WINDOW_OPENGL);
    if (result != 0) {
        return error.SDLInitFailed;
    }
    defer sdl.SDL_Quit();

    const window_width = 1280;
    const window_height = 720;

    const wind = sdl.SDL_CreateWindow("WKP", window_width, window_height, sdl.SDL_WINDOW_OPENGL);
    defer sdl.SDL_DestroyWindow(wind);

    const sdl_ctx = sdl.SDL_GL_CreateContext(wind);
    if (sdl_ctx == null) {
        return error.SDLCreateCtxFail;
    }
    defer _ = sdl.SDL_GL_DeleteContext(sdl_ctx);

    if (gl.glewInit() != gl.GLEW_OK) {
        return error.GlGlewInitError;
    }

    var rend = try render.init();

    while (true) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_EVENT_QUIT) {
                return;
            }
        }

        rend.start_frame(window_width, window_height);
        rend.draw_text("Hello, World!", 100, 100, 24);
        rend.draw_text("Hello, Second!ggg", 100, 132, 24);

        _ = sdl.SDL_GL_SwapWindow(wind);

        sdl.SDL_Delay(16);
    }
}
