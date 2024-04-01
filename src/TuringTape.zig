const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const TuringModelError = @import("TuringModelError.zig").TuringModelError;

const TuringTapeBlock = struct {
    from_idx: i128,
    to_idx: i128,
    items: []u8 = undefined,
    prev: ?*TuringTapeBlock = null,
    next: ?*TuringTapeBlock = null,

    pub fn init(idx0: i128, idx1: i128) TuringTapeBlock {
        return .{ .from_idx = idx0, .to_idx = idx1 };
    }

    pub fn build(self: *TuringTapeBlock, allocator: Allocator) !void {
        if (self.to_idx <= self.from_idx) {
            return TuringModelError.IndexError;
        }
        const bsize: usize = @intCast(self.to_idx - self.from_idx);
        self.items = try allocator.alloc(u8, bsize);
    }

    pub fn deinit(self: TuringTapeBlock, allocator: std.mem.Allocator) void {
        allocator.free(self.items);
    }
};

const TuringTape = struct {
    idx: i128 = 0,
    start_idx: i128 = 0,
    allocator: Allocator,
    block_size: usize,
    first_idx: i128 = 0,
    first_block: ?*TuringTapeBlock = null,
    last_idx: i128 = 0,
    last_block: ?*TuringTapeBlock = null,
    all_blocks: std.ArrayList(*TuringTapeBlock),

    pub fn init(allocator: Allocator, block_size: usize) !TuringTape {
        return .{ .allocator = allocator, .block_size = block_size, .all_blocks = std.ArrayList(*TuringTapeBlock).init(allocator) };
    }

    fn insertFirstBlock(self: *TuringTape, blockp: *TuringTapeBlock) void {
        self.first_block = blockp;
        self.last_block = blockp;
    }

    pub fn appendBlock(self: *TuringTape) !void {
        const blockp = try self.allocator.create(TuringTapeBlock);
        blockp.* = TuringTapeBlock.init(self.last_idx, self.last_idx + self.block_size);
        try self.all_blocks.append(blockp);
        try blockp.build(self.allocator);
        self.last_idx = blockp.to_idx;
        if (self.last_block == null) {
            self.insertFirstBlock(blockp);
        } else {
            self.last_block.?.next = blockp;
            blockp.prev = self.last_block;
            self.last_block = blockp;
        }
    }

    pub fn prependBlock(self: *TuringTape) !void {
        const blockp = try self.allocator.create(TuringTapeBlock);
        blockp.* = TuringTapeBlock.init(self.first_idx - self.block_size, self.first_idx);
        try self.all_blocks.append(blockp);
        try blockp.build(self.allocator);
        self.first_idx = blockp.from_idx;
        if (self.first_block == null) {
            self.insertFirstBlock(blockp);
        } else {
            self.first_block.?.prev = blockp;
            blockp.next = self.first_block;
            self.first_block = blockp;
        }
    }

    pub fn deinit(self: TuringTape) void {
        for (self.all_blocks.items) |b| {
            b.deinit(self.allocator);
            self.allocator.destroy(b);
        }
    }
};

test "TuringTapeBlock" {
    const allocator = std.heap.page_allocator;
    var ttb1 = TuringTapeBlock.init(0, 100);
    try ttb1.build(allocator);
    defer ttb1.deinit(allocator);
    var ttb2 = TuringTapeBlock.init(100, 200);
    try ttb2.build(allocator);
    defer ttb2.deinit(allocator);

    ttb1.next = &ttb2;

    try testing.expect(ttb1.items.len == 100);
    try testing.expect(ttb1.next.?.items.len == 100);
}

test "TuringTape" {
    const allocator = std.heap.page_allocator;
    var tt = try TuringTape.init(allocator, 100);
    defer tt.deinit();

    try testing.expect(tt.idx == 0);

    try tt.appendBlock();

    try testing.expect(tt.first_idx == 0);
    try testing.expect(tt.last_idx == 100);
    try testing.expect(tt.last_block.?.prev == null);
    try testing.expect(tt.first_block.?.next == null);

    try tt.appendBlock();

    try testing.expect(tt.first_idx == 0);
    try testing.expect(tt.last_idx == 200);
    try testing.expect(tt.last_block.?.prev == tt.first_block);
    try testing.expect(tt.first_block.?.next == tt.last_block);

    try tt.prependBlock();

    try testing.expect(tt.first_idx == -100);
    try testing.expect(tt.last_idx == 200);
    try testing.expect(tt.last_block.?.prev == tt.first_block.?.next);
}
