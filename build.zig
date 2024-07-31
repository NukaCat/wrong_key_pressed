const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "wkp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const free_type = b.addStaticLibrary(.{
        .name = "freetype",
        .target = target,
        .optimize = optimize,
    });

    free_type.addIncludePath(b.path("lib/freetype-2.13.2/include"));
    free_type.addCSourceFiles(.{
        .root = b.path("lib/freetype-2.13.2"),
        .files = &.{
            "builds/windows/ftsystem.c",
            "builds/windows/ftdebug.c",
            "src/autofit/autofit.c",
            "src/base/ftbase.c",
            "src/base/ftbbox.c",
            "src/base/ftbdf.c",
            "src/base/ftbitmap.c",
            "src/base/ftcid.c",
            "src/base/ftfstype.c",
            "src/base/ftgasp.c",
            "src/base/ftglyph.c",
            "src/base/ftgxval.c",
            "src/base/ftinit.c",
            "src/base/ftmm.c",
            "src/base/ftotval.c",
            "src/base/ftpatent.c",
            "src/base/ftpfr.c",
            "src/base/ftstroke.c",
            "src/base/ftsynth.c",
            "src/base/fttype1.c",
            "src/base/ftwinfnt.c",
            "src/bdf/bdf.c",
            "src/bzip2/ftbzip2.c",
            "src/cache/ftcache.c",
            "src/cff/cff.c",
            "src/cid/type1cid.c",
            "src/gzip/ftgzip.c",
            "src/lzw/ftlzw.c",
            "src/pcf/pcf.c",
            "src/pfr/pfr.c",
            "src/psaux/psaux.c",
            "src/pshinter/pshinter.c",
            "src/psnames/psnames.c",
            "src/raster/raster.c",
            "src/sdf/sdf.c",
            "src/sfnt/sfnt.c",
            "src/smooth/smooth.c",
            "src/svg/svg.c",
            "src/truetype/truetype.c",
            "src/type1/type1.c",
            "src/type42/type42.c",
            "src/winfonts/winfnt.c",
        },
    });
    free_type.defineCMacro("FT2_BUILD_LIBRARY", "1");
    free_type.installHeadersDirectory(b.path("lib/freetype-2.13.2/include"), "", .{});
    free_type.linkLibC();

    exe.addIncludePath(b.path("lib/SDL/include"));
    exe.addLibraryPath(b.path("lib/SDL/build/Release"));
    exe.linkSystemLibrary("SDL3");

    exe.addIncludePath(b.path("lib/glew-2.1.0/include"));
    exe.addLibraryPath(b.path("lib/glew-2.1.0/lib/Release/x64"));
    exe.linkSystemLibrary("glew32");

    exe.linkSystemLibrary("OpenGL32");

    exe.linkLibrary(free_type);

    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    b.installFile("lib/SDL/build/Release/SDL3.dll", "bin/SDL3.dll");
    b.installFile("lib/glew-2.1.0/bin/Release/x64/glew32.dll", "bin/glew32.dll");

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}