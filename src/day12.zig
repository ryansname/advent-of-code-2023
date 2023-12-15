const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

// const print = std.debug.print;
const print = printToVoid;

fn printToVoid(comptime a: anytype, b: anytype) void {
    _ = a;
    _ = b;
}

fn iterLines(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, '\n');
}

fn iterTokens(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, ' ');
}

const INPUT = @embedFile("inputs/day12.txt");

pub fn main() !void {
    const result = try part1(INPUT);
    const result_2 = try part2(INPUT);

    std.debug.assert(result_2.part2 > 41477449305);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result_2.part2});
}

const Element = enum { good, bad, unknown };

const PartiallyValidResult = union(enum) {
    invalid: void,
    partially_valid: struct {
        required_bad: ?usize,
        required_chars_to_finish: usize,
        sequences_left: usize,
    },
};
fn isPartiallyValid(records: []const Element, sequences: []const u64) PartiallyValidResult {
    var in_bad = false;
    var expected_bads: u64 = if (sequences.len == 0) 0 else sequences[0];
    var sequence_idx: usize = 1;

    for (records) |record| {
        switch (record) {
            // .unknown => return .{ .required_bad = if (in_bad and expected_bads > 0) expected_bads else null },
            .unknown => unreachable,
            .good => {
                if (in_bad) {
                    if (expected_bads > 0) return .invalid;
                    in_bad = false;
                    if (sequence_idx < sequences.len) {
                        expected_bads = sequences[sequence_idx];
                        sequence_idx += 1;
                    }
                }
            },
            .bad => {
                if (!in_bad) in_bad = true;
                if (expected_bads == 0) return .invalid;
                expected_bads -= 1;
            },
        }
    }

    var required_chars_to_finish = expected_bads;
    if (sequences.len > 0) {
        for (sequences[sequence_idx..]) |sequence| {
            required_chars_to_finish += 1 + sequence;
        }
    }

    return .{
        .partially_valid = .{
            .required_bad = if (in_bad and expected_bads > 0) expected_bads else null,
            .required_chars_to_finish = required_chars_to_finish,
            .sequences_left = if (sequences.len > 0) sequences.len - sequence_idx else 0,
        },
    };
}

fn areRecordsValid(records: []const Element, sequences: []const u64) bool {
    for (records) |r| std.debug.assert(r != .unknown);
    var fail_iter = std.mem.tokenizeScalar(Element, records, .good);

    for (sequences) |sequence| {
        if (fail_iter.next()) |fails| {
            if (fails.len != sequence) return false;
        } else return false;
    }
    return fail_iter.next() == null;
}

fn printRecords(prefix: []const u8, records: []const Element, suffix: []const u8) void {
    print("{s} ", .{prefix});
    printRecordsOnly(records);
    print(" {s}\n", .{suffix});
}
fn printRecordsOnly(records: []const Element) void {
    for (records) |r| print("{s}", .{switch (r) {
        .unknown => "?",
        .good => ".",
        .bad => "#",
    }});
}

fn countPossibilitiesStart(records_with_unknowns: []const Element, sequences: []const u64) u63 {
    var workspace = [_]Element{.good} ** 128;
    var result_cache: [128][128]?u63 = .{.{null} ** 128} ** 128;

    printRecords("Processing", records_with_unknowns, "");

    const result = countPossibilities(
        records_with_unknowns,
        sequences,
        &result_cache,
        workspace[0..records_with_unknowns.len],
        0,
    );

    print("For smaller sequence: ", .{});
    printRecordsOnly(records_with_unknowns);
    print(" got {} results\n", .{result});

    return result;
}

/// result_cache: [records_left][sequences_left]count
fn countPossibilities(records_with_unknowns: []const Element, sequences: []const u64, result_cache: [][128]?u63, records: []Element, idx: usize) u63 {
    if (idx == 0) {
        printRecordsOnly(records_with_unknowns);
        print("\n", .{});
    }

    if (idx >= records.len) {
        if (areRecordsValid(records, sequences)) {
            print("Found valid sequence ", .{});
            printRecordsOnly(records);
            print("\n", .{});
            return 1;
        } else {
            print("Found invalid sequence ", .{});
            printRecordsOnly(records);
            print("\n", .{});
            return 0;
        }
    }

    const offset = offset: for (records_with_unknowns[idx..], records[idx..], 0..) |record, *item, offset| {
        switch (record) {
            .good, .bad => item.* = record,
            .unknown => break :offset offset,
        }
    } else {
        // Reached the end, recurse and check for total validity
        return countPossibilities(records_with_unknowns, sequences, result_cache, records, records.len);
    };

    const first_unknown_idx = idx + offset;
    const validity = isPartiallyValid(records[0..first_unknown_idx], sequences);
    const partial = switch (validity) {
        .invalid => {
            printRecordsOnly(records[0..first_unknown_idx]);
            print(" is not partially valid for {any}\n", .{sequences});
            return 0;
        },
        .partially_valid => |p| blk: {
            if (p.required_chars_to_finish + first_unknown_idx > records.len) {
                return 0;
            } else break :blk p;
        },
    };
    // printRecords(records[0..first_unknown_idx]);
    // print(" is partially valid for {any}\n", .{sequences});

    if (partial.required_bad) |required_bad| {
        if (first_unknown_idx + required_bad > records_with_unknowns.len) return 0;

        for (records[first_unknown_idx .. first_unknown_idx + required_bad], records_with_unknowns[first_unknown_idx .. first_unknown_idx + required_bad], 0..) |*r, src, i| switch (src) {
            .unknown, .bad => r.* = .bad,
            .good => {
                printRecordsOnly(records[0 .. first_unknown_idx + i]);
                print(" could not add enough bad items, added {}, needed {}!\n", .{ i, required_bad });
                return 0;
            },
        };

        const idx_that_must_be_good = first_unknown_idx + required_bad;
        var next_idx = if (idx_that_must_be_good < records.len) blk: {
            switch (records_with_unknowns[idx_that_must_be_good]) {
                .unknown, .good => records[idx_that_must_be_good] = .good,
                .bad => {
                    printRecordsOnly(records[0 .. idx_that_must_be_good + 1]);
                    print(" could not add good item spacer\n", .{});
                    return 0;
                },
            }
            break :blk idx_that_must_be_good + 1;
        } else idx_that_must_be_good;

        print("Added {} required bads ", .{required_bad});
        printRecordsOnly(records[0..next_idx]);
        print("\n", .{});

        std.debug.assert(records[idx_that_must_be_good] == .good);
        if (result_cache[idx_that_must_be_good][partial.sequences_left]) |count| {
            // std.debug.print("Cache Hit!\n", .{});
            return count;
        }

        const count = countPossibilities(records_with_unknowns, sequences, result_cache, records, next_idx);
        result_cache[idx_that_must_be_good][partial.sequences_left] = count;

        return count;
    } else {
        var count: u63 = 0;
        inline for (.{ .good, .bad }) |option| {
            records[first_unknown_idx] = option;
            print("Trying ", .{});
            printRecordsOnly(records[0 .. first_unknown_idx + 1]);
            print("\n", .{});

            const this_count = if (option == .good) blk: {
                std.debug.assert(records[first_unknown_idx] == .good);
                if (result_cache[first_unknown_idx][partial.sequences_left]) |c| break :blk c;

                const c = countPossibilities(records_with_unknowns, sequences, result_cache, records, first_unknown_idx + 1);
                result_cache[first_unknown_idx][partial.sequences_left] = c;
                break :blk c;
            } else countPossibilities(records_with_unknowns, sequences, result_cache, records, first_unknown_idx + 1);

            count += this_count;
        }

        return count;
    }
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
        std.debug.print("'{s}'\n", .{line});

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
