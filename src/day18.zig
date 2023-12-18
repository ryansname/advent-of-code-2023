const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day18.txt");

const DugIter = struct {
    map: []Tile,
    index: ?usize = null,
    prev: Tile = .ground,

    fn next(self: *DugIter) ?Coord {
        self.prev = if (self.index) |idx| self.map[idx] else .ground;

        for (self.index orelse 0..self.map.len) |test_idx| {
            if (self.map[test_idx] != .dug) continue;
            if (std.meta.eql(self.map[test_idx], self.prev)) continue; // Duplicate entry

            self.index = test_idx;
            return self.map[test_idx].dug;
        } else return null;
    }
};

fn findTile(map: []const Tile, coord: Coord) Tile {
    const idx = std.sort.binarySearch(Tile, coord, map, {}, coordTileCompare) orelse return .ground;
    return map[idx];
}

fn findBounds(map: []const Tile) struct { min: Coord, max: Coord } {
    var min_x: i64 = math.maxInt(i64);
    var min_y: i64 = math.maxInt(i64);
    var max_x: i64 = math.minInt(i64);
    var max_y: i64 = math.minInt(i64);
    for (map) |tile| {
        switch (tile) {
            .ground => {},
            .dug => |t| {
                min_x = @min(min_x, t.x);
                max_x = @max(max_x, t.x);

                min_y = @min(min_y, t.y);
                max_y = @max(max_y, t.y);
            },
        }
    }
    return .{
        .min = .{ .x = min_x, .y = min_y },
        .max = .{ .x = max_x, .y = max_y },
    };
}

fn printMap(map: []Tile) void {
    const bounds = findBounds(map);
    var coord: Coord = .{ .x = bounds.min.x, .y = bounds.min.y };

    var tile_idx_iter = DugIter{ .map = map };
    var next_dug_coord = tile_idx_iter.next();

    //std.debug.print("Here: {}, next dug: {any}\n", .{ coord, next_dug_coord });
    while (coord.y <= bounds.max.y) : (coord.y += 1) {
        coord.x = bounds.min.x;
        while (coord.x <= bounds.max.x) : (coord.x += 1) {
            const char: u8 = if (next_dug_coord != null and (next_dug_coord.?.x == coord.x and next_dug_coord.?.y == coord.y)) '#' else '.';
            if (char == '#') {
                next_dug_coord = tile_idx_iter.next();
            }
            // std.debug.print("Here: {}, next dug: {any}\n", .{ coord, next_dug_coord });
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    const result = try part1(INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const Coord = struct { x: i64, y: i64 };
const Horiontal = struct { y: i64, x_min: i64, x_max: i64 };
const Vertical = struct { y_min: i64, y_max: i64, x: i64 };

fn tileTileCompare(_: void, t1: Tile, t2: Tile) bool {
    if (t1 == .ground) return false;
    return coordTileCompare({}, t1.dug, t2) == .lt;
}
fn coordTileCompare(_: void, coord: Coord, value: Tile) std.math.Order {
    if (value == .ground) return .lt;
    std.debug.assert(value == .dug);

    if (coord.y < value.dug.y) {
        return .lt;
    } else if (coord.y > value.dug.y) {
        return .gt;
    } else if (coord.x < value.dug.x) {
        return .lt;
    } else if (coord.x > value.dug.x) {
        return .gt;
    } else {
        return .eq;
    }
}

fn digInterior(map: []Tile, border: []const Tile) void {
    const bounds = findBounds(map);
    // Purposely start one less than the min bound which will always be outside
    const start_x = bounds.min.x - 1;
    const start_y = bounds.min.y - 1;

    var here: Coord = .{ .x = start_x, .y = start_y };
    var inside = false;
    var seen_north = false;
    var seen_south = false;
    var next_idx = border.len;
    while (here.y < bounds.max.y) : (here.y += 1) {
        inside = false;
        here.x = start_x;
        while (here.x < bounds.max.x) : (here.x += 1) {
            if (inside) {
                map[next_idx] = .{ .dug = here }; // Dedup if we have to
                next_idx += 1;
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
        }
    }
    std.sort.pdq(Tile, map, {}, tileTileCompare);
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var map_buffer = [_]Tile{.ground} ** (128000); // Approx correct size
    var map = &map_buffer;

    var next_map_idx: usize = 1;
    var here: Coord = .{ .x = 0, .y = 0 };
    map[0] = .{ .dug = here };

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

        const distance = try fmt.parseInt(usize, token_iter.next().?, 10);
        const color = token_iter.next().?[2..7];
        _ = color;

        for (0..distance) |_| {
            // This is dumb but will work
            here.x += delta.x;
            here.y += delta.y;
            map[next_map_idx] = .{ .dug = here };
            next_map_idx += 1;
        }
    }

    std.sort.pdq(Tile, map, {}, tileTileCompare);
    digInterior(map, map[0..next_map_idx]);
    printMap(map);

    var part_1: i64 = 0;
    var dug_iter = DugIter{ .map = map };
    while (dug_iter.next()) |_| part_1 += 1;

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
