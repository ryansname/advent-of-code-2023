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

const INPUT = @embedFile("inputs/day10.txt");

pub fn main() !void {
    const result = try part1(INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

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
    var map_buffer = [_]u8{'.'} ** (150 * 150); // Approx correct size

    var width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var stride = width + 2;
    var total: usize = stride * 2;

    var input_idx: usize = 0;
    var output_offset: usize = stride + 1;
    while (input_idx + width - 1 < input.len) : (input_idx += width + 1) { // +1 for newline
        @memcpy(map_buffer[output_offset .. output_offset + width], input[input_idx .. input_idx + width]);
        output_offset += stride;
        total += stride;
    }
    var map = map_buffer[0..total];

    var start_idx: usize = 0;

    for (map, 0..) |c, idx| if (c == 'S') {
        start_idx = idx;
        break;
    };
    std.debug.assert(start_idx != 0);

    const Map = struct {
        fn print(info: []MapInfo, info_stride: usize) void {
            for (info, 0..) |i, idx| {
                std.debug.print("{c}", .{switch (i) {
                    .unknown => @as(u8, ' '),
                    // .loop => |c| c,
                    .loop => '.',
                    .left => '+',
                    .right => 'x',
                }});
                if (idx % info_stride == info_stride - 1) std.debug.print("\n", .{});
            }
        }
    };

    var first_dir: Dir(4) = undefined;
    var first_idx: usize = undefined;

    // First we'll build the map, travelling around the map, recording where the loop is
    {
        // Take the first step manually, so that we have a direction, then we can loop
        var start_neighbours = getNeighbours(4, map, start_idx, stride);
        const next_info: struct { idx: usize, dir: Dir(4) } = loop: for (start_neighbours) |neighbour| {
            const idx = neighbour.idx;
            const dir = neighbour.dir;
            switch (neighbour.char) {
                '|' => if (dir == .N or dir == .S) break :loop .{ .idx = idx, .dir = if (dir == .N) .N else .S },
                '-' => if (dir == .E or dir == .W) break :loop .{ .idx = idx, .dir = if (dir == .E) .E else .W },
                'L' => if (dir == .S or dir == .W) break :loop .{ .idx = idx, .dir = if (dir == .S) .E else .N },
                'F' => if (dir == .W or dir == .N) break :loop .{ .idx = idx, .dir = if (dir == .W) .S else .E },
                '7' => if (dir == .N or dir == .E) break :loop .{ .idx = idx, .dir = if (dir == .N) .W else .S },
                'J' => if (dir == .E or dir == .S) break :loop .{ .idx = idx, .dir = if (dir == .E) .N else .W },
                '.' => {},
                else => {
                    log.err("Bad character {c}", .{neighbour.char});
                    return error.BadCharacter;
                },
            }
        } else std.debug.panic("No connections to the start?", .{});

        first_idx = next_info.idx;
        first_dir = next_info.dir;
    }

    var info_buf = [_]MapInfo{.unknown} ** map_buffer.len;
    var info = info_buf[0..map.len];
    // It'd probably be better to just remember the start idx and replace it with the "real" char
    info[start_idx] = .{ .loop = 'S' };

    var part_1: i64 = undefined;
    {
        var here_idx = first_idx;
        var next_dir = first_dir;
        var steps: u63 = 1;
        while (here_idx != start_idx) : (steps += 1) {
            info[here_idx] = .{ .loop = map[here_idx] };
            const next_info = getNeighbour(next_dir, map, here_idx, stride);
            // log.info("At {c}, dir: {s}, next: {c}", .{ map[here_idx], @tagName(next_dir), next_info.char });

            std.debug.assert(map[here_idx] != '.');

            here_idx = next_info.idx;
            next_dir = switch (next_info.char) {
                '|' => if (next_dir == .N) .N else .S,
                '-' => if (next_dir == .E) .E else .W,
                'L' => if (next_dir == .S) .E else .N,
                'F' => if (next_dir == .W) .S else .E,
                '7' => if (next_dir == .N) .W else .S,
                'J' => if (next_dir == .E) .N else .W,
                'S' => undefined,
                else => std.debug.panic("Unreachable tile at {}: {c}", .{ next_info.idx, next_info.char }),
            };
        }

        part_1 = steps / 2;
    }

    // Now that we know where the loop is, we'll walk it again, this time marking the left and right sides into info
    {
        var here_idx = first_idx;
        var dir = first_dir;

        while (here_idx != start_idx) {
            const next_info = getNeighbour(dir, map, here_idx, stride);
            const sets: [2]struct { Dir(4), MapInfo } = switch (map[here_idx]) {
                '|' => if (dir == .N) .{ .{ .W, .left }, .{ .E, .right } } else .{ .{ .W, .right }, .{ .E, .left } },
                '-' => if (dir == .E) .{ .{ .N, .left }, .{ .S, .right } } else .{ .{ .N, .right }, .{ .S, .left } },
                'L' => if (dir == .E) .{ .{ .W, .right }, .{ .S, .right } } else .{ .{ .W, .left }, .{ .S, .left } },
                'F' => if (dir == .S) .{ .{ .N, .right }, .{ .W, .right } } else .{ .{ .N, .left }, .{ .W, .left } },
                '7' => if (dir == .W) .{ .{ .N, .right }, .{ .E, .right } } else .{ .{ .N, .left }, .{ .E, .left } },
                'J' => if (dir == .N) .{ .{ .E, .right }, .{ .S, .right } } else .{ .{ .E, .left }, .{ .S, .left } },
                'S' => undefined,
                else => std.debug.panic("Unreachable tile at {}: {c}", .{ next_info.idx, next_info.char }),
            };
            for (sets) |s| markDir(s.@"0", map, info, stride, here_idx, s.@"1");

            // log.info("At {c}, dir: {s}, next: {c}", .{ map[here_idx], @tagName(next_dir), next_info.char });

            std.debug.assert(map[here_idx] != '.');

            here_idx = next_info.idx;
            dir = switch (next_info.char) {
                '|' => if (dir == .N) .N else .S,
                '-' => if (dir == .E) .E else .W,
                'L' => if (dir == .S) .E else .N,
                'F' => if (dir == .W) .S else .E,
                '7' => if (dir == .N) .W else .S,
                'J' => if (dir == .E) .N else .W,
                'S' => undefined,
                else => std.debug.panic("Unreachable tile at {}: {c}", .{ next_info.idx, next_info.char }),
            };
        }
    }

    // Now lets just loop until all squares have a value, based on any L or R neighbours
    {
        var all_set = false;
        while (!all_set) {
            var set_one = false;
            all_set = true;

            for (info, 0..) |i, idx| {
                if (idx < stride or idx > info.len - stride) continue;
                if (idx % stride == 0 or idx % stride == stride - 1) continue;
                // Loops are already handled
                if (i != .unknown) continue;

                const neighbours = getNeighbours(4, info, idx, stride);
                const side_detected: MapInfo = blk: for (neighbours) |n| {
                    switch (n.char) {
                        .left, .right => {
                            set_one = true;
                            break :blk n.char;
                        },
                        else => {},
                    }
                } else .unknown;
                info[idx] = side_detected;
                if (info[idx] == .unknown) all_set = false;
            }

            std.debug.assert(set_one);
        }
    }

    var part_2: i64 = 0;
    // Final step, figure out whether right or left is inside or outside and count the inside cells
    {
        const outside: MapInfo = info[stride + 1];
        const inside: MapInfo = switch (outside) {
            .left => .right,
            .right => .left,
            else => unreachable,
        };
        for (info) |i| if (std.meta.eql(i, inside)) {
            part_2 += 1;
        };
    }

    Map.print(info, stride);

    return .{ .part1 = part_1, .part2 = part_2 };
}

const MapInfo = union(enum) {
    unknown: void,
    loop: u8,
    left: void,
    right: void,
};

fn markDir(dir: Dir(4), map: []const u8, map_info: []MapInfo, stride: usize, here_idx: usize, mark: MapInfo) void {
    const cell_info = getNeighbour(dir, map, here_idx, stride);
    const cell_idx = cell_info.idx;
    if (map_info[cell_idx] != .unknown) return;
    map_info[cell_idx] = mark;
}

const TEST_INPUT_1 =
    \\.....
    \\.S-7.
    \\.|.|.
    \\.L-J.
    \\.....
    \\
;

const TEST_INPUT_2 =
    \\..F7.
    \\.FJ|.
    \\SJ.L7
    \\|F--J
    \\LJ...
    \\
;

const TEST_INPUT_3 =
    \\...........
    \\.S-------7.
    \\.|F-----7|.
    \\.||.....||.
    \\.||.....||.
    \\.|L-7.F-J|.
    \\.|..|.|..|.
    \\.L--J.L--J.
    \\...........
    \\
;

test "simple test" {
    try std.testing.expectEqual(@as(i64, 4), (try part1(TEST_INPUT_1)).part1);
    try std.testing.expectEqual(@as(i64, 8), (try part1(TEST_INPUT_2)).part1);
    try std.testing.expectEqual(@as(i64, 4), (try part1(TEST_INPUT_3)).part2);
}
