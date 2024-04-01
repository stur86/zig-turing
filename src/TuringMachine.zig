const std = @import("std");
const testing = std.testing;

const Allocator = std.mem.Allocator;
const TuringRule = @import("TuringRule.zig").TuringRule;
const TuringModel = @import("TuringModel.zig").TuringModel;
const TuringTape = @import("TuringTape.zig").TuringTape;

pub const TuringMachine = struct {
    idx: i128 = 0,
    cursor_state: u8 = 0,
    model: TuringModel,
    tape: TuringTape,
    allocator: Allocator,

    pub fn init(s_n: u8, sym_n: u8, allocator: Allocator) TuringMachine {
        const model = TuringModel.init(s_n, sym_n, allocator);
        const tape = TuringTape.init(allocator);
        return .{ .allocator = allocator, .model = model, .tape = tape };
    }

    pub fn build(self: *TuringMachine) !void {
        try self.model.build();
    }

    pub fn step(self: *TuringMachine) !bool {
        // Get the current tape symbol
        const sym = try self.tape.getAddr(self.idx);
        // Apply the relevant rule
        const idx = try self.model.applyRule(&self.cursor_state, sym, self.idx);
        if (idx == self.idx) {
            // We're halting
            return true;
        } else {
            self.idx = idx;
        }
        return false;
    }

    pub fn deinit(self: TuringMachine) void {
        self.model.deinit();
        self.tape.deinit();
    }
};

test "TuringMachine" {
    const allocator = std.heap.page_allocator;
    var tm = TuringMachine.init(2, 2, allocator);
    try tm.build();
    defer tm.deinit();

    // Set a rule and apply it
    const trule: TuringRule = .{ .state_in = 0, .symbol_in = 0, .state_out = 1, .symbol_out = 1 };
    try tm.model.setRule(trule);

    const halt = try tm.step();

    try testing.expect(halt);
}
