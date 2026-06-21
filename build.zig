const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.option(std.builtin.OptimizeMode, "optimize", "optimization mode") orelse .ReleaseFast;

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const blip_mod = b.createModule(.{
        .root_source_file = b.path("extern/blip_buf/blip_buf.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .sanitize_c = .off,
    });
    blip_mod.addCSourceFile(.{ .file = b.path("extern/blip_buf/blip_buf.c"), .flags = &.{"-fwrapv"} });

    const mod = b.addModule("zig_nes_emu", .{
        .root_source_file = b.path("src/core/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raylib", .module = raylib },
            .{ .name = "blip", .module = blip_mod },
        },
    });
    mod.linkLibrary(raylib_artifact);

    const mibu_dep = b.dependency("mibu", .{});

    const window_exe = b.addExecutable(.{
        .name = "window_nes_emu",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/window_main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zig_nes_emu", .module = mod },
                .{ .name = "raylib", .module = raylib },
                .{ .name = "blip", .module = blip_mod },
            },
        }),
    });
    window_exe.root_module.linkLibrary(raylib_artifact);
    window_exe.root_module.addImport("mibu", mibu_dep.module("mibu"));

    const window_step = b.step("window", "Compile the window GUI emulator binary");
    window_step.dependOn(&b.addInstallArtifact(window_exe, .{}).step);

    const run_window_cmd = b.addRunArtifact(window_exe);
    run_window_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_window_cmd.addArgs(args);

    const run_window_step = b.step("run-window", "Compile and run the window GUI emulator");
    run_window_step.dependOn(&run_window_cmd.step);

    const terminal_exe = b.addExecutable(.{
        .name = "terminal_nes_emu",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/terminal_main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zig_nes_emu", .module = mod },
                .{ .name = "raylib", .module = raylib },
                .{ .name = "blip", .module = blip_mod },
            },
        }),
    });
    terminal_exe.root_module.linkLibrary(raylib_artifact);
    terminal_exe.root_module.addImport("mibu", mibu_dep.module("mibu"));

    const terminal_step = b.step("terminal", "Compile the text terminal emulator binary");
    terminal_step.dependOn(&b.addInstallArtifact(terminal_exe, .{}).step);

    const run_terminal_cmd = b.addRunArtifact(terminal_exe);
    run_terminal_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_terminal_cmd.addArgs(args);

    const run_terminal_step = b.step("run-terminal", "Compile and run the text terminal emulator");
    run_terminal_step.dependOn(&run_terminal_cmd.step);

    b.installArtifact(window_exe);
    b.installArtifact(terminal_exe);
}
