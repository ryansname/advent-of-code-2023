const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day20.txt");

const ConjState = struct { node: usize, state: NodeState };
const NodeType = union(enum) {
    fork: void,
    flipflop: NodeState,
    conj: [10]ConjState,
};
const NodeState = enum {
    disconnected,
    low,
    high,

    fn invert(self: NodeState) NodeState {
        return switch (self) {
            .disconnected => .disconnected,
            .low => .high,
            .high => .low,
        };
    }
};
const Node = struct {
    outputs: []usize,
    state: NodeType,
};

pub fn main() !void {
    const result = try part1(INPUT, 1000);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}\n", .{result.part1});
    try stdout.print("Part 2: {}\n", .{result.part2});
}

fn labelToUsize(label: []const u8) usize {
    // Labels are upto three lower case letters or A or R
    if (mem.eql(u8, label, "broadcaster")) {
        return 26 * 26 * 26 + 1;
    }

    if (label.len > 3) {
        std.debug.panic("Label is too long: {s}", .{label});
    }
    const a: usize = 'a' - 1;
    var result: usize = switch (label.len) {
        1 => label[0] - a,
        2 => (label[1] - a) + ((label[0] - a) * 26),
        3 => (label[2] - a) + ((label[1] - a) * 26) + ((label[0] - a) * 26 * 26),
        else => std.debug.panic("Label is longer than expected: '{s}'", .{label}),
    };
    return result;
}
test labelToUsize {
    try std.testing.expectEqual(@as(usize, 1), labelToUsize("a"));
    try std.testing.expectEqual(@as(usize, 26), labelToUsize("z"));
    try std.testing.expectEqual(@as(usize, 26 + 1), labelToUsize("aa"));
    try std.testing.expectEqual(@as(usize, 26 + 26), labelToUsize("az"));
    try std.testing.expectEqual(@as(usize, 26 + 26 * 26), labelToUsize("zz"));
    try std.testing.expectEqual(@as(usize, 26 + 26 * 26 + 1), labelToUsize("aaa"));
}

const Pulse = struct {
    source: usize,
    destination: usize,
    signal: NodeState,
};
const PressButtonResult = struct { high: i64, low: i64, rx_low: i64 };
fn pressButton(nodes: []?Node) PressButtonResult {
    var result = PressButtonResult{ .high = 0, .low = 0, .rx_low = 0 };

    var pulses_buf: [1024]Pulse = undefined;
    var pulse_read_idx: usize = 0;
    var pulse_write_idx: usize = 0;

    pulses_buf[pulse_write_idx] = .{ .source = 0, .destination = labelToUsize("broadcaster"), .signal = .low };
    pulse_write_idx += 1;

    while (pulse_read_idx < pulse_write_idx) : (pulse_read_idx += 1) {
        const pulse = pulses_buf[pulse_read_idx];
        (if (pulse.signal == .low) result.low else result.high) += 1;

        if (pulse.signal == .low and pulse.destination == comptime labelToUsize("rx")) {
            result.rx_low += 1;
        }

        // std.debug.print("Applying {s} pulse from {} to {}\n", .{ @tagName(pulse.signal), pulse.source, pulse.destination });
        var signalled_node = &(nodes[pulse.destination] orelse continue);
        switch (signalled_node.state) {
            .fork => {
                for (signalled_node.outputs) |output| {
                    pulses_buf[pulse_write_idx] = .{ .source = pulse.destination, .destination = output, .signal = pulse.signal };
                    pulse_write_idx += 1;
                }
            },
            .flipflop => |*ff| {
                // std.debug.print("FF {} state: {} ", .{ pulse.destination, ff.* });
                // defer std.debug.print("becamse state: {}\n", .{ff.*});
                if (pulse.signal == .low) {
                    ff.* = ff.invert();
                    for (signalled_node.outputs) |output| {
                        pulses_buf[pulse_write_idx] = .{ .source = pulse.destination, .destination = output, .signal = ff.* };
                        pulse_write_idx += 1;
                    }
                }
            },
            .conj => |*conj| {
                var all_high = true;
                for (conj) |*c| {
                    if (c.state == .disconnected) break;
                    if (c.node == pulse.source) c.state = pulse.signal;
                    if (c.state != .high) all_high = false;
                    // std.debug.print("{c} ", .{@tagName(c.state)[0]});
                }
                // std.debug.print("\n", .{});
                const send_signal = if (all_high) NodeState.low else .high;
                for (signalled_node.outputs) |output| {
                    pulses_buf[pulse_write_idx] = .{ .source = pulse.destination, .destination = output, .signal = send_signal };
                    pulse_write_idx += 1;
                }
            },
        }
    }

    return result;
}

fn part1(comptime input: []const u8, presses: u64) !struct { part1: i64, part2: i64 } {
    var outputs_buf: [4096]usize = undefined;
    var output_idx: usize = 0;

    var nodes_buf: [labelToUsize("broadcaster") + 1]?Node = .{null} ** (labelToUsize("broadcaster") + 1);

    // var parts_buf: [1024]Part = undefined;
    // var parts_idx: usize = 0;

    var line_iter = aoc.iterLines(input);
    while (line_iter.next()) |line| {
        var line_part_iter = mem.tokenizeSequence(u8, line, " -> ");
        const source = line_part_iter.next().?;
        const outputs_raw = line_part_iter.next().?;

        const outputs_start_idx = output_idx;
        var outputs_iter = mem.tokenizeAny(u8, outputs_raw, " ,");
        while (outputs_iter.next()) |output_label| {
            // std.debug.print("output: {s}\n", .{output_label});
            outputs_buf[output_idx] = labelToUsize(output_label);
            output_idx += 1;
        }
        const outputs = outputs_buf[outputs_start_idx..output_idx];

        const node = .{
            .outputs = outputs,
            .state = switch (source[0]) {
                '%' => NodeType{ .flipflop = .low },
                '&' => NodeType{ .conj = [_]ConjState{.{ .node = 0, .state = .disconnected }} ** 10 },
                else => NodeType{ .fork = {} },
            },
        };
        if (node.state == .flipflop or node.state == .conj) {
            nodes_buf[labelToUsize(source[1..])] = node;
        } else {
            nodes_buf[labelToUsize(source)] = node;
        }
        // std.debug.print("{}\n", .{node});
    }
    const nodes = nodes_buf[0..];

    // Setup all the conj nodes inputs
    for (nodes, 0..) |node, node_idx| {
        if (node == null) continue;
        for (node.?.outputs) |output| {
            if (nodes[output] != null and nodes[output].?.state == .conj) {
                const conj = &nodes[output].?.state.conj;
                for (conj) |*c| {
                    if (c.state != .disconnected) continue;
                    c.node = node_idx;
                    c.state = .low;
                    break;
                } else {
                    std.debug.panic("Couldn't set all inputs to conjugate node!", .{});
                }
            }
        }
    }

    var result = PressButtonResult{ .low = 0, .high = 0, .rx_low = 0 };
    var part_2: i64 = 0;
    var press_count: i64 = 0;
    for (0..presses) |_| {
        const r = pressButton(nodes);
        press_count += 1;
        result.low += r.low;
        result.high += r.high;

        // Extraordinarily lucky
        if (r.rx_low == 1 and part_2 == 0) {
            part_2 = press_count;
        }
    }

    while (part_2 == 0) {
        const r = pressButton(nodes);
        press_count += 1;

        std.debug.print("gh {c} {c} {c} {c}\n", .{
            @tagName(nodes[labelToUsize("gh")].?.state.conj[0].state)[0],
            @tagName(nodes[labelToUsize("gh")].?.state.conj[1].state)[0],
            @tagName(nodes[labelToUsize("gh")].?.state.conj[2].state)[0],
            @tagName(nodes[labelToUsize("gh")].?.state.conj[3].state)[0],
        });

        if (r.rx_low != 0) {
            std.debug.print("rx was low {} times after {} presses\n", .{ r.rx_low, press_count });
        }
        if (r.rx_low == 1) {
            part_2 = press_count;
        }
    }

    var part_1: i64 = result.low * result.high;
    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\broadcaster -> a, b, c
    \\%a -> b
    \\%b -> c
    \\%c -> in
    \\&in -> a
;

const TEST_INPUT_2 =
    \\broadcaster -> a
    \\%a -> in, co
    \\&in -> b
    \\%b -> co
    \\&co -> ou
;

test "simple test input1" {
    {
        const result = try part1(TEST_INPUT_1, 1);
        try std.testing.expectEqual(@as(i64, 8 * 4), result.part1);
    }

    {
        const result = try part1(TEST_INPUT_1, 1000);
        try std.testing.expectEqual(@as(i64, 32000000), result.part1);
    }
}
test "simple test input2" {
    {
        const result = try part1(TEST_INPUT_2, 1000);
        try std.testing.expectEqual(@as(i64, 11687500), result.part1);
    }
}
