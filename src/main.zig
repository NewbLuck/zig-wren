const std = @import("std");
const wren = @import("wren");

pub fn main() !void {
    std.log.info("{s}", .{wren.VERSION_STRING});

    refAllDecls(wren);
}

pub fn refAllDecls(comptime T: type) void {
    inline for (std.meta.declarations(T)) |decl| {
        _ = decl;
    }
}
