const ascii = std.ascii;
const fmt = std.fmt;
const log = std.log;
const math = std.math;
const mem = std.mem;
const std = @import("std");

pub fn iterLines(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, '\n');
}

pub fn iterTokens(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, ' ');
}

pub fn iterCsv(string: []const u8) mem.TokenIterator(u8, .scalar) {
    return mem.tokenizeScalar(u8, string, ',');
}

// 2D stuff
pub fn Dir(comptime dirs: u8) type {
    return switch (dirs) {
        4 => enum { N, S, E, W },
        8 => enum { N, S, E, W, NE, SE, NW, SW },
        else => @compileError("Unsupported number of dirs " ++ dirs),
    };
}

pub fn indexForDir(dir: Dir(4), idx: usize, stride: usize) usize {
    if (@TypeOf(dir) == Dir(4)) {
        return switch (dir) {
            .N => idx - stride,
            .S => idx + stride,
            .W => idx - 1,
            .E => idx + 1,
        };
    } else {
        @compileError("Unsupported type " ++ @typeName(@TypeOf(dir)));
    }
}

pub fn NeighboursReturn(comptime dirs: u8, comptime BufferType: type) type {
    return [dirs]struct { char: @typeInfo(BufferType).Pointer.child, idx: usize, dir: Dir(dirs) };
}

pub fn getNeighbours(comptime dirs: u8, buffer: anytype, i: usize, stride: usize) NeighboursReturn(dirs, @TypeOf(buffer)) {
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
