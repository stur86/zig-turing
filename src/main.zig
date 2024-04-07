const std = @import("std");
const cfg = @import("TuringConfig.zig");
const trules = @import("TuringRule.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("Usage: turing-zig <config file>\n", .{});
        return;
    }
    const path = args[1];
    var cfreader = cfg.TuringConfigReader.init(allocator);
    try cfreader.read(path);

    std.debug.print("{any}\n", .{cfreader.config.?.rules});
}

test {
    std.testing.refAllDecls(@This());
}
