const std = @import("std");
usingnamespace @import("wren.zig");

pub var allocator:*std.mem.Allocator = undefined;
pub var foreign_method_lookup:std.ArrayList(ForeignMethod) = undefined;
pub var foreign_class_lookup:std.ArrayList(ForeignClass) = undefined;

