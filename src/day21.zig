const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const Dir = aoc.Dir(4);

const INPUT = @embedFile("inputs/day21.txt");

pub fn main() !void {
    const result = try part1(INPUT, 64);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}\n", .{result.part1});
    try stdout.print("Part 2: {}\n", .{result.part2});
}

const Cell = union(enum) {
    rock: void,
    garden_e: void,
    garden_u: void,
    fringe: void,
};

fn flood(map: []Cell, stride: usize, steps: usize) void {
    for (0..steps) |_| {
        for (map, 0..) |*cell, idx| {
            if (cell.* == .rock) continue;
            if (cell.* == .garden_e) continue;

            for (aoc.getNeighbours(4, map, idx, stride)) |neighbours| {
                switch (neighbours.char) {
                    .garden_e => cell.* = .fringe,
                    else => {},
                }
            }
        }

        for (map) |*c| {
            if (c.* == .fringe) c.* = .garden_e;
        }
    }
}

fn countCellsFromStart(
    map: []Cell,
    stride: usize,
    even_or_odd: enum { even, odd },
    start_idx: usize,
) i64 {
    const start_row = start_idx / stride;
    const start_col = start_idx % stride;

    var total: i64 = 0;
    for (map, 0..) |cell, idx| {
        switch (cell) {
            .garden_e => {
                const row = idx / stride;
                const col = idx % stride;

                const distance = @max(row, start_row) - @min(row, start_row) + @max(col, start_col) - @min(col, start_col);
                switch (even_or_odd) {
                    .even => if (distance % 2 == 0) {
                        total += 1;
                    },
                    .odd => if (distance % 2 == 1) {
                        total += 1;
                    },
                }
            },
            else => {},
        }
    }
    return total;
}

fn part1(input: []const u8, steps: usize) !struct { part1: i64, part2: i64 } {
    var map_buffer = [_]Cell{.rock} ** (150 * 150); // Approx correct size

    var width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var stride = width + 2;
    var total: usize = stride * 2;

    var input_idx: usize = 0;
    var output_offset: usize = stride + 1;
    while (input_idx + width - 1 < input.len) : (input_idx += width + 1) { // +1 for newline
        for (map_buffer[output_offset .. output_offset + width], input[input_idx .. input_idx + width]) |*out, in| {
            out.* = switch (in) {
                '.' => .garden_u,
                'S' => .garden_e,
                '#' => .rock,
                else => unreachable,
            };
        }
        output_offset += stride;
        total += stride;
    }
    var map = map_buffer[0..total];
    const start_idx = for (map, 0..) |c, idx| {
        if (c == .garden_e) break idx;
    } else unreachable;

    flood(map, stride, steps);

    const part_1 = countCellsFromStart(
        map,
        stride,
        if (steps % 2 == 0) .even else .odd,
        start_idx,
    );

    printMap(map, stride);

    flood(map, stride, 1);
    printMap(map, stride);

    var part_2: i64 = 0;
    return .{ .part1 = part_1, .part2 = part_2 };
}

fn printMap(map: []Cell, stride: usize) void {
    for (map, 0..) |c, idx| {
        if (idx % stride == 0) std.debug.print("\n", .{});
        std.debug.print("{c}", .{switch (c) {
            .garden_e => @as(u8, 'O'),
            .garden_u => '.',
            .fringe => 'f',
            .rock => '#',
        }});
    } else std.debug.print("\n", .{});
}

const TEST_INPUT_1 =
    \\...........
    \\.....###.#.
    \\.###.##..#.
    \\..#.#...#..
    \\....#.#....
    \\.##..S####.
    \\.##..#...#.
    \\.......##..
    \\.##.#.####.
    \\.##..##.##.
    \\...........
;

test "simple test part1" {
    const result = try part1(TEST_INPUT_1, 6);
    try std.testing.expectEqual(@as(i64, 16), result.part1);
    try std.testing.expectEqual(@as(i64, 0), result.part2);
}
