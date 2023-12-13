const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const print = std.debug.print;
// const print = printToVoid;

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

fn print2d(data: []const u8, print_stride: usize) void {
    for (data, 0..) |d, idx| {
        print("{c}", .{d});
        if (idx % print_stride == print_stride - 1) print("\n", .{});
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

const INPUT = @embedFile("inputs/day13.txt");

pub fn main() !void {
    const result = try part1(INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const Cell = enum(u8) {
    ash = '.',
    rocks = '#',
    wall = '+',
};

const Part = enum { part1, part2 };

fn getMismatchesWhenReflectingBetweenCols(map: []const Cell, stride: usize, col_1: usize, col_2: usize) u63 {
    // out of bounds means they are equal
    if (col_2 >= stride) return 0;
    if (map[col_1 + stride] == .wall or map[col_2 + stride] == .wall) return 0;

    var mismatches: u63 = 0;
    for (0..map.len / stride) |row| {
        if (map[col_1 + row * stride] != map[col_2 + row * stride]) mismatches += 1;
    }
    return mismatches;
}

fn getMismatchesWhenReflectingBetweenRows(map: []const Cell, stride: usize, row_1: usize, row_2: usize) u63 {
    // out of bounds means they are equal
    if (row_2 * stride >= map.len) return 0;
    if (map[row_1 * stride + 1] == .wall or map[row_2 * stride + 1] == .wall) return 0;

    var mismatches: u63 = 0;
    for (0..stride) |col| {
        if (map[col + row_1 * stride] != map[col + row_2 * stride]) mismatches += 1;
    }
    return mismatches;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var part_1: i64 = 0;
    var part_2: i64 = 0;

    var map_iter = mem.splitSequence(u8, input, "\n\n");
    while (map_iter.next()) |raw_map| {
        var map_buffer = [_]Cell{.wall} ** (150 * 150); // Approx correct size

        var width: usize = mem.indexOfScalar(u8, raw_map, '\n') orelse return error.BadInput;
        var stride = width + 2;
        var total: usize = stride * 2;

        var input_idx: usize = 0;
        var output_offset: usize = stride + 1;
        while (input_idx + width - 1 < raw_map.len) : (input_idx += width + 1) { // +1 for newline
            for (map_buffer[output_offset .. output_offset + width], raw_map[input_idx .. input_idx + width]) |*map_buf_item, input_item| {
                map_buf_item.* = std.meta.intToEnum(Cell, input_item) catch |err| {
                    log.err("Bad enum value {c}", .{input_item});
                    return err;
                };
            }
            output_offset += stride;
            total += stride;
        }
        var map = map_buffer[0..total];

        inline for (comptime std.enums.values(Part)) |part| {
            var result, const target = switch (part) {
                .part1 => .{ &part_1, 0 },
                .part2 => .{ &part_2, 1 },
            };
            // log.err("Finding mirror for " ++ @tagName(part), .{});

            // Check left to right for a mirror
            col_check: for (1..stride - 2, 2..stride - 1) |test_col_1, test_col_2| {
                if (getMismatchesWhenReflectingBetweenCols(map, stride, test_col_1, test_col_2) > target) continue;
                // log.err("columns are equal {} & {}", .{ test_col_1, test_col_2 });

                var total_mismatches: u63 = 0;
                for (0..test_col_1 + 1) |col_1| {
                    const col_2 = test_col_2 + test_col_1 - col_1;
                    const this_mismatches = getMismatchesWhenReflectingBetweenCols(map, stride, col_1, col_2);
                    total_mismatches += this_mismatches;
                    // log.err("Checking {} vs {}: {}", .{ col_1, col_2, this_mismatches });
                    if (total_mismatches > target) continue :col_check;
                }

                // log.err("Mirror between cols {} and {} mismatches {} of {}", .{ test_col_1, test_col_2, total_mismatches, target });
                if (total_mismatches == target) {
                    result.* += @intCast(test_col_1);
                    break;
                }
            } else {
                const height = total / stride;
                row_check: for (1..height - 2, 2..height - 1) |test_row_1, test_row_2| {
                    if (getMismatchesWhenReflectingBetweenRows(map, stride, test_row_1, test_row_2) > target) continue;
                    // log.err("rows are equal {} & {}", .{ test_row_1, test_row_2 });

                    var total_mismatches: u63 = 0;
                    for (0..test_row_1 + 1) |row_1| {
                        const row_2 = test_row_2 + test_row_1 - row_1;
                        const this_mismatches = getMismatchesWhenReflectingBetweenRows(map, stride, row_1, row_2);
                        total_mismatches += this_mismatches;
                        // log.err("Checking {} vs {}: {}", .{ row_1, row_2, this_mismatches });
                        if (total_mismatches > target) continue :row_check;
                    }

                    // log.err("Mirror between rows {} and {} mismatches {} of {}", .{ test_row_1, test_row_2, total_mismatches, target });
                    if (total_mismatches == target) {
                        result.* += @intCast(100 * test_row_1);
                        break;
                    }
                } else {
                    unreachable;
                }
            }
        }
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
    \\
    \\#...##..#
    \\#....#..#
    \\..##..###
    \\#####.##.
    \\#####.##.
    \\..##..###
    \\#....#..#
    \\
;

test "simple test part1" {
    try std.testing.expectEqual(@as(i64, 405), (try part1(TEST_INPUT_1)).part1);
    try std.testing.expectEqual(@as(i64, 400), (try part1(TEST_INPUT_1)).part2);
}
