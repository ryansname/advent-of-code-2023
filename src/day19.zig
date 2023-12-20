const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day19.txt");

pub fn main() !void {
    const result = try part1(INPUT);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}\n", .{result.part1});
    try stdout.print("Part 2: {}\n", .{result.part2});
}

const Category = enum { x, m, a, s };
const Instruction = struct {
    category: Category,
    comparison: std.math.Order,
    value: i64,
    target: usize,
};
const Workflow = struct {
    instructions: []const Instruction,
    fallback: usize,
};
const Part = struct {
    x: i64,
    m: i64,
    a: i64,
    s: i64,

    fn set(self: *Part, category: Category, value_to_set: i64) void {
        return switch (category) {
            inline else => |c| @field(self, @tagName(c)) = value_to_set,
        };
    }

    fn value(self: Part, category: Category) i64 {
        return switch (category) {
            inline else => |c| @field(self, @tagName(c)),
        };
    }
};

fn labelToUsize(label: []const u8) usize {
    std.debug.assert(label.len <= 3);
    // Labels are upto three lower case letters or A or R
    if (label[0] == 'A') {
        return 26 * 26 * 26 + 1;
    } else if (label[0] == 'R') {
        return 26 * 26 * 26 + 2;
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

fn isValid(workflows: []const Workflow, part: Part, current_workflow: usize) bool {
    if (current_workflow == comptime labelToUsize("A")) return true;
    if (current_workflow == comptime labelToUsize("R")) return false;

    const workflow = workflows[current_workflow];

    for (workflow.instructions) |instruction| {
        const value = part.value(instruction.category);
        if (std.math.order(value, instruction.value) == instruction.comparison) {
            return isValid(workflows, part, instruction.target);
        }
    }
    return isValid(workflows, part, workflow.fallback);
}

fn part1(comptime input: []const u8) !struct { part1: i64, part2: i64 } {
    var instructions_buf: [4096]Instruction = undefined;
    var instruction_idx: usize = 0;

    var workflows_buf: [labelToUsize("zzz") + 2]Workflow = undefined;

    var parts_buf: [1024]Part = undefined;
    var parts_idx: usize = 0;

    var line_iter = aoc.iterLines(input);
    while (line_iter.next()) |line| {
        if (line[0] == '{') {
            // parts
            var values_iter = mem.tokenizeAny(u8, line, "{=,}xmas");
            parts_buf[parts_idx] = .{
                .x = try fmt.parseInt(i64, values_iter.next().?, 10),
                .m = try fmt.parseInt(i64, values_iter.next().?, 10),
                .a = try fmt.parseInt(i64, values_iter.next().?, 10),
                .s = try fmt.parseInt(i64, values_iter.next().?, 10),
            };
            parts_idx += 1;
        } else {
            const instruction_sep_idx = std.mem.indexOfScalar(u8, line, '{').?;
            const workflow_label = line[0..instruction_sep_idx];
            const instructions_str = line[instruction_sep_idx + 1 .. line.len - 1];

            const instructions_start_idx = instruction_idx;
            var instruction_iter = aoc.iterCsv(instructions_str);
            const fallback = while (instruction_iter.next()) |instruction_str| {
                const value_idx = std.mem.indexOfScalar(u8, instruction_str, ':') orelse break instruction_str;

                const category = std.meta.stringToEnum(Category, instruction_str[0..1]).?;
                const comparison: math.Order = switch (instruction_str[1]) {
                    '>' => .gt,
                    '<' => .lt,
                    else => std.debug.panic("Unsupported comparison {c}", .{instruction_str[1]}),
                };
                const value = try fmt.parseInt(i64, instruction_str[2..value_idx], 10);
                const target = labelToUsize(instruction_str[value_idx + 1 ..]);

                instructions_buf[instruction_idx] = .{
                    .category = category,
                    .comparison = comparison,
                    .value = value,
                    .target = target,
                };
                instruction_idx += 1;
            } else std.debug.panic("Did not find a fallback instruction in '{s}'!", .{line});

            const workflow = .{
                .instructions = instructions_buf[instructions_start_idx..instruction_idx],
                .fallback = labelToUsize(fallback),
            };
            workflows_buf[labelToUsize(workflow_label)] = workflow;
        }
    }
    const workflows = workflows_buf[0..];
    const parts = parts_buf[0..parts_idx];

    // for (workflows) |workflow| {
    //     std.debug.print("{s} -", .{workflow.label});
    //     for (workflow.instructions) |instruction| {
    //         std.debug.print(" {s}{c}{}:{s}", .{
    //             @tagName(instruction.category),
    //             @as(u8, if (instruction.comparison == .gt) '>' else '<'),
    //             instruction.value,
    //             instruction.target,
    //         });
    //     }
    //     std.debug.print(" : {s}\n", .{workflow.fallback});
    // }
    // for (parts) |part| {
    //     std.debug.print("x={}, m={}, a={}, s={}\n", part);
    // }

    var part_1: i64 = 0;
    for (parts) |part| {
        if (isValid(workflows, part, labelToUsize("in"))) {
            for (std.enums.values(Category)) |cat| part_1 += part.value(cat);
        }
    }

    var part_2: i64 = part2(workflows);
    return .{ .part1 = part_1, .part2 = part_2 };
}

fn countPossibilities(min: Part, max: Part) i64 {
    var count: i64 = 1;
    for (std.enums.values(Category)) |cat| count *= max.value(cat) - min.value(cat);
    return count;
}
test countPossibilities {
    const min = Part{ .x = 1, .m = 1, .a = 1, .s = 1 };
    const max = Part{ .x = 4001, .m = 4001, .a = 4001, .s = 4001 };
    try std.testing.expectEqual(@as(i64, 4000 * 4000 * 4000 * 4000), countPossibilities(min, max));
}

const CountOutcomesResult = struct { accept_count: i64, total: i64 };
fn countOutcomes(workflows: []Workflow, min: Part, max: Part, current_workflow: usize) CountOutcomesResult {
    inline for (.{ labelToUsize("A"), labelToUsize("R") }) |leaf_workflow| {
        if (current_workflow == leaf_workflow) {
            var count = countPossibilities(min, max);
            if (current_workflow == comptime labelToUsize("A")) {
                return .{ .accept_count = count, .total = count };
            } else if (current_workflow == comptime labelToUsize("R")) {
                return .{ .accept_count = 0, .total = count };
            }
        }
    }

    const workflow = workflows[current_workflow];

    var combined_min = min;
    var combined_max = max;

    var count_before = countPossibilities(min, max);

    var outcomes: CountOutcomesResult = .{ .accept_count = 0, .total = 0 };
    for (workflow.instructions) |instruction| {
        const threshold = instruction.value;
        const category = instruction.category;
        switch (instruction.comparison) {
            .lt => {
                var new_max = combined_max;
                new_max.set(category, @min(combined_max.value(category), threshold));

                const matching_count = countOutcomes(workflows, combined_min, new_max, instruction.target);
                outcomes.accept_count += matching_count.accept_count;
                outcomes.total += matching_count.total;

                // std.debug.print("{} on {} {}\n", .{ instruction, combined_min, combined_max });
                // std.debug.print("{} {}\n", .{ combined_min, new_max });

                combined_min.set(category, @max(combined_min.value(category), instruction.value));

                // std.debug.print("becomes\n", .{});
                // std.debug.print("{} {}\n", .{ combined_min, combined_max });
            },
            .gt => {
                var new_min = combined_min;
                new_min.set(category, @max(combined_min.value(category), threshold + 1));

                const matching_count = countOutcomes(workflows, new_min, combined_max, instruction.target);
                outcomes.accept_count += matching_count.accept_count;
                outcomes.total += matching_count.total;

                // std.debug.print("{} on {} {}\n", .{ instruction, combined_min, combined_max });
                // std.debug.print("{} {}\n", .{ new_min, combined_max });

                combined_max.set(category, @min(combined_max.value(category), instruction.value + 1));

                // std.debug.print("becomes\n", .{});
                // std.debug.print("{} {}\n", .{ combined_min, combined_max });
            },
            else => unreachable,
        }
        // std.debug.print("\n", .{});
    }

    // And the fallback
    const matching_count = countOutcomes(workflows, combined_min, combined_max, workflow.fallback);
    outcomes.accept_count += matching_count.accept_count;
    outcomes.total += matching_count.total;

    if (outcomes.total != count_before) {
        log.err("Not all possiblities accounted for, before forking: {}, after forking: {}", .{ count_before, outcomes.total });
    }

    return outcomes;
}

fn part2(workflows: []Workflow) i64 {
    const min = Part{ .x = 1, .m = 1, .a = 1, .s = 1 };
    const max = Part{ .x = 4001, .m = 4001, .a = 4001, .s = 4001 };

    const outcomes = countOutcomes(workflows, min, max, labelToUsize("in"));
    const expected_total = 4000 * 4000 * 4000 * 4000;
    if (outcomes.total != expected_total) {
        log.err("Outcome total was unexpected, got {}, expected {}", .{ outcomes.total, expected_total });
    }

    return outcomes.accept_count;
}

const TEST_INPUT_1 =
    \\px{a<2006:qkq,m>2090:A,rfg}
    \\pv{a>1716:R,A}
    \\lnx{m>1548:A,A}
    \\rfg{s<537:gd,x>2440:R,A}
    \\qs{s>3448:A,lnx}
    \\qkq{x<1416:A,crn}
    \\crn{x>2662:A,R}
    \\in{s<1351:px,qqz}
    \\qqz{s>2770:qs,m<1801:hdj,R}
    \\gd{a>3333:R,R}
    \\hdj{m>838:A,pv}
    \\
    \\{x=787,m=2655,a=1222,s=2876}
    \\{x=1679,m=44,a=2067,s=496}
    \\{x=2036,m=264,a=79,s=2244}
    \\{x=2461,m=1339,a=466,s=291}
    \\{x=2127,m=1623,a=2188,s=1013}
;

test "simple test part1" {
    const result = try part1(TEST_INPUT_1);
    try std.testing.expectEqual(@as(i64, 19114), result.part1);
    try std.testing.expectEqual(@as(i64, 167409079868000), result.part2);
}
