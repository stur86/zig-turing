const std = @import("std");
const cfg = @import("TuringConfig.zig");
const trules = @import("TuringRule.zig");
const TuringMachine = @import("TuringMachine.zig").TuringMachine;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("Usage: turing-zig <config file>\n", .{});
        return;
    }
    const path = args[1];
    var cfreader = cfg.TuringConfigReader.init(allocator);
    try cfreader.read(path);

    if (cfreader.config) |config| {
        var machine = try TuringMachine.fromConfig(config, allocator);

        for (0..config.max_steps) |_| {
            const halt = try machine.step();

            var tapeline = std.ArrayList(u8).init(allocator);
            defer tapeline.deinit();
            try machine.printTape(&tapeline);
            _ = try std.io.getStdOut().write(tapeline.items);

            if (halt) {
                _ = try std.io.getStdOut().write("HALT\n");
                break;
            }
        }
    } else {
        return error{InvalidOrMissingConfig}.InvalidOrMissingConfig;
    }
}

test {
    std.testing.refAllDecls(@This());
}
