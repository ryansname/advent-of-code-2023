const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const Dir = aoc.Dir(4);

const INPUT = @embedFile("inputs/day21.txt");

pub fn main() !void {
    // const result = try part1(INPUT, 64);
    const result_2 = try part2(INPUT);

    const stdout = std.io.getStdOut().writer();
    // try stdout.print("Part 1: {}\n", .{result.part1});
    try stdout.print("Part 2: {}\n", .{result_2.part2});
}

const Cell = union(enum) {
    rock: void,
    garden_e: void,
    garden_u: void,
    fringe: void,
};

fn flood(map: []Cell, stride: usize, steps: usize) void {
    for (0..steps) |_| {
        for (map, 0..) |*cell, idx| {
            if (cell.* == .garden_e) continue;
            if (cell.* == .rock) continue;

            for (aoc.getNeighbours(4, map, idx, stride)) |neighbours| {
                switch (neighbours.char) {
                    .garden_e => cell.* = .fringe,
                    else => {},
                }
            }
        }

        for (map) |*c| {
            if (c.* == .fringe) c.* = .garden_e;
        }
    }
}

fn countCellsFromStart(
    map: []Cell,
    stride: usize,
    even_or_odd: enum { even, odd },
    start_idx: usize,
) i64 {
    const start_row = start_idx / stride;
    const start_col = start_idx % stride;

    var total: i64 = 0;
    for (map, 0..) |cell, idx| {
        switch (cell) {
            .garden_e => {
                const row = idx / stride;
                const col = idx % stride;

                const distance = @max(row, start_row) - @min(row, start_row) + @max(col, start_col) - @min(col, start_col);
                switch (even_or_odd) {
                    .even => if (distance % 2 == 0) {
                        total += 1;
                    },
                    .odd => if (distance % 2 == 1) {
                        total += 1;
                    },
                }
            },
            else => {},
        }
    }
    return total;
}

fn part2(input: []const u8) !struct { part1: i64, part2: i64 } {
    var map_template_buffer = [_]Cell{.rock} ** (150 * 150); // Approx correct size
    var map_buffer = [_]Cell{.rock} ** (150 * 150); // Approx correct size

    var width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var stride = width + 2;
    var total: usize = stride * 2;

    var input_idx: usize = 0;
    var output_offset: usize = stride + 1;
    while (input_idx + width - 1 < input.len) : (input_idx += width + 1) { // +1 for newline
        for (map_template_buffer[output_offset .. output_offset + width], input[input_idx .. input_idx + width]) |*out, in| {
            out.* = switch (in) {
                '.' => .garden_u,
                'S' => .garden_u,
                '#' => .rock,
                else => unreachable,
            };
        }
        output_offset += stride;
        total += stride;
    }
    var map_template = map_template_buffer[0..total];
    var map = map_buffer[0..total];

    @memcpy(map, map_template);
    // map[stride + stride / 2] = .garden_e;
    // map[stride * (stride / 2) + 1] = .garden_e;
    map[stride * stride / 2] = .garden_e; // Map center

    var steps_north: i64 = 0;
    printMap(map, stride);

    while (map[stride + stride / 2] == .garden_u) {
        flood(map, stride, 1);
        steps_north += 1;
    }
    std.debug.print("After {} steps north:\n", .{steps_north});
    printMap(map, stride);
    const steps_from_start_to_inner_edge = steps_north;

    // Now, reset the map
    @memcpy(map, map_template);
    // Set the corresponding middle bottom square to explored
    // noting that this is a virtual step
    map[stride * stride - stride - stride / 2 - 1] = .garden_e;
    steps_north += 1;
    std.debug.print("After {} steps north:\n", .{steps_north});
    printMap(map, stride);
    const steps_from_start_to_outer_edge = steps_north;
    _ = steps_from_start_to_outer_edge;

    // Walk all the way north again
    while (map[stride + stride / 2] == .garden_u) {
        flood(map, stride, 1);
        steps_north += 1;
    }
    std.debug.print("After {} steps north:\n", .{steps_north});
    printMap(map, stride);

    const steps_inner_edge_to_inner_edge = steps_north - steps_from_start_to_inner_edge;
    std.debug.print("Took {} steps to get to this point from the same one a map before\n", .{steps_inner_edge_to_inner_edge});

    const steps_to_take: i64 = 26501365;
    const steps_to_take_excluding_start = steps_to_take - steps_from_start_to_inner_edge;
    const maps_to_get_from_center_to_edge = @divFloor(steps_to_take_excluding_start, steps_inner_edge_to_inner_edge);
    const remaining_steps_to_take = steps_to_take_excluding_start - maps_to_get_from_center_to_edge * steps_inner_edge_to_inner_edge;
    _ = remaining_steps_to_take;
    // std.debug.print("Remaining steps to take: {}\n", .{remaining_steps_to_take});
    std.debug.print("Total tiles from center to edge (exc center): {}\n", .{maps_to_get_from_center_to_edge});

    inline for (.{
        stride + stride / 2, // Top Center
        stride * (stride / 2) + 1, // Left Center
        stride * stride - stride - stride / 2 - 1, // Bottom Center
        stride * (stride / 2) + stride - 2, // Right Center
    }) |idx| {
        // Now, reset the map
        @memcpy(map, map_template);
        // Set the corresponding middle bottom square to explored
        // noting that this is a virtual step
        map[idx] = .garden_e;
        flood(map, stride, @intCast(steps_inner_edge_to_inner_edge - 1));
        printMap(map, stride);
    }

    // Ok we know:
    // For entirely full maps, there's and even map and an odd map
    // The corner maps all perfectly touch the edge
    // The outside edge are all "active" / odd cells
    // Edges will be either a corner full or the opposide corner empty

    //       ../\..
    //       ./##\.
    //     ../#++#\..
    //     ./##++##\.
    //   ../#++##++#\..
    //   ./##++##++##\.
    // ../#++##++##++#\..
    // ./##++##++##++##\.

    // Each row is has both of the edge pieces + a triangle number of full blocks
    // with n & n-1 of each type of cell

    @memcpy(map, map_template);
    map[stride + 1] = .garden_e;
    flood(map, stride, @intCast(steps_from_start_to_inner_edge));
    printMap(map, stride);
    map[stride + 1] = .garden_e;
    flood(map, stride, @intCast(steps_inner_edge_to_inner_edge));
    printMap(map, stride);

    const full_count_even = countCellsFromStart(map, stride, .even, stride * stride / 2);
    const full_count_odd = countCellsFromStart(map, stride, .odd, stride * stride / 2);
    const center_tile_count = full_count_odd;
    std.debug.print("Count a: {}, count b: {}\n", .{ full_count_even, full_count_odd });
    _ = center_tile_count;

    var part_2: i64 = 0;
    {
        // Total tiles does not include the center tile, and does include the tip tile
        const full_tiles = maps_to_get_from_center_to_edge - 1;
        //       ../\..
        //       ./##\.
        //     ../#++#\..
        //     ./##++##\.
        //   ../#++##++#\..
        //   ./##++##++##\.
        // ../#++##++##++#\
        // ..\#++##++##++#/
        //   .\##++##++##/.
        //   ..\#++##++#/..
        //     .\##++##/.
        //     ..\#++#/..
        //       .\##/.
        //       ..\/..

        for (0..@intCast(full_tiles)) |row| {
            const full_tiles_in_square = row * row;
            const inner_tiles_in_square = if (row > 2) (row - 2) * (row - 2) else 0;
            const possibilities = if (row % 2 == 0) full_count_odd else full_count_even;
            std.debug.print("{}: {}\n", .{ row, part_2 });
            part_2 += possibilities * @as(i64, @intCast(full_tiles_in_square - inner_tiles_in_square));
        }

        // Corners = 4
        // Inside edges + corners = (2^(full_tiles - 2)) / 4
        // Outside edges = (2 ^ full_tiles - 1) / 4
    }

    return .{ .part1 = 0, .part2 = part_2 };
}

fn printMap(map: []Cell, stride: usize) void {
    for (map, 0..) |c, idx| {
        if (idx % stride == 0) std.debug.print("\n", .{});
        std.debug.print("{c}", .{switch (c) {
            .garden_e => @as(u8, 'O'),
            .garden_u => '.',
            .fringe => 'f',
            .rock => '#',
        }});
    } else std.debug.print("\n", .{});
}

const TEST_INPUT_1 =
    \\...........
    \\.....###.#.
    \\.###.##..#.
    \\..#.#...#..
    \\....#.#....
    \\.##..S####.
    \\.##..#...#.
    \\.......##..
    \\.##.#.####.
    \\.##..##.##.
    \\...........
;

test "simple test part1" {
    // const result = try part1(TEST_INPUT_1, 6);
    // try std.testing.expectEqual(@as(i64, 16), result.part1);
    // try std.testing.expectEqual(@as(i64, 0), result.part2);
}
