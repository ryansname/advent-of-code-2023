const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day18.txt");

fn findBounds(map: Map) struct { min: Coord, max: Coord } {
    var min_x: i64 = math.maxInt(i64);
    var min_y: i64 = math.maxInt(i64);
    var max_x: i64 = math.minInt(i64);
    var max_y: i64 = math.minInt(i64);
    for (map.horizontals) |horizontal| {
        min_x = @min(min_x, horizontal.x_min);
        max_x = @max(max_x, horizontal.x_max);
        min_y = @min(min_y, horizontal.y);
        max_y = @max(max_y, horizontal.y);
    }
    return .{
        .min = .{ .x = min_x - 1, .y = min_y - 1 },
        .max = .{ .x = max_x + 1, .y = max_y + 1 },
    };
}

pub fn main() !void {
    const result = try part1(.P1, INPUT);
    const result_2 = try part1(.P2, INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result_2.part2});
}

const Coord = struct { x: i64, y: i64 };
const Horizontal = struct { y: i64, x_min: i64, x_max: i64 };
const Vertical = struct { y_min: i64, y_max: i64, x: i64 };

const Map = struct {
    horizontals: []Horizontal,
    verticals: []Vertical,
};

fn compareFn(comptime T: type, comptime ordered_fields: anytype) type {
    return struct {
        // Return true if arg1 < arg2
        fn compare(_: void, arg1: T, arg2: T) bool {
            inline for (ordered_fields) |field| {
                const value_1 = @field(arg1, field);
                const value_2 = @field(arg2, field);

                if (value_1 != value_2) return value_1 < value_2;
            }
            return false;
        }
    };
}

const PRINT_MAP = false;
const PRINT_DEBUG = false;
fn printMap(char: u8, count: i64) void {
    if (!PRINT_MAP) return;
    for (0..@intCast(count)) |_| std.debug.print("{c}", .{char});
}
fn printNotMap(comptime format: []const u8, args: anytype) void {
    if (!PRINT_DEBUG) return;
    std.debug.print(format, args);
}

fn countDug(map: Map) i64 {
    const b = findBounds(map);

    const height: usize = @intCast(b.max.y - b.min.y);
    const width: usize = @intCast(b.max.x - b.min.x);
    _ = width;
    var dug: i64 = 0;

    var progress_root = std.Progress{};
    var progress = progress_root.start("Running", height);
    for (1..height) |row_offset| {
        defer progress.completeOne();
        const row: i64 = @as(i64, @intCast(row_offset)) + b.min.y;

        var dug_this_row: i64 = 0;
        defer {
            dug += dug_this_row;
        }

        // Tracks whether we'll be inside or outside next
        var seen_above = false;
        var seen_below = false;
        // Will the next non horizontal line be inside or outside
        var inside = false;
        var col = b.min.x;
        var vertical_idx: usize = 0;

        // Jump to matching vertical
        for (map.verticals[vertical_idx..]) |vertical| {
            if (vertical.x < col) continue;

            // Vertical has no overlap
            if (row < vertical.y_min) continue;
            if (row > vertical.y_max) continue;

            defer col = vertical.x + 1;

            var distance_to_vertical = vertical.x - col;

            //std.debug.print("Consider {}", .{vertical});
            printNotMap("x={} ({} - {}) (exc)={}, inside={}", .{ vertical.x, col, vertical.x, distance_to_vertical, inside });
            defer printNotMap(" {}\n", .{dug_this_row});

            var was_in_border = false;
            var next_inside = inside;
            defer inside = next_inside;

            // Easy case, we're in the middle of the line
            if (vertical.y_min < row and row < vertical.y_max) {
                next_inside = !inside;
            } else if (vertical.y_min == row) {
                if (seen_above) {
                    // u shape, stay on the same side
                    was_in_border = true;
                    seen_above = false;
                } else if (seen_below) {
                    was_in_border = true;
                    next_inside = !inside;
                    seen_below = false;
                } else {
                    seen_above = true;
                }
            } else if (vertical.y_max == row) {
                if (seen_below) {
                    // n shape, stay on the same side
                    was_in_border = true;
                    seen_below = false;
                } else if (seen_above) {
                    was_in_border = true;
                    next_inside = !inside;
                    seen_above = false;
                } else {
                    seen_below = true;
                }
            } else {
                std.debug.panic("Reaches unreachable state", .{});
            }

            if (was_in_border) {
                printMap('b', distance_to_vertical);
                dug_this_row += distance_to_vertical;
            } else if (inside) {
                printMap('#', distance_to_vertical);
                dug_this_row += distance_to_vertical;
            } else {
                printMap('.', distance_to_vertical);
            }
            // and we always finish on a border
            printMap('|', 1);
            dug_this_row += 1;
        }
        printMap('\n', 1);
    }

    return dug;
}

fn part1(part: enum { P1, P2 }, input: []const u8) !struct { part1: i64, part2: i64 } {
    var horizontal_buffer: [512]Horizontal = undefined;
    var vertical_buffer: [512]Vertical = undefined;

    var next_horizontal_idx: usize = 0;
    var next_vertical_idx: usize = 0;

    var here: Coord = .{ .x = 0, .y = 0 };

    var instruction_iter = aoc.iterLines(input);
    while (instruction_iter.next()) |line| {
        var token_iter = aoc.iterTokens(line);

        const delta, const distance = switch (part) {
            .P1 => blk: {
                const delta: Coord = switch (token_iter.next().?[0]) {
                    'U' => .{ .x = 0, .y = -1 },
                    'D' => .{ .x = 0, .y = 1 },
                    'R' => .{ .x = 1, .y = 0 },
                    'L' => .{ .x = -1, .y = 0 },
                    else => unreachable,
                };

                const distance = try fmt.parseInt(i64, token_iter.next().?, 10);
                break :blk .{ delta, distance };
            },
            .P2 => blk: {
                _ = token_iter.next();
                _ = token_iter.next();
                const color = token_iter.next().?[2..8];
                const delta: Coord = switch (color[5]) {
                    '3' => .{ .x = 0, .y = -1 },
                    '1' => .{ .x = 0, .y = 1 },
                    '0' => .{ .x = 1, .y = 0 },
                    '2' => .{ .x = -1, .y = 0 },
                    else => unreachable,
                };
                const distance = try fmt.parseInt(i64, color[0..5], 16);
                break :blk .{ delta, distance };
            },
        };

        const next = .{
            .x = here.x + delta.x * distance,
            .y = here.y + delta.y * distance,
        };
        defer here = next;

        if (delta.x != 0) {
            horizontal_buffer[next_horizontal_idx] = .{ .y = here.y, .x_min = @min(here.x, next.x), .x_max = @max(here.x, next.x) };
            next_horizontal_idx += 1;
        } else {
            vertical_buffer[next_vertical_idx] = .{ .x = here.x, .y_min = @min(here.y, next.y), .y_max = @max(here.y, next.y) };
            next_vertical_idx += 1;
        }
    }

    const horizontals = horizontal_buffer[0..next_horizontal_idx];
    const verticals = vertical_buffer[0..next_vertical_idx];

    std.sort.pdq(Horizontal, horizontals, {}, compareFn(Horizontal, .{ "y", "x_min", "x_max" }).compare);
    std.sort.pdq(Vertical, verticals, {}, compareFn(Vertical, .{ "x", "y_min", "y_max" }).compare);

    const answer = countDug(.{ .horizontals = horizontals, .verticals = verticals });
    var part_1: i64 = 0;
    var part_2: i64 = 0;

    switch (part) {
        .P1 => part_1 = answer,
        .P2 => part_2 = answer,
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\R 6 (#70c710)
    \\D 5 (#0dc571)
    \\L 2 (#5713f0)
    \\D 2 (#d2c081)
    \\R 2 (#59c680)
    \\D 2 (#411b91)
    \\L 5 (#8ceee2)
    \\U 2 (#caa173)
    \\L 1 (#1b58a2)
    \\U 2 (#caa171)
    \\R 2 (#7807d2)
    \\U 3 (#a77fa3)
    \\L 2 (#015232)
    \\U 2 (#7a21e3)
;

test "small box" {
    const result = try part1(.P1,
        \\R 1 (#70c710)
        \\D 1 (#0dc571)
        \\L 1 (#5713f0)
        \\U 1 (#d2c081)
    );
    try std.testing.expectEqual(@as(i64, 4), result.part1);
}

test "smallish box" {
    const result = try part1(.P1,
        \\R 2 (#70c710)
        \\D 2 (#0dc571)
        \\L 2 (#5713f0)
        \\U 2 (#d2c081)
    );
    try std.testing.expectEqual(@as(i64, 9), result.part1);
}

test "simple test part1" {
    const result = try part1(.P1, TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 62), result.part1);
    const result_2 = try part1(.P2, TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 952408144115), result_2.part2);
}

test part1 {
    const result = try part1(.P1, INPUT);
    try std.testing.expectEqual(@as(i64, 106459), result.part1);
    // try std.testing.expectEqual(@as(i64, 0), result.part2);
}
