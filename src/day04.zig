const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day04.txt");

pub fn main() !void {
    const result = try parts(undefined, INPUT);
    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

fn badParseInt(str: []const u8) !u8 {
    return fmt.parseInt(u8, str[0..2], 10) catch try fmt.parseInt(u8, str[1..2], 10);
}

fn parts(alloc: mem.Allocator, input: []const u8) !struct { part1: u64, part2: u64 } {
    _ = alloc;

    var part_1: u64 = 0;
    var part_2: u64 = 0;

    {
        var winning_numbers = [_]u8{0} ** 32;
        var score: u64 = 0;

        var winning_number_idx: usize = 0;
        var lines = mem.tokenizeScalar(u8, input, '\n');
        while (lines.next()) |line| {
            @memset(&winning_numbers, 0);
            winning_number_idx = 0;
            score = 0;

            var idx = mem.indexOfScalar(u8, line, ':').? + 2;

            while (line[idx] != '|') : (idx += 3) {
                const number = try badParseInt(line[idx..]);
                winning_numbers[winning_number_idx] = number;
                winning_number_idx += 1;
            }
            // log.err("Winning numbers: '{any}", .{mem.sliceTo(&winning_numbers, 0)});
            idx += 2;

            while (idx < line.len) : (idx += 3) {
                const number = try badParseInt(line[idx..]);
                // log.err("Considering: '{s}' = {}", .{ line[idx .. idx + 2], number });
                if (mem.indexOfScalar(u8, &winning_numbers, number)) |_| {
                    score = if (score == 0) 1 else score * 2;
                }
            }
            part_1 += score;
        }
    }
    {
        var copies = [_]u64{0} ** 256;
        var winning_numbers = [_]u8{0} ** 32;
        var wins: u64 = 0;

        var winning_number_idx: usize = 0;
        var lines = mem.tokenizeScalar(u8, input, '\n');
        var card_idx: usize = 0;
        while (lines.next()) |line| {
            defer card_idx += 1;
            copies[card_idx] += 1;

            @memset(&winning_numbers, 0);
            winning_number_idx = 0;
            wins = 0;

            var idx = mem.indexOfScalar(u8, line, ':').? + 2;

            while (line[idx] != '|') : (idx += 3) {
                const number = try badParseInt(line[idx..]);
                winning_numbers[winning_number_idx] = number;
                winning_number_idx += 1;
            }
            // log.err("Winning numbers: '{any}", .{mem.sliceTo(&winning_numbers, 0)});
            idx += 2;

            while (idx < line.len) : (idx += 3) {
                const number = try badParseInt(line[idx..]);
                // log.err("Considering: '{s}' = {}", .{ line[idx .. idx + 2], number });
                if (mem.indexOfScalar(u8, &winning_numbers, number)) |_| {
                    wins += 1;
                }
            }

            var copy_idx = card_idx + 1;
            while (copy_idx < card_idx + 1 + wins) : (copy_idx += 1) {
                copies[copy_idx] += copies[card_idx];
            }
        }

        for (copies) |m| part_2 += m;
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    \\
;

test "simple test" {
    var alloc = std.testing.allocator;
    const results = try parts(alloc, TEST_INPUT);
    try std.testing.expectEqual(@as(u64, 13), results.part1);
    try std.testing.expectEqual(@as(u64, 30), results.part2);
}
