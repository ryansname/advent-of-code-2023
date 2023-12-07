const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day03.txt");

pub fn main() !void {
    const result = try parts(INPUT);
    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

fn getNeighbouringPart(buffer: []const u8, i: usize, stride: usize) ?struct { char: u8, idx: usize } {
    const offsets = .{
        i - stride,
        i - stride - 1,
        i - stride + 1,
        i + stride,
        i + stride - 1,
        i + stride + 1,
        i - 1,
        i + 1,
    };

    inline for (offsets) |d| {
        if (!ascii.isDigit(buffer[d]) and buffer[d] != '.') return .{ .char = buffer[d], .idx = d };
    }

    return null;
}

fn parts(input: []const u8) !struct { part1: u64, part2: u64 } {
    var buffer = [_]u8{'.'} ** (150 * 150); // Approx correct size
    var neighbours = [_]?u64{null} ** buffer.len;

    var width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var stride = width + 2;
    var total: usize = stride * 2;
    var first_idx = stride + 1;

    var input_idx: usize = 0;
    var output_offset: usize = first_idx;
    while (input_idx + width - 1 < input.len) : (input_idx += width + 1) { // +1 for newline
        @memcpy(buffer[output_offset .. output_offset + width], input[input_idx .. input_idx + width]);
        output_offset += stride;
        total += stride;
    }

    var part_number: u64 = undefined;
    var part_1: u64 = 0;
    var part_2 = part_1;

    var is_part_number = false;
    var gear_idx: ?usize = 0;
    var in_number = false;
    for (buffer[0..total], 0..) |c, i| switch (c) {
        '0'...'9' => {
            if (!in_number) {
                in_number = true;
                part_number = 0;
                gear_idx = null;
                is_part_number = false;
            }
            part_number = part_number * 10 + c - '0';

            if (getNeighbouringPart(&buffer, i, stride)) |part_deets| {
                is_part_number = true;
                if (part_deets.char == '*') gear_idx = part_deets.idx;
            }
        },
        else => {
            if (in_number) {
                // log.err("Got number {} | is part? {} | gear idx? {any} | other part number: {any}", .{ part_number, is_part_number, gear_idx, neighbours[gear_idx orelse 0] });
                in_number = false;
                if (is_part_number) {
                    part_1 += part_number;
                    if (gear_idx) |g| {
                        if (neighbours[g]) |other_part_number| {
                            part_2 += other_part_number * part_number;
                        } else {
                            neighbours[g] = part_number;
                        }
                    }
                }
            }
        },
    };

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT =
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#...
    \\617*......
    \\.....+.58.
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
;

test "simple test" {
    const results = try parts(TEST_INPUT);
    try std.testing.expectEqual(@as(u64, 4361), results.part1);
    try std.testing.expectEqual(@as(u64, 467835), results.part2);
}
