// Parses and runs commands/messages
// Provides initialization functions

const std = @import("std");
const wv = @import("webview.zig");
const View = wv.View;
const Message = @import("input.zig").Message;
const debug = @import("debug.zig");

var allocator: std.mem.Allocator = undefined;
var stdout: std.fs.File.Writer = undefined;

pub const BindContext = struct {
    view: *View,
    id: []const u8,

    pub fn getWebView(ctx: *BindContext) *View {
        return ctx.view;
    }
};

pub const WebviewCommand = struct {
    view: *View,
    type: []const u8,
    data: [:0]const u8,

    pub fn getWebView(ctx: *BindContext) *View {
        return ctx.view;
    }
};

// Stores allocated argument buffers
var argBuffer: ?[:0]const u8 = null;

fn bindCallback(seq: [*c]const u8, req: [*c]const u8, data: ?*anyopaque) callconv(.C) void {
    var dataPtr = @ptrCast(*BindContext, @alignCast(@alignOf(BindContext), data.?));
    const message = allocator.dupeZ(u8, req[0..std.mem.indexOfSentinel(u8, 0, req):0]) catch @panic("out of memory!");

    // Free previous buffer, if any
    if(argBuffer != null) allocator.free(argBuffer.?);
    argBuffer = message;

    // Resolve the pending promise
    dataPtr.getWebView().webview_return(seq, 0, "{}");
    defer allocator.destroy(dataPtr);

    // Pass through data back to Bun
    stdout.print(
        \\{{
        \\  "type": "bindCallback",
        \\  "id": {s},
        \\  "data": {s}
        \\}}
    , .{dataPtr.id, message}) catch |e| @panic(@errorName(e));
}

fn setTitle(view: *View, data: ?*anyopaque) callconv(.C) void {
    var dataPtr = @ptrCast(*WebviewCommand, @alignCast(@alignOf(WebviewCommand), data.?));
    view.setTitle(dataPtr.data);
    defer allocator.destroy(dataPtr);
}

// Handles individual messages and executes them
pub fn handleMessage(alloc: std.mem.Allocator, message: Message, webv: *View, stdo: std.fs.File.Writer) !void {

    allocator = alloc;
    stdout = stdo;

    // bind() function
    if(std.mem.eql(u8, message.type, "bind") == true) {
        var parts = std.mem.split(u8, message.data, ":");
        const id = parts.next().?;
        const name = parts.next().?;
        const nameZ = try allocator.dupeZ(u8, name);

        var ctx = try allocator.create(BindContext);
        ctx.* = BindContext{
            .view = webv,
            .id = id
        };

        defer allocator.free(nameZ);

        // Bind the function
        webv.webview_bind(nameZ, bindCallback, ctx);
    }

    // setTitle() function
    if(std.mem.eql(u8, message.type, "setTitle") == true) {
        var ctx = try allocator.create(WebviewCommand);
        ctx.* = WebviewCommand{
            .view = webv,
            .type = message.type,
            .data = message.data
        };
        webv.dispatch(setTitle, ctx);
    }

    // setSize() function
    // Format is width:height:hint
    if(std.mem.eql(u8, message.type, "setSize") == true) {
        // Split into parts
        var parts = std.mem.split(u8, message.data, ":");

        // Parse height & width
        const width = try std.fmt.parseUnsigned(u16, parts.next().?, 10);
        const height = try std.fmt.parseUnsigned(u16, parts.next().?, 10);
        const hint = try std.fmt.parseUnsigned(c_int, parts.next().?, 10);

        webv.setSize(width, height, @intToEnum(wv.SizeHint, hint));
    }

    // navigate() function
    if(std.mem.eql(u8, message.type, "navigate") == true) {
        webv.navigate(message.data);
    }

    // eval() function
    if(std.mem.eql(u8, message.type, "eval") == true) {
        webv.eval(message.data);
    }

    // init() function
    if(std.mem.eql(u8, message.type, "init") == true) {
        webv.init(message.data);
    }

}