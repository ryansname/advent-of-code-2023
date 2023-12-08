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

const Card = enum(u8) {
    joker,
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",
    T,
    J,
    Q,
    K,
    A,
};

const Hand = [5]Card;
const HandAndBid = struct {
    hand: Hand,
    bid: u64,
};
const Category = enum(u8) {
    five = 6,
    four = 5,
    threetwo = 4,
    three = 3,
    twotwo = 2,
    two = 1,
    one = 0,
};

fn categorise1(hand: Hand) Category {
    var counts = [_]u8{0} ** std.enums.values(Card).len;
    for (hand) |card| {
        counts[@intFromEnum(card)] += 1;
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

    if (max_count == 5) return .five;
    if (max_count == 4) return .four;
    if (max_count == 3 and second_most == 2) return .threetwo;
    if (max_count == 3) return .three;
    if (max_count == 2 and second_most == 2) return .twotwo;
    if (max_count == 2) return .two;
    return .one;
}

fn categorise2(hand: Hand) Category {
    var counts = [_]u8{0} ** std.enums.values(Card).len;
    for (hand) |card| {
        counts[@intFromEnum(card)] += 1;
    }

    const jokers_count = counts[@intFromEnum(Card.joker)];

    // Count best hand excluding jokers
    var max_count: u8 = 0;
    var max_idx: usize = 0;
    for (counts, 0..) |c, idx| {
        if (idx == @intFromEnum(Card.joker)) continue;

        max_count = @max(max_count, c);
        if (max_count == c) max_idx = idx;
    }

    var second_most: u8 = 0;
    for (counts, 0..) |c, idx| {
        if (idx == @intFromEnum(Card.joker)) continue;
        if (idx == max_idx) continue;

        second_most = @max(second_most, c);
    }

    // Add jokers to the max count to make it even better
    max_count += jokers_count;
    std.debug.assert(max_count + second_most <= 5);

    if (max_count == 5) return .five;
    if (max_count == 4) return .four;
    if (max_count == 3 and second_most == 2) return .threetwo;
    if (max_count == 3) return .three;
    if (max_count == 2 and second_most == 2) return .twotwo;
    if (max_count == 2) return .two;
    return .one;
}

fn handCompareP1(_: void, h1: HandAndBid, h2: HandAndBid) bool {
    const cat_1 = categorise1(h1.hand);
    const cat_2 = categorise1(h2.hand);

    if (cat_1 == cat_2) {
        for (h1.hand, h2.hand) |card_1, card_2| {
            if (card_1 == card_2) continue;
            return @intFromEnum(card_1) < @intFromEnum(card_2);
        }
        return false;
    } else {
        return @intFromEnum(cat_1) < @intFromEnum(cat_2);
    }
}

fn handCompareP2(_: void, h1: HandAndBid, h2: HandAndBid) bool {
    const cat_1 = categorise2(h1.hand);
    const cat_2 = categorise2(h2.hand);

    if (cat_1 == cat_2) {
        for (h1.hand, h2.hand) |card_1, card_2| {
            if (card_1 == card_2) continue;
            return @intFromEnum(card_1) < @intFromEnum(card_2);
        }
        return false;
    } else {
        return @intFromEnum(cat_1) < @intFromEnum(cat_2);
    }
}

fn parts(input: []const u8) !struct { part1: u64, part2: u64 } {
    var hands_buf: [1000]HandAndBid = undefined;
    var hand_idx: usize = 0;

    var lines = mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        for (&hands_buf[hand_idx].hand, line[0..5]) |*card, char| {
            card.* = std.meta.stringToEnum(Card, &[_]u8{char}).?;
        }
        hands_buf[hand_idx].bid = try fmt.parseInt(u32, line[6..], 10);
        hand_idx += 1;
    }
    var hands = hands_buf[0..hand_idx];

    mem.sort(HandAndBid, hands, {}, handCompareP1);

    var part_1: u64 = 0;
    for (hands, 1..) |hand, rank| {
        part_1 += hand.bid * rank;
    }

    for (hands) |*hand| for (&hand.hand) |*card| {
        if (card.* == .J) card.* = .joker;
    };
    mem.sort(HandAndBid, hands, {}, handCompareP2);

    var part_2: u64 = 0;
    for (hands, 1..) |hand, rank| {
        part_2 += hand.bid * rank;
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
