const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const Dir = aoc.Dir(4);

const INPUT = @embedFile("inputs/day17.txt");

fn printMap(map: []Cell, stride: usize) void {
    for (map, 0..) |cell, idx| {
        if (idx % stride == 0) {
            std.debug.print("\n", .{});
        }

        const char: u8 = switch (cell) {
            .wall => ' ',
            .unexplored => |heat_loss| '0' + heat_loss,
            .fringe => 'F',
            .explored => |e| switch (e.prev_node_dir) {
                .N => 'v',
                .E => '<',
                .S => '^',
                .W => '>',
            },
        };
        std.debug.print("{c}", .{char});
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    const result = try part1(INPUT);

    std.debug.assert(result.part1 > 7343);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const ExploredCell = struct {
    total_heat_loss: i64,
    prev_node_idx: usize,
    prev_node_dir: Dir,
    dir_in_a_row: u8,
    cell_heat_loss: u8,
};
const Cell = union(enum) {
    wall: void,
    unexplored: u8, // heat loss
    fringe: ExploredCell,
    explored: ExploredCell,
};

fn tick(map: []Cell, stride: usize) bool {
    var min_idx: usize = 0;
    var min_cost: i64 = math.maxInt(i64);
    for (map, 0..) |tile, idx| {
        if (tile != .fringe) continue;
        if (tile.fringe.total_heat_loss < min_cost) {
            min_cost = tile.fringe.total_heat_loss;
            min_idx = idx;
        }
    }
    if (min_idx == 0) return false;

    const cell = map[min_idx].fringe;
    map[min_idx] = .{ .explored = cell };

    for (std.enums.values(Dir)) |dir| {
        if (dir == cell.prev_node_dir) continue;

        const new_fringe = &map[aoc.indexForDir(dir, min_idx, stride)];
        const dirs_in_a_row = if (dir.inverse() == cell.prev_node_dir) cell.dir_in_a_row + 1 else 0;
        if (dirs_in_a_row >= 3) continue;

        new_fringe.* = switch (new_fringe.*) {
            .wall => continue,
            .explored => continue,
            .unexplored => |heat_loss| .{ .fringe = .{
                .total_heat_loss = cell.total_heat_loss + heat_loss,
                .prev_node_idx = min_idx,
                .prev_node_dir = dir.inverse(),
                .dir_in_a_row = dirs_in_a_row,
                .cell_heat_loss = heat_loss,
            } },
            .fringe => |f| if (cell.total_heat_loss + f.cell_heat_loss > f.total_heat_loss) continue else .{ .fringe = .{
                .total_heat_loss = cell.total_heat_loss + f.cell_heat_loss,
                .prev_node_idx = min_idx,
                .prev_node_dir = dir.inverse(),
                .dir_in_a_row = dirs_in_a_row,
                .cell_heat_loss = f.cell_heat_loss,
            } },
        };
    }
    return true;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var map_buffer = [_]Cell{.wall} ** (150 * 150); // Approx correct size

    var width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var stride = width + 2;
    var total: usize = stride * 2;

    var input_idx: usize = 0;
    var output_offset: usize = stride + 1;
    while (input_idx + width - 1 < input.len) : (input_idx += width + 1) { // +1 for newline
        for (map_buffer[output_offset .. output_offset + width], input[input_idx .. input_idx + width]) |*out, in| {
            out.* = switch (in) {
                '1'...'9' => .{ .unexplored = in - '0' },
                else => unreachable,
            };
        }
        output_offset += stride;
        total += stride;
    }
    var map = map_buffer[0..total];

    // Start in the top left, but you don't pay the cost to enter it
    map[stride + 2] = .{ .fringe = .{
        .total_heat_loss = map[stride + 2].unexplored,
        .prev_node_idx = stride + 1,
        .prev_node_dir = .W,
        .dir_in_a_row = 0,
        .cell_heat_loss = map[stride + 2].unexplored,
    } };
    map[stride + stride + 1] = .{ .fringe = .{
        .total_heat_loss = map[stride + stride + 1].unexplored,
        .prev_node_idx = stride + 1,
        .prev_node_dir = .N,
        .dir_in_a_row = 0,
        .cell_heat_loss = map[stride + stride + 1].unexplored,
    } };

    printMap(map, stride);

    while (tick(map, stride)) {
        printMap(map, stride);
        std.debug.print("{}\n", .{map[total - stride - 2]});
    }

    var part_1: i64 = map[total - stride - 2].explored.total_heat_loss;
    var part_2: i64 = 0;
    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\2413432311323
    \\3215453535623
    \\3255245654254
    \\3446585845452
    \\4546657867536
    \\1438598798454
    \\4457876987766
    \\3637877979653
    \\4654967986887
    \\4564679986453
    \\1224686865563
    \\2546548887735
    \\4322674655533
;

test "simple test part1" {
    const result = try part1(TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 102), result.part1);
    try std.testing.expectEqual(@as(i64, 0), result.part2);
}
