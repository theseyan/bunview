// Bunview Server

const std = @import("std");
const wv = @import("webview.zig");
const input = @import("input.zig");
const debug = @import("debug.zig");

// Allocator
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var arena = std.heap.ArenaAllocator.init(gpa.allocator());
var allocator = arena.allocator();
var view: *wv.View = undefined;
var stdout: std.fs.File.Writer = undefined;

// Called from webview JS context with events
fn internalCallback(ctx: *wv.CallbackContext, data: []const u8) void {
    _ = ctx;

    // Pass through data back to Bun
    stdout.print("{s}", .{data}) catch |e| @panic(@errorName(e));
}

pub fn main() !void {

    debug.print("Main thread started", .{});

    // Get a handle to stdout writer
    // It has to be blocking because of (probably) a bug with the event loop
    var stdoutHandle = std.io.getStdOut();
    stdoutHandle.intended_io_mode = .blocking;
    stdout = stdoutHandle.writer();

    // Create Webview instance
    view = wv.View.create(true, null) catch |e| @panic(@errorName(e));
    var ctx = wv.CallbackContext{.view = view};

    // Start listening to stdin on a new thread
    var thread = try std.Thread.spawn(.{}, input.listenStdin, .{allocator, view, stdout});
    thread.detach();

    // Bind internal callback events handler
    view.bind("__bv_internal_callback", internalCallback, &ctx);

    // Register preload JS
    view.init(@embedFile("js/preload.js"));

    // Set empty defaults
    view.setTitle("");
    view.setSize(500, 500, .none);
    view.navigate("data:text/html,<html></html>");

    // Emit "ready" event
    try stdout.print(
        \\{{
        \\  "type": "event",
        \\  "data": "{{\"event\": \"ready\"}}"
        \\}}
    , .{});

    // Start webview thread
    view.run();

    // Webview stopped, destroy it and emit 'close' event
    view.destroy();
    stdout.print(
        \\{{
        \\  "type": "event",
        \\  "data": "{{\"event\": \"close\"}}"
        \\}}
    , .{}) catch |e| @panic(@errorName(e));

}