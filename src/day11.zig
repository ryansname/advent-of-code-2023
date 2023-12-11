const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

fn iter_lines(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, '\n');
}

fn iter_tokens(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, ' ');
}

fn print2d(data: []const Cell, print_stride: usize) void {
    for (data, 0..) |d, idx| {
        std.debug.print("{c}", .{switch (d) {
            .wall => @as(u8, '+'),
            .galaxy => '#',
            .nothing => '.',
            .warp => ':',
        }});
        if (idx % print_stride == print_stride - 1) std.debug.print("\n", .{});
    }
}
fn Dir(comptime dirs: u8) type {
    return switch (dirs) {
        4 => enum { N, S, E, W },
        8 => enum { N, S, E, W, NE, SE, NW, SW },
        else => @compileError("Unsupported number of dirs " ++ dirs),
    };
}
fn NeighboursReturn(comptime dirs: u8, comptime BufferType: type) type {
    return [dirs]struct { char: @typeInfo(BufferType).Pointer.child, idx: usize, dir: Dir(dirs) };
}
fn getNeighbours(comptime dirs: u8, buffer: anytype, i: usize, stride: usize) NeighboursReturn(dirs, @TypeOf(buffer)) {
    const offsets = switch (dirs) {
        4 => .{
            .{ i - stride, .N },
            .{ i + stride, .S },
            .{ i - 1, .W },
            .{ i + 1, .E },
        },
        8 => .{
            .{ i - stride, .N },
            .{ i - stride - 1, .NW },
            .{ i - stride + 1, .NE },
            .{ i + stride, .S },
            .{ i + stride - 1, .SW },
            .{ i + stride + 1, .SE },
            .{ i - 1, .W },
            .{ i + 1, .E },
        },
        else => @compileError("Unsupported number of dirs " ++ dirs),
    };

    var result: NeighboursReturn(dirs, @TypeOf(buffer)) = undefined;

    inline for (offsets, &result) |d, *r| {
        r.* = .{
            .char = buffer[d.@"0"],
            .idx = d.@"0",
            .dir = d.@"1",
        };
    }
    return result;
}

const INPUT = @embedFile("inputs/day11.txt");

pub fn main() !void {
    const result = try part1(INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const Cell = union(enum) {
    wall: void,
    nothing: void,
    warp: void,
    galaxy: u16,
};

fn getNeighbour(dir: Dir(4), buffer: []const u8, i: usize, stride: usize) struct { char: u8, idx: usize, dir: Dir(4) } {
    const options = .{
        .{ i - stride, .N },
        // .{ i - stride - 1, .NW },
        // .{ i - stride + 1, .NE },
        .{ i + stride, .S },
        // .{ i + stride - 1, .SW },
        // .{ i + stride + 1, .SE },
        .{ i - 1, .W },
        .{ i + 1, .E },
    };
    inline for (options) |option| {
        if (option.@"1" == dir) {
            return .{ .char = buffer[option.@"0"], .idx = option.@"0", .dir = dir };
        }
    } else unreachable;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var raw_map_buffer = [_]u8{'.'} ** (150 * 150); // Approx correct size

    var raw_width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var raw_stride = raw_width + 2;
    var raw_total: usize = raw_stride * 2;

    var input_idx: usize = 0;
    var output_offset: usize = raw_stride + 1;
    while (input_idx + raw_width - 1 < input.len) : (input_idx += raw_width + 1) { // +1 for newline
        @memcpy(raw_map_buffer[output_offset .. output_offset + raw_width], input[input_idx .. input_idx + raw_width]);
        output_offset += raw_stride;
        raw_total += raw_stride;
    }
    var raw_map = raw_map_buffer[0..raw_total];

    var stride = raw_stride;
    var src_cols_to_double = [_]bool{false} ** 200;
    var src_rows_to_double = [_]bool{false} ** 200;
    // Add extra rows where there's no galaxies
    {
        for (1..raw_stride - 1) |col| {
            for (1..raw_total / raw_stride) |row| {
                if (raw_map[col + row * raw_stride] != '.') break;
            } else {
                src_cols_to_double[col] = true;
            }
        }
        for (1..(raw_total / raw_stride) - 1) |row| {
            for (0..raw_stride) |col| {
                if (raw_map[col + row * raw_stride] != '.') break;
            } else {
                src_rows_to_double[row] = true;
            }
        }
    }

    var map_buffer: [200 * 200]Cell = undefined; // Approx correct size

    var col_being_processed: usize = 0;
    var row_being_processed: usize = 0;
    input_idx = 0;
    output_offset = 0;
    var next_galaxy_id: u16 = 0;
    while (input_idx < raw_map.len) : (input_idx += 1) {
        map_buffer[output_offset] = if (row_being_processed == 0 or row_being_processed == (raw_total - 1) / raw_stride) blk: {
            break :blk .wall;
        } else if (col_being_processed == 0 or col_being_processed == raw_stride - 1) blk: {
            break :blk .wall;
        } else switch (raw_map_buffer[input_idx]) {
            '.' => if (src_cols_to_double[col_being_processed] or src_rows_to_double[row_being_processed]) .warp else .nothing,
            '#' => blk: {
                next_galaxy_id += 1;
                break :blk .{ .galaxy = next_galaxy_id };
            },
            else => unreachable,
        };
        output_offset += 1;

        col_being_processed += 1;
        if (col_being_processed == raw_stride) {
            col_being_processed = 0;
            row_being_processed += 1;
        }
    }
    var map = map_buffer[0..output_offset];
    // print2d(map, stride);

    var part_1: i64 = 0;
    var part_2: i64 = 0;

    var progress = std.Progress{};
    var progress_node = progress.start("Solving", next_galaxy_id);
    progress_node.activate();
    for (1..next_galaxy_id + 1) |start_id| {
        defer progress_node.completeOne();
        for (start_id + 1..next_galaxy_id + 1) |end_id| {
            part_1 += findManhattan(map, 2, stride, @intCast(start_id), @intCast(end_id));
            part_2 += findManhattan(map, 1_000_000, stride, @intCast(start_id), @intCast(end_id));
        }
    }
    progress_node.end();

    return .{ .part1 = part_1, .part2 = part_2 };
}

fn findManhattan(map: []const Cell, warp_speed: u63, stride: usize, start_galaxy_id: u16, end_galaxy_id: u16) u63 {
    var start_idx: usize = 0;
    var end_idx: usize = 0;

    for (map, 0..) |cell, idx| switch (cell) {
        .wall, .nothing, .warp => {},
        .galaxy => |galaxy_id| if (galaxy_id == start_galaxy_id) {
            start_idx = idx;
        } else if (galaxy_id == end_galaxy_id) {
            end_idx = idx;
        },
    };

    std.debug.assert(start_idx != 0);
    std.debug.assert(end_idx != 0);

    const start_col = start_idx % stride;
    const start_row = start_idx / stride;

    const end_col = end_idx % stride;
    const end_row = end_idx / stride;

    var distance: u63 = 0;

    for (@min(start_col, end_col)..@max(start_col, end_col)) |col| {
        switch (map[col + start_row * stride]) {
            .wall => unreachable,
            .nothing, .galaxy => distance += 1,
            .warp => distance += warp_speed,
        }
    }
    for (@min(start_row, end_row)..@max(start_row, end_row)) |row| {
        switch (map[row * stride + start_col]) {
            .wall => unreachable,
            .nothing, .galaxy => distance += 1,
            .warp => distance += warp_speed,
        }
    }

    return distance;
}

const TEST_INPUT_1 =
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
    \\
;

test "simple test" {
    try std.testing.expectEqual(@as(i64, 374), (try part1(TEST_INPUT_1)).part1);
    try std.testing.expectEqual(@as(i64, 82000210), (try part1(TEST_INPUT_1)).part2);
}
