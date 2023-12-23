const aoc = @import("util.zig");
const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

const INPUT = @embedFile("inputs/day22.txt");

pub fn main() !void {
    const result = try part1(INPUT);

    if (result.part2 <= 1955) {
        @panic("Part 2 not big enough");
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {}\n", .{result.part1});
    try stdout.print("Part 2: {}\n", .{result.part2});
}

const V3 = struct {
    x: i64,
    y: i64,
    z: i64,
};
const Cell = struct {
    pos: V3,
    block_id: usize,
};
const Block = struct {
    cells: []Cell,
    id: usize,
    moved_this_tick: bool,
};

fn applyGravity(blocks: []Block, all_cells: []const Cell) i64 {
    for (blocks) |*b| b.moved_this_tick = false;

    var moved: i64 = 0;
    var moved_this_cycle: i64 = 1;
    // Part 2 needs a complete single tick
    while (moved_this_cycle != 0) {
        moved_this_cycle = 0;
        // Try and move each block that hasn't moved yet
        for (blocks) |*block| {
            if (block.moved_this_tick) continue;

            // Look for a block that has room to drop
            can_drop: for (block.cells) |block_cell| {
                const check_pos = V3{ .x = block_cell.pos.x, .y = block_cell.pos.y, .z = block_cell.pos.z - 1 };
                if (check_pos.z < 1) break :can_drop;

                // I guess this is n^3 worst cast....
                // I could presort the blocks to maybe avoid it
                for (all_cells) |match_cell| {
                    if (match_cell.block_id == block.id) continue;
                    if (std.meta.eql(check_pos, match_cell.pos)) break :can_drop;
                }
            } else {
                moved += 1;
                moved_this_cycle += 1;
                block.moved_this_tick = true;
                for (block.cells) |*cell| {
                    cell.pos.z -= 1;
                }
            }
        }
    }
    return moved;
}

fn part1(comptime input: []const u8) !struct { part1: i64, part2: i64 } {
    var cell_buf: [10240]Cell = undefined;
    var cell_buf_idx: usize = 0;

    var block_buf: [2048]Block = undefined;
    var block_buf_idx: usize = 0;

    var line_iter = aoc.iterLines(input);
    while (line_iter.next()) |line| {
        var token_iter = mem.tokenizeAny(u8, line, ",~");
        const x1 = try fmt.parseInt(usize, token_iter.next().?, 10);
        const y1 = try fmt.parseInt(usize, token_iter.next().?, 10);
        const z1 = try fmt.parseInt(usize, token_iter.next().?, 10);
        const x2 = try fmt.parseInt(usize, token_iter.next().?, 10);
        const y2 = try fmt.parseInt(usize, token_iter.next().?, 10);
        const z2 = try fmt.parseInt(usize, token_iter.next().?, 10);

        const cell_start_idx = cell_buf_idx;
        for (x1..x2 + 1) |x| for (y1..y2 + 1) |y| for (z1..z2 + 1) |z| {
            cell_buf[cell_buf_idx] = .{
                .pos = .{
                    .x = @intCast(x),
                    .y = @intCast(y),
                    .z = @intCast(z),
                },
                .block_id = block_buf_idx,
            };
            cell_buf_idx += 1;
        };
        block_buf[block_buf_idx] = .{
            .cells = cell_buf[cell_start_idx..cell_buf_idx],
            .id = block_buf_idx,
            .moved_this_tick = false,
        };
        block_buf_idx += 1;
    }
    const blocks = block_buf[0..block_buf_idx];
    const cells = cell_buf[0..cell_buf_idx];

    while (true) {
        const blocks_moved = applyGravity(blocks, cells);
        if (blocks_moved == 0) break;
    }

    var settled_cell_template_buf: [cell_buf.len]Cell = undefined;
    var settled_cell_template = settled_cell_template_buf[0..cells.len];
    @memcpy(settled_cell_template, cells);

    var part_1: i64 = 0;
    var part_2: i64 = 0;
    for (blocks) |block| {
        // To pretend disintegrate it, lets just move the block underground
        @memcpy(cells, settled_cell_template);
        for (block.cells) |*cell| cell.pos.z = -100;

        const blocks_moved = applyGravity(blocks, cells);
        if (blocks_moved == 0) part_1 += 1;
        part_2 += blocks_moved;
    }

    return .{ .part1 = part_1, .part2 = part_2 };
}

const TEST_INPUT_1 =
    \\1,0,1~1,2,1
    \\0,0,2~2,0,2
    \\0,2,3~2,2,3
    \\0,0,4~0,2,4
    \\2,0,5~2,2,5
    \\0,1,6~2,1,6
    \\1,1,8~1,1,9
;

test "simple test input1" {
    {
        const result = try part1(TEST_INPUT_1);
        try std.testing.expectEqual(@as(i64, 5), result.part1);
    }

    {
        const result = try part1(TEST_INPUT_1);
        try std.testing.expectEqual(@as(i64, 7), result.part2);
    }
}
