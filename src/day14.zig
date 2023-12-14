const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const print = std.debug.print;
//const print = printToVoid;

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

const INPUT = @embedFile("inputs/day14.txt");

pub fn main() !void {
    const result = try part1(INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

const Rock = enum {
    roller,
    not_roller,
    nothing,
};

fn printDat(map: []Rock, stride: usize) void {
    for (map, 0..) |cell, idx| {
        print("{c}", .{switch (cell) {
            .roller => @as(u8, 'O'),
            .not_roller => '#',
            .nothing => '.',
        }});

        if (idx % stride == stride - 1) print("\n", .{});
    }
}

fn rollThatStuff(map: []Rock, stride: usize, comptime direction: Dir(4)) void {
    const height: u63 = @intCast(map.len / stride);
    const s: struct {
        scan_start: usize,
        scan_step: i64,
        scan_count: usize,
        roll_start: usize,
        roll_step: i64,
        roll_count: usize,

        fn calc(start: usize, num: usize, step: i64) usize {
            const start_i64: i64 = @intCast(start);
            const num_i64: i64 = @intCast(num);

            const offset: i64 = num_i64 * step;
            const result_i64: i64 = @intCast(start_i64 + offset);
            return @intCast(result_i64);
        }

        fn calcScan(s: @This(), scan_num: usize) usize {
            return calc(s.scan_start, scan_num, s.scan_step);
        }

        fn calcRoll(s: @This(), roll_num: usize) usize {
            return calc(s.roll_start, roll_num, s.roll_step);
        }
    } = switch (direction) {
        .N => .{
            .scan_start = 0,
            .scan_step = 1,
            .scan_count = stride,
            .roll_start = 0,
            .roll_step = @intCast(stride),
            .roll_count = height,
        },
        .S => .{
            .scan_start = 0,
            .scan_step = 1,
            .scan_count = stride,
            .roll_start = (height - 1) * stride,
            .roll_step = -@as(i64, @intCast(stride)),
            .roll_count = height,
        },
        .E => .{
            .scan_start = 0,
            .scan_step = @intCast(stride),
            .scan_count = height,
            .roll_start = stride - 1,
            .roll_step = -1,
            .roll_count = stride,
        },
        .W => .{
            .scan_start = 0,
            .scan_step = @intCast(stride),
            .scan_count = height,
            .roll_start = 0,
            .roll_step = 1,
            .roll_count = stride,
        },
    };

    var placements = [_]usize{0} ** 512;
    for (0..s.scan_count) |scan_num| {
        const scan = s.calcScan(scan_num);
        placements = [_]usize{0} ** 512;
        var placement_read_idx: usize = 0;
        var placement_write_idx: usize = 0;

        for (0..s.roll_count) |roll_num| {
            const roll = s.calcRoll(roll_num);
            const idx = scan + roll;
            switch (map[idx]) {
                .nothing => {
                    placements[placement_write_idx] = idx;
                    placement_write_idx += 1;
                },
                .not_roller => {
                    placement_write_idx = 0;
                    placement_read_idx = 0;
                },
                .roller => {
                    if (placement_read_idx != placement_write_idx) {
                        map[placements[placement_read_idx]] = .roller;
                        map[idx] = .nothing;
                        placements[placement_write_idx] = idx;
                        placement_read_idx += 1;
                        placement_write_idx += 1;
                    }
                },
            }
        }
    }
}

fn calculateLoad(map: []Rock, stride: usize) u63 {
    var result: u63 = 0;
    const height = map.len / stride;
    for (1..height - 1) |row| {
        const load_per_rock: u63 = @intCast(height - 1 - row); // -1 for the top boundary row I added

        for (map[row * stride .. (row + 1) * stride]) |cell| switch (cell) {
            .roller => result += load_per_rock,
            else => {},
        };
    }

    return result;
}

fn rollCycle(map: []Rock, stride: usize) void {
    rollThatStuff(map, stride, .N);
    rollThatStuff(map, stride, .W);
    rollThatStuff(map, stride, .S);
    rollThatStuff(map, stride, .E);
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var map_buffer = [_]Rock{.not_roller} ** (150 * 150); // Approx correct size

    var width: usize = mem.indexOfScalar(u8, input, '\n') orelse return error.BadInput;
    var stride = width + 2;
    var total: usize = stride * 2;

    var input_idx: usize = 0;
    var output_offset: usize = stride + 1;
    while (input_idx + width - 1 < input.len) : (input_idx += width + 1) { // +1 for newline
        for (map_buffer[output_offset .. output_offset + width], input[input_idx .. input_idx + width]) |*out, in| {
            out.* = switch (in) {
                'O' => .roller,
                '#' => .not_roller,
                '.' => .nothing,
                else => unreachable,
            };
        }
        output_offset += stride;
        total += stride;
    }
    var map = map_buffer[0..total];

    var cycles_simulated: u64 = 0;

    rollThatStuff(map, stride, .N);
    var part_1: i64 = @intCast(calculateLoad(map, stride));
    rollThatStuff(map, stride, .W);
    rollThatStuff(map, stride, .S);
    rollThatStuff(map, stride, .E);
    cycles_simulated += 1;

    // Generate a bunch of cycles to make sure we're in the loop of destiny
    while (cycles_simulated < 1000) : (cycles_simulated += 1) {
        rollCycle(map, stride);
    }

    // Take a copy of the current state
    var cycle_target_buf: [map_buffer.len]Rock = undefined;
    @memcpy(&cycle_target_buf, &map_buffer);
    const cycle_target = cycle_target_buf[0..map.len];

    // Now cycle until we find a loop
    const loop_start = cycles_simulated;
    while (true) {
        rollCycle(map, stride);
        cycles_simulated += 1;
        if (mem.eql(Rock, map, cycle_target)) break;
    }

    const cycles_per_loop = cycles_simulated - loop_start;
    print("Loop length: {}\n", .{cycles_per_loop});

    const target_cycles = 1000000000;
    const cycles_to_go = target_cycles - cycles_simulated;
    const num_loops = cycles_to_go / cycles_per_loop;
    const cycles_to_skip = num_loops * cycles_per_loop;

    // Now we can skip a bunch
    cycles_simulated += cycles_to_skip;
    print("Skipping {} cycles. {} to go\n", .{ cycles_to_skip, target_cycles - cycles_simulated });

    // And get to the target
    for (cycles_simulated..target_cycles) |_| {
        rollCycle(map, stride);
    }

    var part_2: i64 = @intCast(calculateLoad(map, stride));
    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\O....#....
    \\O.OO#....#
    \\.....##...
    \\OO.#O....O
    \\.O.....O#.
    \\O.#..O.#.#
    \\..O..#O..O
    \\.......O..
    \\#....###..
    \\#OO..#....
    \\
;

test "simple test part1" {
    const result = try part1(TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 136), result.part1);
    try std.testing.expectEqual(@as(i64, 64), result.part2);
}
