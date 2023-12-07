// So I forgot to put the bid into my datastructure and didn't want to
// figure out how to make it track the sorting in the hands array.
// I just shoved the bid on the end of the hand and called it terrible.
// I was punished for my laziness in P2, because I forgot to trim the hand
// size back down, and changed the bid of some hands, in rare cases.

const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day07.txt");

pub fn main() !void {
    const result = try parts(INPUT);
    log.info("Part 1: {}", .{result.part1});

    std.debug.assert(result.part2 != 249819012);
    std.debug.assert(result.part2 > 249778079);
    log.info("Part 2: {}", .{result.part2});
}

const Hand = [6]u64;
const Category = enum(u8) {
    five = 6,
    four = 5,
    full = 4,
    three = 3,
    twotwo = 2,
    two = 1,
    one = 0,
};

fn categorise1(hand: Hand) Category {
    var counts = [_]u8{0} ** 14;
    for (hand[0..5]) |card| {
        counts[card] += 1;
    }

    var max_count: u8 = 0;
    var max_idx: usize = 0;
    for (counts, 0..) |c, idx| {
        max_count = @max(max_count, c);
        if (max_count == c) max_idx = idx;
    }

    var second_most: u8 = 0;
    for (counts, 0..) |c, idx| {
        if (idx == max_idx) continue;
        second_most = @max(second_most, c);
    }

    // log.err("For {any} was {} & {}", .{ hand, max_count, second_most });

    if (max_count == 5) return .five;
    if (max_count == 4) return .four;
    if (max_count == 3 and second_most == 2) return .full;
    if (max_count == 3) return .three;
    if (max_count == 2 and second_most == 2) return .twotwo;
    if (max_count == 2) return .two;
    return .one;
}

fn categorise2(hand: Hand) Category {
    var counts = [_]u8{0} ** 14;
    for (hand[0..5]) |card| {
        counts[card] += 1;
    }

    const jokers_count = counts[13];

    // Count best hand excluding jokers
    var max_count: u8 = 0;
    var max_idx: usize = 1;
    for (counts[0..13], 0..) |c, idx| {
        max_count = @max(max_count, c);
        if (max_count == c) max_idx = idx;
    }

    var second_most: u8 = 0;
    for (counts[0..13], 0..) |c, idx| {
        if (idx == max_idx) continue;
        second_most = @max(second_most, c);
    }

    // Add jokers to the max count to make it even better
    max_count += jokers_count;
    std.debug.assert(max_count + second_most <= 5);

    // log.err("For {any} was {} & {}", .{ hand, max_count, second_most });

    if (max_count == 5) return .five;
    if (max_count == 4) return .four;
    if (max_count == 3 and second_most == 2) return .full;
    if (max_count == 3) return .three;
    if (max_count == 2 and second_most == 2) return .twotwo;
    if (max_count == 2) return .two;
    return .one;
}

fn handCompareP1(_: void, h1: Hand, h2: Hand) bool {
    const cat_1 = categorise1(h1);
    const cat_2 = categorise1(h2);

    if (cat_1 == cat_2) {
        for (0..5) |i| {
            const card_1 = h1[i];
            const card_2 = h2[i];

            if (card_1 == card_2) continue;
            return card_1 > card_2;
        }
        return false;
    } else {
        return @intFromEnum(cat_1) < @intFromEnum(cat_2);
    }
}

fn handCompareP2(_: void, h1: Hand, h2: Hand) bool {
    const cat_1 = categorise2(h1);
    const cat_2 = categorise2(h2);

    if (cat_1 == cat_2) {
        for (0..5) |i| {
            const card_1 = h1[i];
            const card_2 = h2[i];

            if (card_1 == card_2) continue;
            return card_1 > card_2;
        }
        return false;
    } else {
        return @intFromEnum(cat_1) < @intFromEnum(cat_2);
    }
}

fn parts(input: []const u8) !struct { part1: u64, part2: u64 } {
    const replace = .{
        .{ .f = 'A', .t = 0 },
        .{ .f = 'K', .t = 1 },
        .{ .f = 'Q', .t = 2 },
        .{ .f = 'J', .t = 3 },
        .{ .f = 'T', .t = 4 },
        .{ .f = '9', .t = 5 },
        .{ .f = '8', .t = 6 },
        .{ .f = '7', .t = 7 },
        .{ .f = '6', .t = 8 },
        .{ .f = '5', .t = 9 },
        .{ .f = '4', .t = 10 },
        .{ .f = '3', .t = 11 },
        .{ .f = '2', .t = 12 },
        .{ .f = 'j', .t = 13 }, // Joker
    };
    var hands_buf = [_]Hand{.{ 0, 0, 0, 0, 0, 0 }} ** 1000;
    var hand_idx: usize = 0;

    var lines = mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        for (0..5) |i| {
            hands_buf[hand_idx][i] = @as(u64, line[i]);
        }
        // @memcpy(hands_buf[hand_idx][0..5], line[0..5]);
        hands_buf[hand_idx][5] = try fmt.parseInt(u32, line[6..], 10);
        // bids_buf[hand_idx] = try fmt.parseInt(u32, line[6..], 10);

        for (hands_buf[hand_idx][0..5]) |*c| {
            inline for (replace) |r| {
                if (c.* == r.f) c.* = r.t;
            }
        }
        hand_idx += 1;
    }
    var hands = hands_buf[0..hand_idx];

    mem.sort(Hand, hands, {}, handCompareP1);

    var part_1: u64 = 0;
    for (hands, 1..) |hand, rank| {
        // log.err("{any} {} {}", .{ hand[0..5], hand[5], rank });
        part_1 += hand[5] * rank;
    }

    // Mutilate a little bit
    comptime {
        if (replace.@"3".f != 'J' or replace.@"13".f != 'j') @compileError("Out of date replacements");
    }
    for (hands) |*hand| for (hand[0..5]) |*card| {
        if (card.* == replace.@"3".t) card.* = replace.@"13".t;
    };
    mem.sort(Hand, hands, {}, handCompareP2);

    var part_2: u64 = 0;
    for (hands, 1..) |hand, rank| {
        // log.err("{any} {} {}", .{ hand[0..5], hand[5], rank });
        part_2 += hand[5] * rank;

        var hand_out = [5]u8{ 0, 0, 0, 0, 0 };
        for (hand[0..5], 0..) |card, i| {
            inline for (replace) |r| {
                if (card == r.t) hand_out[i] = r.f;
            }
        }
        // log.err("{s} {}", .{ hand_out, categorise2(hand) });
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
    \\
;

test "simple test" {
    const results = try parts(TEST_INPUT);
    try std.testing.expectEqual(@as(u64, 6440), results.part1);
    try std.testing.expectEqual(@as(u64, 5905), results.part2);
}

test "custom_test 1" {
    const results = try parts(
        \\JJJJJ 1
        \\QQQQQ 3
    );
    try std.testing.expectEqual(@as(u64, 7), results.part2);
}
test "custom_test 2" {
    const results = try parts(
        \\JJJJQ 1
        \\QQQQQ 3
    );
    try std.testing.expectEqual(@as(u64, 7), results.part2);
}
test "custom_test 3" {
    const results = try parts(
        \\QJJJJ 1
        \\JQJQJ 2
        \\QQQQQ 3
    );
    try std.testing.expectEqual(@as(u64, 1 * 2 + 2 * 1 + 3 * 3), results.part2);
}
