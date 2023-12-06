const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

pub fn main() !void {
    const part_1, _ = try parts(undefined, .{
        .{ .t = 61, .d = 430 },
        .{ .t = 67, .d = 1036 },
        .{ .t = 75, .d = 1307 },
        .{ .t = 71, .d = 1150 },
    });
    const part_2, _ = try parts(undefined, .{
        .{ .t = 61677571, .d = 430103613071150 },
    });
    log.info("Part 1: {}", .{part_1});
    log.info("Part 2: {}", .{part_2});
}

fn parts(alloc: mem.Allocator, input: anytype) !struct { u64, u64 } {
    _ = alloc;

    var part_1: u64 = 1;
    var part_2: u64 = 0;

    inline for (input) |race| {
        var perms: u64 = 0;
        for (0..race.t) |t| {
            const distance = (race.t - t) * t;

            if (distance > race.d) {
                perms += 1;
            }
        }
        part_1 *= perms;
    }

    return .{ part_1, part_2 };
}

test "simple test" {
    var alloc = std.testing.allocator;
    const part_1, _ = try parts(alloc, .{
        .{ .t = 7, .d = 9 },
        .{ .t = 15, .d = 40 },
        .{ .t = 30, .d = 200 },
    });
    const part_2, _ = try parts(alloc, .{
        .{ .t = 71530, .d = 940200 },
    });
    try std.testing.expectEqual(@as(u64, 288), part_1);
    try std.testing.expectEqual(@as(u64, 71503), part_2);
}
