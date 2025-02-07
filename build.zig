const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "mjk-editor",
        .root_source_file = b.path("src/lib/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "mjk-editor",
        .root_source_file = b.path("src/main/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    b.installArtifact(exe);
}
