const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day18.txt");

//const DugIter = struct {
//    map: []Tile,
//    index: ?usize = null,
//    prev: Tile = .ground,
//
//    fn next(self: *DugIter) ?Coord {
//        self.prev = if (self.index) |idx| self.map[idx] else .ground;
//
//        for (self.index orelse 0..self.map.len) |test_idx| {
//            if (self.map[test_idx] != .dug) continue;
//            if (std.meta.eql(self.map[test_idx], self.prev)) continue; // Duplicate entry
//
//            self.index = test_idx;
//            return self.map[test_idx].dug;
//        } else return null;
//    }
//};
//
//fn findTile(map: []const Tile, coord: Coord) Tile {
//    const idx = std.sort.binarySearch(Tile, coord, map, {}, coordTileCompare) orelse return .ground;
//    return map[idx];
//}

fn findBounds(map: Map) struct { min: Coord, max: Coord } {
    var min_x: i64 = math.maxInt(i64);
    var min_y: i64 = math.maxInt(i64);
    var max_x: i64 = math.minInt(i64);
    var max_y: i64 = math.minInt(i64);
    for (map.horizontal) |horizontal| {
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
    const result = try part1(INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const Coord = struct { x: i64, y: i64 };
const Horizontal = struct { y: i64, x_min: i64, x_max: i64 };
const Vertical = struct { y_min: i64, y_max: i64, x: i64 };

const Map = struct {
    horizontal: []Horizontal,
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

//fn tileTileCompare(_: void, t1: Tile, t2: Tile) bool {
//    if (t1 == .ground) return false;
//    return coordTileCompare({}, t1.dug, t2) == .lt;
//}
//fn coordTileCompare(_: void, coord: Coord, value: Tile) std.math.Order {
//    if (value == .ground) return .lt;
//    std.debug.assert(value == .dug);
//
//    if (coord.y < value.dug.y) {
//        return .lt;
//    } else if (coord.y > value.dug.y) {
//        return .gt;
//    } else if (coord.x < value.dug.x) {
//        return .lt;
//    } else if (coord.x > value.dug.x) {
//        return .gt;
//    } else {
//        return .eq;
//    }
//}

//fn digInterior(map: []Tile, border: []const Tile) void {
//    const bounds = findBounds(map);
//    // Purposely start one less than the min bound which will always be outside
//    const start_x = bounds.min.x - 1;
//    const start_y = bounds.min.y - 1;
//
//    var here: Coord = .{ .x = start_x, .y = start_y };
//    var inside = false;
//    var seen_north = false;
//    var seen_south = false;
//    var next_idx = border.len;
//    while (here.y < bounds.max.y) : (here.y += 1) {
//        inside = false;
//        here.x = start_x;
//        while (here.x < bounds.max.x) : (here.x += 1) {
//            if (inside) {xxxxxxxxx
//                map[next_idx] = .{ .dug = here }; // Dedup if we have to
//                next_idx += 1;
//            }
//            // Check against the border to update insidedness
//            const t_here = findTile(border, here);
//            const north = findTile(border, .{ .x = here.x, .y = here.y - 1 });
//            // const east = findTile(border, .{ .x = here.x + 1, .y = here.y });
//            const south = findTile(border, .{ .x = here.x, .y = here.y + 1 });
//            // const west = findTile(border, .{ .x = here.x - 1, .y = here.y });
//
//            if (t_here != .dug) {
//                seen_north = false;
//                seen_south = false;
//            } else {
//                if (north == .dug) seen_north = true;
//                if (south == .dug) seen_south = true;
//            }
//
//            if (seen_north and seen_south) {
//                inside = !inside;
//            }
//        }
//    }
//    std.sort.pdq(Tile, map, {}, tileTileCompare);
//}

fn countDug(map: Map) i64 {
    const b = findBounds(map);
    std.debug.print("Found bounds: {}\n", .{b});

    const height: usize = @intCast(b.max.y - b.min.y);
    const width: usize = @intCast(b.max.x - b.min.x);
    var dug: i64 = 0;

    for (1..height - 1) |row_offset| {
        const row: i64 = @as(i64, @intCast(row_offset)) + b.min.y;

        var inside = false;
        var col = b.min.x;

        for (map.verticals) |vertical| {
            if (inside) {
                dug += vertical.x - col;
            }

            if (inside) {
                dug += 1;
            }

            // Check against the border to update insidedness
            const t_here = findTile(border, here);
            const north = findTile(border, .{ .x = here.x, .y = here.y - 1 });
            // const east = findTile(border, .{ .x = here.x + 1, .y = here.y });
            const south = findTile(border, .{ .x = here.x, .y = here.y + 1 });
            // const west = findTile(border, .{ .x = here.x - 1, .y = here.y });

            if (t_here != .dug) {
                seen_north = false;
                seen_south = false;
            } else {
                if (north == .dug) seen_north = true;
                if (south == .dug) seen_south = true;
            }

            if (seen_north and seen_south) {
                inside = !inside;
            }

            std.debug.print("{}, {}\n", .{ col, row });
        }
    }

    return 0;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var horizontal_buffer: [512]Horizontal = undefined;
    var vertical_buffer: [512]Vertical = undefined;

    var next_horizontal_idx: usize = 0;
    var next_vertical_idx: usize = 0;

    var here: Coord = .{ .x = 0, .y = 0 };

    var instruction_iter = aoc.iterLines(input);
    while (instruction_iter.next()) |line| {
        var token_iter = aoc.iterTokens(line);
        const delta: Coord = switch (token_iter.next().?[0]) {
            'U' => .{ .x = 0, .y = -1 },
            'D' => .{ .x = 0, .y = 1 },
            'R' => .{ .x = 1, .y = 0 },
            'L' => .{ .x = -1, .y = 0 },
            else => unreachable,
        };

        const distance = try fmt.parseInt(i64, token_iter.next().?, 10);
        const color = token_iter.next().?[2..7];
        _ = color;

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

    var part_1: i64 = countDug(.{ .horizontal = horizontals, .vertical = verticals });
    var part_2: i64 = 0;
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

test "simple test part1" {
    const result = try part1(TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 62), result.part1);
    try std.testing.expectEqual(@as(i64, 0), result.part2);
}
