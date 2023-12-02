const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day02.txt");

pub fn main() !void {
    const result = try parts(undefined, INPUT);
    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const Value = struct { set: bool = false, red: u64, green: u64, blue: u64 };

fn parts(alloc: mem.Allocator, input: []const u8) !struct { part1: u64, part2: u64 } {
    _ = alloc;
    var data: [100][100]Value = .{
        .{.{ .red = 0, .blue = 0, .green = 0 }} ** 100,
    } ** 100;

    var tokens = mem.tokenizeAny(u8, input, " ;,\n:");

    var game_idx: usize = 0;
    var pull_idx: usize = 0;
    var number: usize = undefined;
    while (tokens.next()) |t| {
        if (t.len == 0) break;

        var pull = &data[game_idx][pull_idx];
        pull.set = true;
        if (ascii.isDigit(t[0])) {
            // log.info("Parsing: {s}", .{t});
            number = try fmt.parseInt(u64, t, 10);
        } else if (t[0] == 'r') {
            // log.err("red: {}", .{number});
            pull.red += number;
        } else if (t[0] == 'b') {
            // log.err("blue: {}", .{number});
            pull.blue += number;
        } else if (t[0] == 'g') {
            // log.err("green: {}", .{number});
            pull.green += number;
        }
        if (tokens.peek()) |next| if (next[0] == 'G') {
            game_idx += 1;
            pull_idx = 0;
        } else if (input[tokens.index - 2] == ';') {
            pull_idx += 1;
        } else {};
    }
    for (data[game_idx + 1 ..]) |*d| d[0].red = 9999;

    const limit = Value{ .red = 12, .green = 13, .blue = 14 };
    var seen: Value = undefined;
    var part1: u64 = 0;
    var part2: u64 = 0;

    for (data, 1..) |d, id| {
        if (!d[0].set) break;

        seen = Value{ .red = 0, .green = 0, .blue = 0 };
        for (d) |p| {
            if (!p.set) break;

            seen.red = @max(seen.red, p.red);
            seen.green = @max(seen.green, p.green);
            seen.blue = @max(seen.blue, p.blue);
        }
        if (seen.red <= limit.red and seen.green <= limit.green and seen.blue <= limit.blue) {
            part1 += id;
        }
        part2 += seen.red * seen.green * seen.blue;
    }

    return .{ .part1 = part1, .part2 = part2 };
}

const TEST_INPUT =
    \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
;

test "simple test" {
    var alloc = std.testing.allocator;
    const results = try parts(alloc, TEST_INPUT);
    try std.testing.expectEqual(@as(u64, 8), results.part1);
    try std.testing.expectEqual(@as(u64, 2286), results.part2);
}
