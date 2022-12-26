const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("bunview", "src/main.zig");

    // Link libc and libc++
    //exe.linkLibC();
    exe.linkLibCpp();

    // Compile and link webview library
    exe.addCSourceFile("deps/webview/webview.cc", &.{
        "-c", "-std=c++11", "-fPIC"
    });
    exe.addIncludePath("deps/webview");

    switch (target.getOs().tag) {
        .windows => {
            //exe.addLibPath(sdkRoot() ++ "/vendor/webview/dll/x64");
        },
        .macos => {
            // b.sysroot = "/home/theseyan/macos12-sdk";
            // exe.addIncludePath("/home/theseyan/macos12-sdk/usr/include");
            // exe.addLibraryPath("/home/theseyan/macos12-sdk/usr/lib");
            // exe.addFrameworkPath("/home/theseyan/macos12-sdk/System/Library/Frameworks");
            exe.linkFramework("WebKit");
        },
        .linux => {
            exe.linkSystemLibrary("gtk+-3.0");
            exe.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => std.debug.panic("Unsupported OS: {s}", .{std.meta.tagName(exe.target.getOsTag())}),
    }

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
}
