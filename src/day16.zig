const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const Dir = aoc.Dir(4);

const INPUT = @embedFile("inputs/day16.txt");

fn printMap(map: []Tile, stride: usize) void {
    const N = @intFromEnum(Dir.N);
    const E = @intFromEnum(Dir.E);
    const S = @intFromEnum(Dir.S);
    const W = @intFromEnum(Dir.W);
    for (map, 0..) |tile, idx| {
        if (idx % stride == 0) {
            std.debug.print("\n", .{});
        }

        if (!tile.isEnergized()) {
            std.debug.print(" ", .{});
            continue;
        }

        const char: []const u8 = switch (tile) {
            .black_hole => " ",
            .nothing => ".",
            .beam => |b| blk: {
                if (b[N] or b[S]) {
                    if (b[E] or b[W]) {
                        break :blk "┼";
                    } else {
                        break :blk "│";
                    }
                } else {
                    break :blk "─";
                }
            },
            .mirror_ld => "╲",
            .mirror_lu => "╱",
            .splitter_vertical => "╫",
            .splitter_horizontal => "╪",
        };
        std.debug.print("{s}", .{char});
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    const result = try part1(INPUT);

    std.debug.assert(result.part1 > 7343);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const Tile = union(enum) {
    black_hole: void, // Light can't escape
    nothing: void,
    beam: [4]bool, // The beam and up to two directions
    mirror_ld: bool, // Mirror left down (/)
    mirror_lu: bool, // Mirror left up (\)
    splitter_vertical: bool,
    splitter_horizontal: bool,

    fn isEnergized(self: Tile) bool {
        return switch (self) {
            .black_hole, .nothing => false,
            .beam => true,
            .mirror_ld, .mirror_lu, .splitter_vertical, .splitter_horizontal => |energized| energized,
        };
    }

    fn setBeam(self: *Tile, dir: Dir, map: []Tile, idx: usize, stride: usize) void {
        switch (self.*) {
            .beam => |*b| b[@intFromEnum(dir)] = true,
            .nothing => {
                self.* = .{ .beam = .{false} ** 4 };
                self.beam[@intFromEnum(dir)] = true;
            },
            .black_hole => {},
            .mirror_ld => |*tile| {
                tile.* = true;
                switch (dir) {
                    .N => setBeamInDirection(map, stride, .W, idx),
                    .W => setBeamInDirection(map, stride, .N, idx),
                    .S => setBeamInDirection(map, stride, .E, idx),
                    .E => setBeamInDirection(map, stride, .S, idx),
                }
            },
            .mirror_lu => |*tile| {
                tile.* = true;
                switch (dir) {
                    .N => setBeamInDirection(map, stride, .E, idx),
                    .E => setBeamInDirection(map, stride, .N, idx),
                    .S => setBeamInDirection(map, stride, .W, idx),
                    .W => setBeamInDirection(map, stride, .S, idx),
                }
            },
            .splitter_vertical => |*tile| {
                tile.* = true;
                switch (dir) {
                    .E, .W => {
                        setBeamInDirection(map, stride, .N, idx);
                        setBeamInDirection(map, stride, .S, idx);
                    },
                    inline else => setBeamInDirection(map, stride, dir, idx),
                }
            },
            .splitter_horizontal => |*tile| {
                tile.* = true;
                switch (dir) {
                    .N, .S => {
                        setBeamInDirection(map, stride, .E, idx);
                        setBeamInDirection(map, stride, .W, idx);
                    },
                    inline else => setBeamInDirection(map, stride, dir, idx),
                }
            },
        }
    }
};

fn setBeamInDirection(map: []Tile, stride: usize, dir: Dir, src_idx: usize) void {
    const dest_idx = aoc.indexForDir(dir, src_idx, stride);
    map[dest_idx].setBeam(dir, map, dest_idx, stride);
}

fn isBeamEnteringFrom(map: []Tile, stride: usize, dir: Dir, idx: usize) bool {
    const entry_idx = aoc.indexForDir(dir, idx, stride);
    return switch (map[entry_idx]) {
        .black_hole, .nothing => false,
        .beam => |b| b[0] == dir.inverse() or b[1] == dir.inverse(),
        .mirror_ld => switch (dir) {
            .N => isBeamEnteringFrom(map, stride, .E, entry_idx),
            .E => isBeamEnteringFrom(map, stride, .N, entry_idx),
            .S => isBeamEnteringFrom(map, stride, .W, entry_idx),
            .W => isBeamEnteringFrom(map, stride, .S, entry_idx),
        },
        .mirror_lu => switch (dir) {
            .N => isBeamEnteringFrom(map, stride, .W, entry_idx),
            .W => isBeamEnteringFrom(map, stride, .N, entry_idx),
            .S => isBeamEnteringFrom(map, stride, .E, entry_idx),
            .E => isBeamEnteringFrom(map, stride, .S, entry_idx),
        },
        .splitter_vertical => switch (dir) {
            .N => isBeamEnteringFrom(map, stride, .W, entry_idx) or isBeamEnteringFrom(map, stride, .N, entry_idx) or isBeamEnteringFrom(map, stride, .E, entry_idx),
            .S => isBeamEnteringFrom(map, stride, .W, entry_idx) or isBeamEnteringFrom(map, stride, .S, entry_idx) or isBeamEnteringFrom(map, stride, .E, entry_idx),
            .W, .E => false,
        },
        .splitter_horizontal => switch (dir) {
            .E => isBeamEnteringFrom(map, stride, .E, entry_idx) or isBeamEnteringFrom(map, stride, .N, entry_idx) or isBeamEnteringFrom(map, stride, .S, entry_idx),
            .W => isBeamEnteringFrom(map, stride, .W, entry_idx) or isBeamEnteringFrom(map, stride, .N, entry_idx) or isBeamEnteringFrom(map, stride, .S, entry_idx),
            .N, .S => false,
        },
    };
}

fn tick(map: []Tile, stride: usize) void {
    for (map, 0..) |tile, idx| {
        switch (tile) {
            .black_hole => {},
            .nothing => {},
            .beam => |dirs| for (dirs, 0..) |enabled, dir_ordinal| if (enabled) setBeamInDirection(map, stride, @enumFromInt(dir_ordinal), idx),
            else => {},
        }
    }
    // std.debug.print("{c}[2J{c}[H]", .{ 0o33, 0o33 });
    // printMap(map, stride);
}

fn getEnergyWithSeed(map_init: []const Tile, stride: usize, seed_idx: usize, seed_dir: Dir) i64 {
    var map_buf: [256 * 256]Tile = undefined;
    var map = map_buf[0..map_init.len];
    @memcpy(map, map_init);

    setBeamInDirection(map, stride, seed_dir, seed_idx);

    var previous_energized: i64 = 0;
    var energized: i64 = 1;
    while (energized != previous_energized) {
        // A bit of a hack, tick 10 times before checking for stability, as a beam crossing otherwise would not increase energised-ness
        for (0..10) |_| tick(map, stride);

        previous_energized = energized;
        energized = 0;
        for (map) |t| energized += if (t.isEnergized()) 1 else 0;
    }
    std.debug.print("{c}[2J{c}[H]", .{ 0o33, 0o33 });
    printMap(map, stride);
    return energized;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var map_buffer = [_]Tile{.black_hole} ** (150 * 150); // Approx correct size

    var width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var stride = width + 2;
    var total: usize = stride * 2;

    var input_idx: usize = 0;
    var output_offset: usize = stride + 1;
    while (input_idx + width - 1 < input.len) : (input_idx += width + 1) { // +1 for newline
        for (map_buffer[output_offset .. output_offset + width], input[input_idx .. input_idx + width]) |*out, in| {
            out.* = switch (in) {
                '.' => .nothing,
                '/' => .{ .mirror_lu = false },
                '\\' => .{ .mirror_ld = false },
                '-' => .{ .splitter_horizontal = false },
                '|' => .{ .splitter_vertical = false },
                else => unreachable,
            };
        }
        output_offset += stride;
        total += stride;
    }
    var map = map_buffer[0..total];

    const part_1 = getEnergyWithSeed(map, stride, stride, .E);

    var part_2: i64 = part_1;
    for (0..map.len / stride) |row| {
        part_2 = @max(part_2, getEnergyWithSeed(map, stride, stride * row, .E));
        part_2 = @max(part_2, getEnergyWithSeed(map, stride, stride * (row + 1) - 1, .W));
    }
    for (0..stride) |col| {
        part_2 = @max(part_2, getEnergyWithSeed(map, stride, col, .S));
        part_2 = @max(part_2, getEnergyWithSeed(map, stride, map.len - stride + 1 + col, .N));
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\.|...\....
    \\|.-.\.....
    \\.....|-...
    \\........|.
    \\..........
    \\.........\
    \\..../.\\..
    \\.-.-/..|..
    \\.|....-|.\
    \\..//.|....
;

test "simple test part1" {
    const result = try part1(TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 46), result.part1);
    try std.testing.expectEqual(@as(i64, 51), result.part2);
}
