const std = @import("std");

const Item = enum {
    Empty,
    Human,
    Box,
};

const Row = [24]Item;
const Window = [6]Row;

const Loc = packed struct {
    row: u6,
    col: u24,
    item: Item,

    pub const Direction = enum {
        Up,
        Down,
        Left,
        Right,
    };

    pub inline fn move(self: *Loc, comptime direction: Direction) void {
        return switch (direction) {
            .Left => {
                if (self.col != 0) {
                    self.col -= 1;
                }
            },
            .Right => {
                if (self.col != 24 - 1) {
                    self.col += 1;
                }
            },
            .Up => {
                if (self.row != 0) {
                    self.row -= 1;
                }
            },
            .Down => {
                if (self.row != 6 - 1) {
                    self.row += 1;
                }
            },
        };
    }

    pub inline fn random(rnd: *std.rand.Xoshiro256, item: Item) Loc {
        return Loc{
            .row = rnd.random().intRangeAtMost(u6, 0, 5),
            .col = rnd.random().intRangeAtMost(u24, 0, 23),
            .item = item,
        };
    }
};

pub fn main() !void {
    var rnd = std.rand.Xoshiro256.init(0);
    const allocator = std.heap.c_allocator;

    var player = Loc{
        .row = 4,
        .col = 4,
        .item = .Human,
    };

    var box = Loc.random(&rnd, .Box);

    outer: while (true) {
        while (box.row == player.row and player.col == box.col) {
            box = Loc.random(&rnd, .Box);
        }

        var tmp = try makeWindow(&.{ player, box });
        try draw(&tmp);

        var input = (try std.io.getStdIn().reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 1024 * 2048)) orelse continue;
        defer allocator.free(input);

        if (input.len < 1) continue;

        for (input) |c| {
            switch (c) {
                'w' => player.move(.Up),
                'a' => player.move(.Left),
                'd' => player.move(.Right),
                's' => player.move(.Down),
                'q' => break :outer,
                else => void{},
            }
        }
    }
}

pub inline fn makeWindow(locs: []const Loc) !Window {
    var window = std.mem.zeroes(Window);

    for (locs) |loc| {
        window[loc.row][loc.col] = loc.item;
    }

    return window;
}

pub fn draw(window: *Window) !void {
    var writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer writer.flush() catch @panic("OOM");

    for (window) |row| {
        for (row) |item| {
            _ = switch (item) {
                .Human => try writer.write("🤵"),
                .Empty => try writer.write("⬜"),
                .Box => try writer.write("🟫"),
            };
        }

        _ = try writer.write("\n");
    }

    _ = try writer.write("\n");
}
