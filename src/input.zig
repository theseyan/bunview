// Receives and handles input from stdin

const std = @import("std");
const wv = @import("webview.zig");
const json = std.json;
const runtime = @import("runtime.zig");
const debug = @import("debug.zig");

// Struct of a individual message passed through stdin
pub const Message = struct {
    type: []const u8,
    data: [:0]const u8
};

// Stdin listener
// Polls for input from the parent process
pub fn listenStdin(allocator: std.mem.Allocator, webv: *wv.View, stdout: std.fs.File.Writer) !void {

    debug.print("IO thread started", .{});
    const stdin = std.io.getStdIn().reader();

    // Each line should not exceed 1 MiB
    while(try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024 * 1024 * 1024)) |input| {

        // Parse message JSON
        const msg = x: {
            var stream = json.TokenStream.init(input);
            const res = json.parse(Message, &stream, .{.allocator = allocator, .ignore_unknown_fields = true});
            break :x res catch |e| {
                return e;
            };
        };

        // Handle Message
        try runtime.handleMessage(allocator, msg, webv, stdout);

        allocator.free(input);

    }

}