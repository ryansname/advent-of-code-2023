const log = std.log;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day1.txt");

pub fn main() !void {
    log.info("Part 1: {}", .{try part1(undefined, INPUT)});
    log.info("Part 2: {}", .{try part2(undefined, INPUT)});
    log.info("Part 2 (short): {}", .{try part2Short(undefined, INPUT)});
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !u64 {
    _ = alloc;

    var sum: u64 = 0;
    var first_digit: ?u64 = null;
    var last_digit: u64 = undefined;

    for (input) |c| {
        switch (c) {
            '\n' => {
                sum += first_digit.? * 10 + last_digit;
                first_digit = null;
            },
            '0'...'9' => {
                if (first_digit == null) first_digit = c - '0';
                last_digit = c - '0';
            },
            else => {},
        }
    }
    if (first_digit) |_| sum += first_digit.? * 10 + last_digit;

    return sum;
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !u64 {
    _ = alloc;

    var sum: u64 = 0;
    var first_digit: ?u64 = null;
    var last_digit: u64 = undefined;

    for (input, 0..) |c, i| {
        switch (c) {
            '\n' => {
                sum += first_digit.? * 10 + last_digit;
                first_digit = null;
            },
            '0'...'9' => {
                if (first_digit == null) first_digit = c - '0';
                last_digit = c - '0';
            },
            'o' => {
                if (mem.startsWith(u8, input[i..], "one")) {
                    if (first_digit == null) first_digit = 1;
                    last_digit = 1;
                }
            },
            't' => {
                if (mem.startsWith(u8, input[i..], "two")) {
                    if (first_digit == null) first_digit = 2;
                    last_digit = 2;
                } else if (mem.startsWith(u8, input[i..], "three")) {
                    if (first_digit == null) first_digit = 3;
                    last_digit = 3;
                }
            },
            'f' => {
                if (mem.startsWith(u8, input[i..], "four")) {
                    if (first_digit == null) first_digit = 4;
                    last_digit = 4;
                } else if (mem.startsWith(u8, input[i..], "five")) {
                    if (first_digit == null) first_digit = 5;
                    last_digit = 5;
                }
            },
            's' => {
                if (mem.startsWith(u8, input[i..], "six")) {
                    if (first_digit == null) first_digit = 6;
                    last_digit = 6;
                } else if (mem.startsWith(u8, input[i..], "seven")) {
                    if (first_digit == null) first_digit = 7;
                    last_digit = 7;
                }
            },
            'e' => {
                if (mem.startsWith(u8, input[i..], "eight")) {
                    if (first_digit == null) first_digit = 8;
                    last_digit = 8;
                }
            },
            'n' => {
                if (mem.startsWith(u8, input[i..], "nine")) {
                    if (first_digit == null) first_digit = 9;
                    last_digit = 9;
                }
            },
            else => {},
        }
    }
    if (first_digit) |_| sum += first_digit.? * 10 + last_digit;

    return sum;
}

// After looking in discord, this seemed funny
fn part2Short(alloc: std.mem.Allocator, input: []const u8) !u64 {
    _ = alloc;

    var sum: u64 = 0;
    var first_digit: ?u64 = null;
    var last_digit: u64 = undefined;

    const digit_strings = .{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

    loop: for (input, 0..) |c, i| {
        switch (c) {
            '\n' => {
                sum += first_digit.? * 10 + last_digit;
                first_digit = null;
            },
            '0'...'9' => {
                if (first_digit == null) first_digit = c - '0';
                last_digit = c - '0';
            },
            else => inline for (digit_strings, 1..) |digit, value| {
                if (std.mem.startsWith(u8, input[i..], digit)) {
                    if (first_digit == null) first_digit = value;
                    last_digit = value;
                    continue :loop;
                }
            },
        }
    }
    if (first_digit) |_| sum += first_digit.? * 10 + last_digit;

    return sum;
}

const TEST_INPUT =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
;

const TEST_INPUT_2 =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
;

test "simple test" {
    var alloc = std.testing.allocator;
    try std.testing.expectEqual(@as(u64, 142), try part1(alloc, TEST_INPUT));
    try std.testing.expectEqual(@as(u64, 281), try part2(alloc, TEST_INPUT_2));
    try std.testing.expectEqual(@as(u64, 281), try part2Short(alloc, TEST_INPUT_2));
}
