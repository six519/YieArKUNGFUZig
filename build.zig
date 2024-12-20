const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "kungfu",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    b.installArtifact(exe);

    exe.linkSystemLibrary("raylib");
    exe.linkLibC();

    b.installDirectory(.{
        .source_dir = b.path("assets"),
        .install_dir = .{
            .custom = "bin/assets",
        },
        .install_subdir = "",
    });

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
