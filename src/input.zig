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
        var parser = std.json.Parser.init(allocator, false);
        var tree: ?std.json.ValueTree = parser.parse(input) catch |e| switch (e) {
            error.UnexpectedEndOfJson => null,
            else => return e
        };

        const msg = Message{
            .type = tree.?.root.Object.get("type").?.String,
            .data = try allocator.dupeZ(u8, tree.?.root.Object.get("data").?.String),
        };

        // Handle Message
        try runtime.handleMessage(allocator, msg, webv, stdout);

        allocator.free(input);
        parser.deinit();

    }

}