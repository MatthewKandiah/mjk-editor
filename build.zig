const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "mjk-editor",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "vendor" } });
    exe.addCSourceFile(.{ .file = .{ .src_path = .{ .owner = b, .sub_path = "vendor/stb_impl.c" } } });
    exe.linkLibC();
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.root_module.addImport("mjk", b.createModule(.{ .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/lib/lib.zig" } } }));
    b.installArtifact(exe);

    const screenshots_exe = b.addExecutable(.{
        .name = "screenshot-test",
        .root_source_file = b.path("src/test/screenshot-tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    screenshots_exe.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "vendor" } });
    screenshots_exe.addCSourceFile(.{ .file = .{ .src_path = .{ .owner = b, .sub_path = "vendor/stb_impl.c" } } });
    screenshots_exe.linkLibC();
    screenshots_exe.linkSystemLibrary("SDL2");
    screenshots_exe.linkSystemLibrary("SDL2_ttf");
    screenshots_exe.root_module.addImport("mjk", b.createModule(.{ .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/lib/lib.zig" } } }));
    b.installArtifact(screenshots_exe);
}
