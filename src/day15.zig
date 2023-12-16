const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day15.txt");

pub fn main() !void {
    const result = try part1(INPUT);

    log.info("Part 1: {}", .{result.part1});
    log.info("Part 2: {}", .{result.part2});
}

fn hash(input: []const u8) i64 {
    var result: i64 = 0;
    for (input) |char| {
        result += char;
        result *= 17;
        result = @mod(result, 256);
    }
    return result;
}

const LabelledLens = struct {
    label: []const u8,
    lens: u8,
};
const LensBox = [10]?LabelledLens;

fn hashmap(input: []const u8) i64 {
    var boxes: [256]LensBox = [_]LensBox{.{null} ** 10} ** 256;
    var instruction_iter = aoc.iterCsv(input);
    while (instruction_iter.next()) |instruction| {
        var decoder = mem.tokenizeAny(u8, instruction, "=-");
        const label = decoder.next().?;
        const operation = instruction[decoder.index];
        const lens = if (decoder.next()) |l| l[0] - '0' else null;

        var box_idx = hash(label);
        var box = &boxes[@intCast(box_idx)];
        // std.debug.print("label: '{s}', box: {}, instruction: '{c}', lens: {any}\n", .{ label, box_idx, operation, lens });

        if (operation == '-') {
            const idx: usize = blk: for (box, 0..) |ll, idx| {
                if (ll != null and mem.eql(u8, ll.?.label, label)) break :blk idx;
            } else continue;

            for (box[idx .. box.len - 1], box[idx + 1 ..]) |*l, *h| {
                l.* = h.*;
            }
            box[box.len - 1] = null;
        } else if (operation == '=') {
            for (box) |*ll| {
                if (ll.* == null) {
                    ll.* = .{ .label = label, .lens = lens.? };
                    break;
                } else if (mem.eql(u8, ll.*.?.label, label)) {
                    ll.*.?.lens = lens.?;
                    break;
                }
            }
        } else {
            std.debug.panic("Unsupported operation: {c}", .{operation});
        }
    }

    var result: i64 = 0;
    for (boxes, 1..) |box, box_num| {
        for (box, 1..) |labelled_lens, slot_num| {
            if (labelled_lens) |ll| {
                const lens_contrib: i64 = @intCast(box_num * slot_num * ll.lens);
                // std.debug.print("Box {}, Lens: {}, FL: {}\n", .{ box_num, slot_num, ll.lens });
                result += lens_contrib;
            }
        }
    }

    return result;
}

fn part1(input: []const u8) !struct { part1: i64, part2: i64 } {
    var part_1: i64 = 0;
    var instruction_iter = aoc.iterCsv(input);
    while (instruction_iter.next()) |instruction| {
        part_1 += hash(instruction);
    }

    var part_2: i64 = hashmap(input);
    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";

test hash {
    try std.testing.expectEqual(@as(i64, 52), hash("HASH"));
}

test "simple test part1" {
    const result = try part1(TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 1320), result.part1);
    try std.testing.expectEqual(@as(i64, 145), result.part2);
}
