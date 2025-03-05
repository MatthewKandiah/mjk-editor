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
    b.installArtifact(exe);

    const generate_screenshots_exe = b.addExecutable(.{
        .name = "generate-screenshots",
        .root_source_file = b.path("src/generateScreenshots.zig"),
        .target = target,
        .optimize = optimize,
    });
    generate_screenshots_exe.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "vendor" } });
    generate_screenshots_exe.addCSourceFile(.{ .file = .{ .src_path = .{ .owner = b, .sub_path = "vendor/stb_impl.c" } } });
    generate_screenshots_exe.linkLibC();
    generate_screenshots_exe.linkSystemLibrary("SDL2");
    generate_screenshots_exe.linkSystemLibrary("SDL2_ttf");
    b.installArtifact(generate_screenshots_exe);

    const check_screenshots_exe = b.addExecutable(.{
        .name = "check-screenshots",
        .root_source_file = b.path("src/checkScreenshots.zig"),
        .target = target,
        .optimize = optimize,
    });
    check_screenshots_exe.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "vendor" } });
    check_screenshots_exe.addCSourceFile(.{ .file = .{ .src_path = .{ .owner = b, .sub_path = "vendor/stb_impl.c" } } });
    check_screenshots_exe.linkLibC();
    check_screenshots_exe.linkSystemLibrary("SDL2");
    check_screenshots_exe.linkSystemLibrary("SDL2_ttf");
    b.installArtifact(check_screenshots_exe);
}
