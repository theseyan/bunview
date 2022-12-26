const std = @import("std");

// Whether debug mode is enabled
pub var debug = true;

// Starting timestamp for measuring app lifetime
pub var startTime: i64 = undefined;

// Prints a debug message
pub fn print(comptime msg: []const u8, args: anytype) void {

    if(debug)
        std.debug.print("(native:{any})\t" ++ msg ++ "", .{std.Thread.getCurrentId()} ++ args);

}