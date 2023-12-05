const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day05.txt");

pub fn main() !void {
    const result = try parts(undefined, INPUT);
    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const MapItem = struct {
    in: u64,
    out: u64,
    range: u64,
    delta: i64,
};

fn mapGet(in: u64, map: []const MapItem) u64 {
    for (map) |item| {
        if (in >= item.in and in < item.in + item.range) {
            // log.err("{} -> {} delta: {} {}", .{ item.in, item.out, item.delta, in });
            return @intCast(item.delta + @as(i64, @intCast(in)));
        }
    }
    std.debug.panic("No map matched input: {}", .{in});
    unreachable;
}

fn mapGetRange(in_min: u64, in_max: u64, map: []const MapItem) [100]?struct { u64, u64 } {
    var result = [_]?struct { u64, u64 }{null} ** 100;
    var result_idx: usize = 0;

    var in_iter = in_min;
    iter: while (in_iter < in_max) {
        for (map) |item| {
            std.debug.assert(item.range > 0);
            if (in_iter >= item.in and in_iter < item.in + item.range) {
                const part_min: u64 = @intCast(item.delta + @as(i64, @intCast(in_iter)));
                const part_max: u64 = @intCast(item.delta + @as(i64, @intCast(@min(item.in + item.range, in_max))));
                result[result_idx] = .{ part_min, part_max };
                result_idx += 1;
                in_iter += part_max - part_min;
                continue :iter;
            }
        }
    }

    return result;
}

fn parts(alloc: mem.Allocator, input: []const u8) !struct { part1: u64, part2: u64 } {
    _ = alloc;

    var maps: [7][100]MapItem = .{.{.{ .in = 0, .out = 0, .range = std.math.maxInt(u64), .delta = 0 }} ** 100} ** 7;

    var tokenized_parts = mem.tokenizeSequence(u8, input, "\n\n");

    const seeds = tokenized_parts.next().?;

    for (&maps) |*map| {
        const map_section = tokenized_parts.next().?;
        var line_iter = mem.tokenizeScalar(u8, map_section, '\n');
        _ = line_iter.next();
        var line_idx: usize = 0;
        while (line_iter.next()) |line| {
            var part_iter = mem.tokenizeScalar(u8, line, ' ');

            var item = &map[line_idx];
            line_idx += 1;

            item.out = try fmt.parseInt(u64, part_iter.next().?, 10);
            item.in = try fmt.parseInt(u64, part_iter.next().?, 10);
            item.range = try fmt.parseInt(u64, part_iter.next().?, 10);
            item.delta = @as(i64, @intCast(item.out)) - @as(i64, @intCast(item.in));
        }

        // log.err("{any}", .{map.*});
    }

    var part_1: u64 = std.math.maxInt(u64);
    {
        var seed_iter = mem.tokenizeScalar(u8, seeds, ' ');
        _ = seed_iter.next(); // Seeds:

        while (seed_iter.next()) |seed_str| {
            const seed = try fmt.parseInt(u64, seed_str, 10);

            var current_id = seed;
            for (maps) |map| {
                current_id = mapGet(current_id, &map);
            }
            part_1 = @min(part_1, current_id);
            // log.err("Resolved {} to {}", .{ seed, current_id });
        }
    }

    var part_2: u64 = std.math.maxInt(u64);
    {
        var seed_iter = mem.tokenizeScalar(u8, seeds, ' ');
        _ = seed_iter.next(); // Seeds:
        while (seed_iter.next()) |seed_str| {
            const seed_min = try fmt.parseInt(u64, seed_str, 10);
            const seed_max = seed_min + try fmt.parseInt(u64, seed_iter.next().?, 10);

            const min = resolve(.{ seed_min, seed_max }, &maps, 0);
            part_2 = @min(part_2, min);
        }
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

fn resolve(range: struct { u64, u64 }, maps: *[7][100]MapItem, map_idx: usize) u64 {
    const min, const max = range;
    if (map_idx >= maps.len) {
        return min;
    }

    const map = maps[map_idx];
    var result: u64 = math.maxInt(u64);

    const next_ranges_raw = mapGetRange(min, max, &map);
    std.debug.assert(next_ranges_raw[0] != null);
    for (next_ranges_raw) |nr| {
        if (nr == null) break;

        result = @min(result, resolve(nr.?, maps, map_idx + 1));
    }

    return result;
}

const TEST_INPUT =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
    \\
;

test "simple test" {
    var alloc = std.testing.allocator;
    const results = try parts(alloc, TEST_INPUT);
    try std.testing.expectEqual(@as(u64, 35), results.part1);
    try std.testing.expectEqual(@as(u64, 46), results.part2);
}
