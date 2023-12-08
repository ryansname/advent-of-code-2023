const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

fn iter_lines(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, '\n');
}

const INPUT = @embedFile("inputs/day08.txt");

pub fn main() !void {
    const result = try part_1(INPUT);
    log.info("Part 1: {}", .{result.part1});

    const result_2 = try part_2(INPUT);
    log.info("Part 2: {}", .{result_2.part2});
}

const Fork = struct {
    here: u15,
    left: u15,
    right: u15,
};

fn decode(node: []const u8) u15 {
    return (@as(u15, @intCast(node[0])) << 10) + (@as(u15, @intCast(node[1])) << 5) + @as(u15, @intCast(node[2]));
}

fn isEnd(node: u15) bool {
    return node & math.maxInt(u5) == 'Z' & math.maxInt(u5);
}

fn find_fork(nodes: []Fork, here: u15) Fork {
    for (nodes) |node| if (node.here == here) return node;
    @panic("We're lost");
}

fn part_1(input: []const u8) !struct { part1: u64, part2: u64 } {
    var node_buf: [1000]Fork = undefined;
    var line_iter = iter_lines(input);

    const instructions = line_iter.next().?;

    var node_idx: usize = 0;
    while (line_iter.next()) |line| {
        var node = &node_buf[node_idx];
        node_idx += 1;

        node.here = decode(line[0..3]);
        node.left = decode(line[7..10]);
        node.right = decode(line[12..15]);
    }
    const nodes = node_buf[0..node_idx];

    var here = decode("AAA");
    const end = decode("ZZZ");

    var steps: u64 = 0;
    loop: while (true) {
        for (instructions) |i| {
            steps += 1;
            switch (i) {
                'L' => here = find_fork(nodes, here).left,
                'R' => here = find_fork(nodes, here).right,
                else => std.debug.panic("Unknown instruction {c}", .{i}),
            }
            if (here == end) break :loop;
        }
    }

    return .{ .part1 = steps, .part2 = 0 };
}

fn part_2(input: []const u8) !struct { part1: u64, part2: u64 } {
    var node_buf: [1000]Fork = undefined;
    var heres_buf: [32]u15 = undefined;

    var line_iter = iter_lines(input);

    const instructions = line_iter.next().?;

    var heres_idx: usize = 0;
    var node_idx: usize = 0;
    while (line_iter.next()) |line| {
        var node = &node_buf[node_idx];
        node_idx += 1;

        node.here = decode(line[0..3]);
        node.left = decode(line[7..10]);
        node.right = decode(line[12..15]);

        if (line[2] == 'A') {
            heres_buf[heres_idx] = node.here;
            heres_idx += 1;
        }
    }
    const nodes = node_buf[0..node_idx];
    var heres = heres_buf[0..heres_idx];
    // log.info("Ghosts: {}", .{heres.len});
    var steps_to_loop: [64]u64 = .{0} ** 64;
    var steps_in_loop: [64]u64 = .{0} ** 64;

    var steps: u64 = 0;
    loop: while (true) {
        for (instructions) |i| {
            steps += 1;

            for (heres, 0..) |*here, ghost| {
                switch (i) {
                    'L' => here.* = find_fork(nodes, here.*).left,
                    'R' => here.* = find_fork(nodes, here.*).right,
                    else => std.debug.panic("Unknown instruction {c}", .{i}),
                }

                if (isEnd(here.*)) {
                    if (steps_to_loop[ghost] == 0) {
                        steps_to_loop[ghost] = steps;
                    } else if (steps_in_loop[ghost] == 0) {
                        steps_in_loop[ghost] = steps - steps_to_loop[ghost];
                    }
                }
            }

            var all_known = true;
            for (steps_in_loop[0..heres.len]) |s| {
                all_known = all_known and s != 0;
            }
            if (all_known) break :loop;
        }
    }

    for (steps_to_loop[0..heres.len], steps_in_loop[0..heres.len], 1..) |to, in, ghost| {
        log.info("Ghost {}: {} + {}n", .{ ghost, to, in });
    }

    var steps_short_buf: [64]u64 = undefined;
    @memcpy(&steps_short_buf, &steps_to_loop);
    var steps_short = steps_short_buf[0..heres.len];
    for (steps_short) |ss| steps = @max(ss, steps);

    loop: while (true) {
        // Any ghost behind the leader will move
        var max_idx: usize = 0;
        for (steps_short[1..], 1..) |ss, idx| {
            if (steps_short[max_idx] < ss) max_idx = idx;
        }
        for (steps_short, 0..) |*ss, idx| {
            if (ss.* < steps_short[max_idx]) {
                ss.* += steps_in_loop[idx];
            }
        }

        // If all the ghosts are now at the same index, we're done
        for (steps_short) |ss| {
            if (steps_short[max_idx] != ss) break;
        } else {
            break :loop;
        }
    }

    return .{ .part1 = 0, .part2 = steps_short[0] };
}

const TEST_INPUT =
    \\RL
    \\
    \\AAA = (BBB, CCC)
    \\BBB = (DDD, EEE)
    \\CCC = (ZZZ, GGG)
    \\DDD = (DDD, DDD)
    \\EEE = (EEE, EEE)
    \\GGG = (GGG, GGG)
    \\ZZZ = (ZZZ, ZZZ)    
    \\
;

const TEST_INPUT_2 =
    \\LLR
    \\
    \\AAA = (BBB, BBB)
    \\BBB = (AAA, ZZZ)
    \\ZZZ = (ZZZ, ZZZ)
    \\
;

const TEST_INPUT_3 =
    \\LR
    \\
    \\11A = (11B, XXX)
    \\11B = (XXX, 11Z)
    \\11Z = (11B, XXX)
    \\22A = (22B, XXX)
    \\22B = (22C, 22C)
    \\22C = (22Z, 22Z)
    \\22Z = (22B, 22B)
    \\XXX = (XXX, XXX)
    \\
;

test "simple test" {
    const results = try part_1(TEST_INPUT);
    try std.testing.expectEqual(@as(u64, 2), results.part1);
    // try std.testing.expectEqual(@as(u64, 0), results.part2);
}

test "simple test 2" {
    const results = try part_1(TEST_INPUT_2);
    try std.testing.expectEqual(@as(u64, 6), results.part1);
}
test "simple test 3" {
    const results = try part_2(TEST_INPUT_3);
    try std.testing.expectEqual(@as(u64, 6), results.part2);
}
