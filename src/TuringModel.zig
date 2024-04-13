const std = @import("std");
const testing = std.testing;

const TuringModelError = @import("TuringModelError.zig").TuringModelError;
const turing_rule = @import("TuringRule.zig");
const TuringRule = turing_rule.TuringRule;
const StepDir = turing_rule.StepDir;

pub const TuringModel = struct {
    states_n: u8,
    symbols_n: u8,
    allocator: std.mem.Allocator,
    ruleset: []TuringRule,

    pub fn init(s_n: u8, sym_n: u8, alloc: std.mem.Allocator) TuringModel {
        return .{ .states_n = s_n, .symbols_n = sym_n, .allocator = alloc, .ruleset = undefined };
    }

    pub fn build(self: *TuringModel) !void {
        const size = self.states_n * self.symbols_n;
        var ruleset = try self.allocator.alloc(TuringRule, size);

        for (0..ruleset.len) |i| {
            const sym_n: u8 = @truncate(i % self.states_n);
            const s_n: u8 = @truncate((i - sym_n) / self.states_n);
            ruleset[i] = .{ .state_in = s_n, .symbol_in = sym_n, .state_out = s_n, .symbol_out = sym_n, .step = StepDir.HALT };
        }

        self.ruleset = ruleset;
    }

    fn checkState(self: TuringModel, s_n: u8) !void {
        if (s_n >= self.states_n) {
            return TuringModelError.InvalidState;
        }
    }

    fn checkSymbol(self: TuringModel, sym_n: u8) !void {
        if (sym_n >= self.symbols_n) {
            return TuringModelError.InvalidSymbol;
        }
    }

    pub fn setRule(self: TuringModel, rule: TuringRule) !void {
        const s_n = rule.state_in;
        const sym_n = rule.symbol_in;

        try self.checkState(s_n);
        try self.checkSymbol(sym_n);
        try self.checkState(rule.state_out);
        try self.checkSymbol(rule.symbol_out);

        self.ruleset[s_n * self.symbols_n + sym_n] = rule;
    }

    pub fn getRule(self: TuringModel, s_n: u8, sym_n: u8) !TuringRule {
        try self.checkState(s_n);
        try self.checkSymbol(sym_n);

        return self.ruleset[s_n * self.symbols_n + sym_n];
    }

    pub fn applyRule(self: TuringModel, s_n: *u8, sym_n: *u8, idx: i128) !i128 {
        const rule = try self.getRule(s_n.*, sym_n.*);
        return try rule.apply(s_n, sym_n, idx);
    }

    pub fn deinit(self: TuringModel) void {
        self.allocator.free(self.ruleset);
    }
};

test "TuringModel" {
    const allocator = std.testing.allocator;
    var tm = TuringModel.init(4, 5, allocator);
    try tm.build();
    defer tm.deinit();

    try testing.expect(tm.states_n == 4);
    try testing.expect(tm.symbols_n == 5);
    try testing.expect(tm.ruleset.len == 20);

    // Try assigning a rule
    const tr: TuringRule = .{ .state_in = 0, .symbol_in = 0, .state_out = 1, .symbol_out = 1, .step = StepDir.RIGHT };

    try tm.setRule(tr);

    var s_n: u8 = 0;
    var sym_n: u8 = 0;
    try testing.expect((try tm.getRule(s_n, sym_n)).state_out == 1);
    try testing.expect((try tm.applyRule(&s_n, &sym_n, 0)) == 1);
    try testing.expect(s_n == 1);
    try testing.expect(sym_n == 1);

    // Check some errors instead
    try testing.expect(tm.getRule(6, 0) == TuringModelError.InvalidState);
    try testing.expect(tm.getRule(0, 6) == TuringModelError.InvalidSymbol);
}
