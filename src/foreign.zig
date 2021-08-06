const std = @import("std");
const data = @import("data.zig");
usingnamespace @import("wren.zig");

pub fn registerMethod(
    module:[]const u8,
    className:[]const u8,
    signature:[]const u8,
    isStatic:bool,
    ptr:ForeignMethodFn
) void {
    data.foreign_method_lookup.append(ForeignMethod{
        .module = module,
        .className = className,
        .signature = signature,
        .isStatic = isStatic,
        .ptr = ptr,
    }) catch unreachable;
}

pub fn findMethod (
    module:[]const u8,
    className:[]const u8,
    signature:[]const u8,
    isStatic:bool,
) !ForeignMethodFn {
    // TODO: Iterator vs direct array iteration?
    // TODO: Change this to some kind of hash-based structure, maybe hashmap of array lists
    //       keyed on something like a concatenation of the params?  Might have faster lookup
    //       if this is heavily loaded out, bench it at some point and see where the tipping
    //       point is.
    for(data.foreign_method_lookup.items) |item| {
        if(std.mem.eql(u8,item.module,module) and
           std.mem.eql(u8,item.className,className) and
           std.mem.eql(u8,item.signature,signature) and
           item.isStatic == isStatic) {
            return item.ptr;  
        }
    }
    return error.ForeignMethodNotFound;
}   

pub fn registerClass(
    module:[]const u8,
    className:[]const u8,
    allocate_fn:AllocateFnSig,
    finalize_fn:FinalizeFnSig,
) void {
    data.foreign_class_lookup.append(ForeignClass{
        .module = module,
        .className = className,
        .methods = ForeignClassMethods {
            .allocate = allocate_fn,
            .finalize = finalize_fn,
        }
    }) catch unreachable;
}     

pub fn findClass (
    module:[]const u8,
    className:[]const u8,
) !ForeignClassMethods {
    // TODO: Iterator vs direct array iteration?
    // TODO: See notes on findMethod above, same thing applies here.
    for(data.foreign_class_lookup.items) |item| {
        if(std.mem.eql(u8,item.module,module) and
            std.mem.eql(u8,item.className,className)) {
            return item.methods;  
        }
    }
    return error.ForeignClassNotFound;
} 
