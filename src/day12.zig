const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

fn iterLines(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, '\n');
}

const INPUT = @embedFile("inputs/day12.txt");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const result = try part1(INPUT);
    const result_2 = try part2(INPUT);

    try stdout.print("Part 1: {}\n", .{result.part1});
    try stdout.print("Part 2: {}\n", .{result_2.part2});
}

const Element = enum { good, bad, unknown };

fn countPossibilitiesStart(records_with_unknowns: []const Element, sequences: []const u64) u63 {
    var workspace = [_]Element{.good} ** 128;
    var result_cache: [128][128]?u63 = .{.{null} ** 128} ** 128;

    const result = countPossibilities2(
        records_with_unknowns,
        sequences,
        &result_cache,
        workspace[0..records_with_unknowns.len],
        workspace[0..records_with_unknowns.len],
    );

    return result;
}

fn countPossibilities2(input: []const Element, remaining_damaged_lengths: []const u64, result_cache: [][128]?u63, workspace: []Element, solution: []Element) u63 {
    if (result_cache[workspace.len][remaining_damaged_lengths.len]) |count| return count;

    if (input.len == 0) {
        const result: u63 = if (remaining_damaged_lengths.len == 0) 1 else 0;
        return result;
    }

    var considerations_buf: [2]Element = undefined;
    considerations_buf[0] = input[0];
    const considerations = switch (input[0]) {
        .bad, .good => considerations_buf[0..1],
        .unknown => blk: {
            considerations_buf[0] = .good;
            considerations_buf[1] = .bad;
            break :blk considerations_buf[0..];
        },
    };

    var result: u63 = 0;
    c: for (considerations) |state| {
        workspace[0] = state;

        switch (workspace[0]) {
            .good => {
                const count = countPossibilities2(input[1..], remaining_damaged_lengths, result_cache, workspace[1..], solution);
                result_cache[workspace.len - 1][remaining_damaged_lengths.len] = count;
                result += count;
            },
            .bad => {
                if (remaining_damaged_lengths.len == 0) continue :c;

                const required_bad_count = remaining_damaged_lengths[0];
                if (input.len < required_bad_count) continue :c; // Not enough input to fulfill bad count

                // Set the next required_bad_count elements to bad
                for (input[0..required_bad_count], workspace[0..required_bad_count]) |input_element, *workspace_element| {
                    switch (input_element) {
                        .good => continue :c,
                        .unknown, .bad => workspace_element.* = .bad,
                    }
                }

                // Now, if there is no more characters at all, we'll recurse and check that we're done
                std.debug.assert(input.len >= required_bad_count);
                if (input.len == required_bad_count) {
                    const count = countPossibilities2(
                        input[required_bad_count..],
                        remaining_damaged_lengths[1..],
                        result_cache,
                        workspace[required_bad_count..],
                        solution,
                    );
                    result += count;
                } else {
                    switch (input[required_bad_count]) {
                        .unknown, .good => {
                            workspace[required_bad_count] = .good;
                            const count = countPossibilities2(
                                input[required_bad_count + 1 ..],
                                remaining_damaged_lengths[1..],
                                result_cache,
                                workspace[required_bad_count + 1 ..],
                                solution,
                            );
                            result += count;
                        },
                        .bad => continue :c,
                    }
                }
            },
            .unknown => unreachable,
        }
    }
    return result;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var lines_iter = iterLines(input);
    var records_buf: [64]Element = undefined;
    var sequences_buf: [records_buf.len]u64 = undefined;
    var next_record_idx: usize = 0;
    var next_sequence_idx: usize = 0;

    var progress_root = std.Progress{};
    var progress = progress_root.start("Part 1", mem.count(u8, input, "\n"));

    var part_1: i64 = 0;
    while (lines_iter.next()) |line| {
        var node = progress.start(line, 0);
        node.activate();
        defer node.end();

        defer next_record_idx = 0;
        defer next_sequence_idx = 0;

        const records, const sequences = blk: {
            for (line) |char| {
                switch (char) {
                    '?' => records_buf[next_record_idx] = .unknown,
                    '.' => records_buf[next_record_idx] = .good,
                    '#' => records_buf[next_record_idx] = .bad,
                    ' ' => break,
                    else => unreachable,
                }
                next_record_idx += 1;
            }
            const sequences_start = next_record_idx + 1;
            var sequences_iter = std.mem.tokenizeScalar(u8, line[sequences_start..], ',');
            while (sequences_iter.next()) |sequence_string| {
                sequences_buf[next_sequence_idx] = try fmt.parseInt(u64, sequence_string, 10);
                next_sequence_idx += 1;
            }

            break :blk .{ records_buf[0..next_record_idx], sequences_buf[0..next_sequence_idx] };
        };

        const possibilities = countPossibilitiesStart(records, sequences);
        part_1 += @intCast(possibilities);
    }

    var part_2: i64 = 0;
    return .{ .part1 = part_1, .part2 = part_2 };
}

fn part2(input: []const u8) !struct { part1: i64, part2: i64 } {
    var lines_iter = iterLines(input);
    var records_buf: [128]Element = undefined;
    var sequences_buf: [records_buf.len]u64 = undefined;
    var next_record_idx: usize = 0;
    var next_sequence_idx: usize = 0;

    var progress_root = std.Progress{};
    var progress = progress_root.start("Part 2", mem.count(u8, input, "\n"));

    var part_2: i64 = 0;
    while (lines_iter.next()) |line| {
        var node = progress.start(line, 0);
        node.activate();
        node.end();
        defer next_record_idx = 0;
        defer next_sequence_idx = 0;

        const records, const sequences = blk: {
            for (line) |char| {
                switch (char) {
                    '?' => records_buf[next_record_idx] = .unknown,
                    '.' => records_buf[next_record_idx] = .good,
                    '#' => records_buf[next_record_idx] = .bad,
                    ' ' => break,
                    else => unreachable,
                }
                next_record_idx += 1;
            }
            const sequences_start = next_record_idx + 1;

            records_buf[next_record_idx] = .unknown;
            next_record_idx += 1;

            var sequences_iter = std.mem.tokenizeScalar(u8, line[sequences_start..], ',');
            while (sequences_iter.next()) |sequence_string| {
                sequences_buf[next_sequence_idx] = try fmt.parseInt(u64, sequence_string, 10);
                next_sequence_idx += 1;
            }

            // Repeat the input 4 times for a total of 5 copies
            for (1..5, 2..) |r, r2| {
                @memcpy(records_buf[next_record_idx * r .. next_record_idx * r2], records_buf[0..next_record_idx]);
                @memcpy(sequences_buf[next_sequence_idx * r .. next_sequence_idx * r2], sequences_buf[0..next_sequence_idx]);
            }
            next_record_idx *= 5;
            // Strip the trailing unknown
            next_record_idx -= 1;

            next_sequence_idx *= 5;

            break :blk .{ records_buf[0..next_record_idx], sequences_buf[0..next_sequence_idx] };
        };

        const possibilities = countPossibilitiesStart(records, sequences);
        part_2 += @intCast(possibilities);
    }

    return .{ .part1 = 0, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\???.### 1,1,3
    \\.??..??...?##. 1,1,3
    \\?#?#?#?#?#?#?#? 1,3,1,6
    \\????.#...#... 4,1,1
    \\????.######..#####. 1,6,5
    \\?###???????? 3,2,1
    \\
;

test "simple test part1" {
    try std.testing.expectEqual(@as(i64, 1), (try part1("???.### 1,1,3")).part1);
    try std.testing.expectEqual(@as(i64, 4), (try part1(".??..??...?##. 1,1,3")).part1);
    try std.testing.expectEqual(@as(i64, 1), (try part1("?#?#?#?#?#?#?#? 1,3,1,6")).part1);
    try std.testing.expectEqual(@as(i64, 1), (try part1("????.#...#... 4,1,1")).part1);
    try std.testing.expectEqual(@as(i64, 4), (try part1("????.######..#####. 1,6,5")).part1);
    try std.testing.expectEqual(@as(i64, 10), (try part1("?###???????? 3,2,1")).part1);
    try std.testing.expectEqual(@as(i64, 21), (try part1(TEST_INPUT_1)).part1);
}

test "simple test part2" {
    try std.testing.expectEqual(@as(i64, 1), (try part2("???.### 1,1,3")).part2);
    try std.testing.expectEqual(@as(i64, 16384), (try part2(".??..??...?##. 1,1,3")).part2);
    try std.testing.expectEqual(@as(i64, 1), (try part2("?#?#?#?#?#?#?#? 1,3,1,6")).part2);
    try std.testing.expectEqual(@as(i64, 16), (try part2("????.#...#... 4,1,1")).part2);
    try std.testing.expectEqual(@as(i64, 2500), (try part2("????.######..#####. 1,6,5")).part2);
    try std.testing.expectEqual(@as(i64, 506250), (try part2("?###???????? 3,2,1")).part2);
    try std.testing.expectEqual(@as(i64, 525152), (try part2(TEST_INPUT_1)).part2);
}

test "slow1" {
    _ = try part2("???????#?#?#??#??. 1,10,2");
}

test "slow2" {
    _ = try part2("??.??????#???.?# 1,1,3,1,2");
}
