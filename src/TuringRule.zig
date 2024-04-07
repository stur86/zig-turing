const std = @import("std");
const testing = std.testing;
const TuringModelError = @import("TuringModelError.zig").TuringModelError;

pub const StepDir = enum(i2) {
    LEFT = -1,
    HALT = 0,
    RIGHT = 1,

    pub fn apply(self: StepDir, i: i128) !i128 {
        const res = @addWithOverflow(@intFromEnum(self), i);
        if (res[1] == 1) {
            return TuringModelError.OutOfBounds;
        }
        return res[0];
    }
};

pub const TuringRule = struct {
    state_in: u8 = 0,
    symbol_in: u8 = 0,
    state_out: u8 = 0,
    symbol_out: u8 = 0,
    step: StepDir = StepDir.HALT,

    pub fn apply(self: TuringRule, state: *u8, symbol: *u8, index: i128) !i128 {
        if (self.state_in != state.*) {
            return TuringModelError.WrongRule;
        }
        if (self.symbol_in != symbol.*) {
            return TuringModelError.WrongRule;
        }
        const index_new = try self.step.apply(index);
        state.* = self.state_out;
        symbol.* = self.symbol_out;
        return index_new;
    }
};

test "StepDir" {
    const sleft = StepDir.LEFT;
    const sright = StepDir.RIGHT;
    const ibase: i32 = 3;

    try testing.expect(try sleft.apply(ibase) == 2);
    try testing.expect(try sright.apply(ibase) == 4);

    const imax: i128 = (1 << 127) - 1;

    try testing.expect(sright.apply(imax) == TuringModelError.OutOfBounds);
}

test "TuringRule" {
    const tr: TuringRule = .{ .state_in = 0, .symbol_in = 0, .state_out = 1, .symbol_out = 1, .step = StepDir.RIGHT };

    try testing.expect(tr.state_in == 0);
    try testing.expect(tr.state_out == 1);

    var state: u8 = 0;
    var symbol: u8 = 0;
    var idx: i128 = 5;

    idx = try tr.apply(&state, &symbol, idx);

    try testing.expect(state == 1);
    try testing.expect(symbol == 1);
    try testing.expect(idx == 6);

    // Applying again should cause an error
    try testing.expect(tr.apply(&state, &symbol, idx) == TuringModelError.WrongRule);
    // And now, with the wrong index
    state = 0;
    symbol = 0;
    try testing.expect(tr.apply(&state, &symbol, (1 << 127) - 1) == TuringModelError.OutOfBounds);
}
