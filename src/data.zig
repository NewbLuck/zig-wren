const std = @import("std");
usingnamespace @import("wren.zig");
const HashedArrayList = @import("libs/hashed_array_list.zig").HashedArrayList;

pub var allocator:*std.mem.Allocator = undefined;

//pub var foreign_method_lookup:std.ArrayList(ForeignMethod) = undefined;
//pub var foreign_class_lookup:std.ArrayList(ForeignClass) = undefined;
pub var method_lookup:HashedArrayList(usize,ForeignMethod) = undefined;
pub var class_lookup:HashedArrayList(usize,ForeignClass) = undefined;
