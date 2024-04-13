const std = @import("std");
const TuringRule = @import("TuringRule.zig").TuringRule;
const testing = std.testing;
const Allocator = std.mem.Allocator;

const MAX_FILE_LENGTH = 1 << 16;

pub const TuringConfig = struct { states: u8 = 2, symbols: u8 = 2, rules: ?[]TuringRule = null, starting_tape: ?[]u8 = null, starting_tape_zero_index: i128 = 0, max_steps: usize = 1000 };

pub const TuringConfigReader = struct {
    allocator: Allocator,
    parsed: ?std.json.Parsed(TuringConfig) = null,
    config: ?TuringConfig = null,

    pub fn init(allocator: Allocator) TuringConfigReader {
        return .{ .allocator = allocator };
    }

    pub fn read(self: *TuringConfigReader, path: []const u8) !void {
        const data = try std.fs.cwd().readFileAlloc(self.allocator, path, MAX_FILE_LENGTH);
        defer self.allocator.free(data);
        const parsed = try std.json.parseFromSlice(TuringConfig, self.allocator, data, .{ .allocate = .alloc_always });
        self.parsed = parsed;
        self.config = parsed.value;
    }

    pub fn deinit(self: TuringConfigReader) void {
        self.parsed.?.deinit();
    }
};

test "TuringConfig" {
    const allocator = std.testing.allocator;
    const parsed = try std.json.parseFromSlice(TuringConfig, allocator, "{\"states\": 3}", .{});
    const config = parsed.value;

    try testing.expect(config.states == 3);
    try testing.expect(config.symbols == 2);
    try testing.expect(config.rules == null);
    try testing.expect(config.starting_tape == null);
    try testing.expect(config.starting_tape_zero_index == 0);
}
