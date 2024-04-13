const std = @import("std");
const testing = std.testing;

const Allocator = std.mem.Allocator;
const TuringRule = @import("TuringRule.zig").TuringRule;
const TuringModel = @import("TuringModel.zig").TuringModel;
const TuringTape = @import("TuringTape.zig").TuringTape;
const TuringConfig = @import("TuringConfig.zig").TuringConfig;

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

    pub fn fromConfig(config: TuringConfig, allocator: Allocator) !TuringMachine {
        const s_n: u8 = config.states;
        const sym_n: u8 = config.symbols;
        var model = TuringModel.init(s_n, sym_n, allocator);
        var tape = TuringTape.init(allocator);

        try model.build();

        // Add the rules
        if (config.rules) |rules| {
            for (rules) |rule| {
                try model.setRule(rule);
            }
        }

        // Set the initial tape
        // if (config.starting_tape) {}
        if (config.starting_tape) |stape| {
            const idx0 = config.starting_tape_zero_index;
            for (0..stape.len) |idx| {
                try tape.set(idx - idx0, stape[idx]);
            }
        }

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
    try testing.expect(tm.cursor_state == 1);
    try testing.expect(try tm.tape.get(0) == 1);
}

test "TuringMachineFromConfig" {
    const allocator: Allocator = std.heap.page_allocator;
    const rules: []TuringRule = try allocator.alloc(TuringRule, 1);
    defer allocator.free(rules);
    rules[0] = .{ .state_in = 0, .symbol_in = 1, .state_out = 1, .symbol_out = 2 };

    var tape: [3]u8 = .{ 0, 1, 0 };

    const config: TuringConfig = .{ .states = 2, .symbols = 3, .rules = rules, .starting_tape = &tape, .starting_tape_zero_index = 1 };
    const machine: TuringMachine = try TuringMachine.fromConfig(config, allocator);

    try testing.expect(machine.model.states_n == 2);
    try testing.expect(machine.model.symbols_n == 3);
    try testing.expect(machine.model.ruleset.len == 6);
    try testing.expect(machine.model.ruleset[1].state_out == 1);
    try testing.expect(machine.model.ruleset[1].symbol_out == 2);
    try testing.expect(std.mem.eql(u8, machine.tape.tape_rh.items, &[2]u8{ 1, 0 }));
    try testing.expect(std.mem.eql(u8, machine.tape.tape_lh.items, &[1]u8{0}));
}
