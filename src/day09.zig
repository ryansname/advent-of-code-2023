const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

fn iter_lines(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, '\n');
}

fn iter_tokens(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, ' ');
}

const INPUT = @embedFile("inputs/day09.txt");

pub fn main() !void {
    const result = try part1(INPUT);
    log.info("Part 1: {}", .{result.part1});

    // const result_2 = try part_2(INPUT);
    log.info("Part 2: {}", .{result.part2});
}

fn calculateNext(values: []i64) i64 {
    for (values) |v| {
        if (v != 0) break;
    } else {
        // log.err("Returning 0", .{});
        return 0;
    }

    var next_buf: [64]i64 = undefined;
    var next = next_buf[0 .. values.len - 1];

    for (values[0 .. values.len - 1], values[1..], next) |v1, v2, *n| {
        n.* = v2 - v1;
    }
    log.info("Calculated {any}", .{next});

    const last = values[values.len - 1];
    const calculated = calculateNext(next);
    // log.err("returning {} + {}", .{ last, calculated });
    return last + calculated;
}

fn calculatePrevious(values: []i64) i64 {
    for (values) |v| {
        if (v != 0) break;
    } else {
        // log.err("Returning 0", .{});
        return 0;
    }

    var next_buf: [64]i64 = undefined;
    var next = next_buf[0 .. values.len - 1];

    for (values[0 .. values.len - 1], values[1..], next) |v1, v2, *n| {
        n.* = v2 - v1;
    }
    // log.info("Calculated {any}", .{next});

    const first = values[0];
    const calculated = calculatePrevious(next);
    // log.err("returning {} + {}", .{ last, calculated });
    return first - calculated;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var part_1: i64 = 0;
    var part_2: i64 = 0;

    var lines = iter_lines(input);
    var line_nums_buf: [64]i64 = undefined;
    var line_nums_idx: usize = undefined;
    while (lines.next()) |line| {
        line_nums_idx = 0;
        var token_iter = iter_tokens(line);
        while (token_iter.next()) |token| : (line_nums_idx += 1) {
            line_nums_buf[line_nums_idx] = try fmt.parseInt(i64, token, 10);
        }
        part_1 += calculateNext(line_nums_buf[0..line_nums_idx]);
        part_2 += calculatePrevious(line_nums_buf[0..line_nums_idx]);
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT =
    \\0 3 6 9 12 15
    \\1 3 6 10 15 21
    \\10 13 16 21 30 45
    \\
;

test "simple test" {
    try std.testing.expectEqual(@as(i64, 18), (try part1("0 3 6 9 12 15")).part1);
    try std.testing.expectEqual(@as(i64, 28), (try part1("1 3 6 10 15 21")).part1);
    try std.testing.expectEqual(@as(i64, 68), (try part1("10 13 16 21 30 45")).part1);
    try std.testing.expectEqual(@as(i64, 114), (try part1(TEST_INPUT)).part1);

    try std.testing.expectEqual(@as(i64, -3), (try part1("0 3 6 9 12 15")).part2);
    try std.testing.expectEqual(@as(i64, 0), (try part1("1 3 6 10 15 21")).part2);
    try std.testing.expectEqual(@as(i64, 5), (try part1("10 13 16 21 30 45")).part2);
    try std.testing.expectEqual(@as(i64, 2), (try part1(TEST_INPUT)).part2);
}
