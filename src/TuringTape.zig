const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const TuringTapeAddress = struct { i: usize, is_left: bool };

pub const TuringTape = struct {
    allocator: Allocator,
    tape_rh: std.ArrayList(u8),
    tape_lh: std.ArrayList(u8),

    pub fn init(allocator: Allocator) TuringTape {
        const tape_rh = std.ArrayList(u8).init(allocator);
        const tape_lh = std.ArrayList(u8).init(allocator);
        return .{ .allocator = allocator, .tape_rh = tape_rh, .tape_lh = tape_lh };
    }

    pub fn tapeAddress(idx: i128) TuringTapeAddress {
        if (idx >= 0) {
            return .{ .i = @intCast(idx), .is_left = false };
        } else {
            return .{ .i = @intCast(-1 - idx), .is_left = true };
        }
    }

    pub fn getAddr(self: *TuringTape, idx: i128) !*u8 {
        const addr = TuringTape.tapeAddress(idx);
        const tape: *std.ArrayList(u8) = if (addr.is_left) &(self.tape_lh) else &(self.tape_rh);
        // Extend if necessary

        if (tape.items.len < addr.i + 1) {
            const n: usize = addr.i - tape.items.len + 1;
            try tape.appendNTimes(0, n);
        }
        // Return the value address
        return &tape.items[addr.i];
    }

    pub fn get(self: *TuringTape, idx: i128) !u8 {
        const addrv = try self.getAddr(idx);
        return addrv.*;
    }

    pub fn set(self: *TuringTape, idx: i128, v: u8) !void {
        const addrv = try self.getAddr(idx);
        addrv.* = v;
    }

    pub fn deinit(self: TuringTape) void {
        self.tape_rh.deinit();
        self.tape_lh.deinit();
    }
};

test "TuringTape" {
    const allocator = std.heap.page_allocator;
    var tt = TuringTape.init(allocator);
    defer tt.deinit();

    const a1 = TuringTape.tapeAddress(2);
    const a2 = TuringTape.tapeAddress(-4);

    try testing.expect(a1.i == 2);
    try testing.expect(!a1.is_left);

    try testing.expect(a2.i == 3);
    try testing.expect(a2.is_left);

    const pv = try tt.getAddr(0);

    try testing.expect(pv.* == 0);
    try testing.expect(tt.tape_rh.items.len == 1);

    const v = try tt.get(-3);

    try testing.expect(v == 0);
    try testing.expect(tt.tape_lh.items.len == 3);

    try tt.set(0, 1);

    const v2 = try tt.get(0);

    try testing.expect(v2 == 1);
}
