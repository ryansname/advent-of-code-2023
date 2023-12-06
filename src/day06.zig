const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

pub fn main() !void {
    const part_1 = parts(.{
        .{ .t = 61, .d = 430 },
        .{ .t = 67, .d = 1036 },
        .{ .t = 75, .d = 1307 },
        .{ .t = 71, .d = 1150 },
    });
    const part_2 = parts(.{
        .{ .t = 61677571, .d = 430103613071150 },
    });
    log.info("Part 1: {}", .{part_1});
    log.info("Part 2: {}", .{part_2});
}

fn parts(input: anytype) u64 {
    var result: u64 = 1;

    inline for (input) |race| {
        var perms: u64 = 0;
        for (0..race.t) |t| {
            const distance = (race.t - t) * t;

            if (distance > race.d) {
                perms += 1;
            }
        }
        result *= perms;
    }

    return result;
}

test "simple test" {
    const part_1 = parts(.{
        .{ .t = 7, .d = 9 },
        .{ .t = 15, .d = 40 },
        .{ .t = 30, .d = 200 },
    });
    const part_2 = parts(.{
        .{ .t = 71530, .d = 940200 },
    });
    try std.testing.expectEqual(@as(u64, 288), part_1);
    try std.testing.expectEqual(@as(u64, 71503), part_2);
}
