const std = @import("std");
const data = @import("data.zig");
usingnamespace @import("wren.zig");
const HashedArrayList = @import("libs/hashed_array_list.zig").HashedArrayList;

pub fn registerMethod(
    vm:?*VM,
    module:[]const u8,
    className:[]const u8,
    signature:[]const u8,
    isStatic:bool,
    ptr:ForeignMethodFn
) !void {
    if(vm) |vm_ptr| {
        data.method_lookup.append(@ptrToInt(vm_ptr),ForeignMethod {
            .module = module,
            .className = className,
            .signature = signature,
            .isStatic = isStatic,
            .ptr = ptr,
        }) catch return error.FailedToRegisterMethod;
    } else return error.NullVmPtr;
}

pub fn findMethod (
    vm:?*VM,
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
    if(vm) |vm_ptr| {
        if(data.method_lookup.getKey(@ptrToInt(vm_ptr))) |a_list| {
            for(a_list.items) |item| {
                if(std.mem.eql(u8,item.module,module) and
                std.mem.eql(u8,item.className,className) and
                std.mem.eql(u8,item.signature,signature) and
                item.isStatic == isStatic) {
                    return item.ptr;  
                }
            }
        } else return error.InvalidVm;
        return error.ForeignMethodNotFound;
    } else return error.NullVmPointer;
}   

pub fn registerClass(
    vm:?*VM,
    module:[]const u8,
    className:[]const u8,
    allocate_fn:AllocateFnSig,
    finalize_fn:FinalizeFnSig,
) !void {
    if(vm) |vm_ptr| {
        data.class_lookup.append(@ptrToInt(vm_ptr),ForeignClass{
            .module = module,
            .className = className,
            .methods = ForeignClassMethods {
                .allocate = allocate_fn,
                .finalize = finalize_fn,
            }
        }) catch return error.FailedToRegisterClass;
    } else return error.NullVmPtr;

}     

pub fn findClass (
    vm:?*VM,
    module:[]const u8,
    className:[]const u8,
) !ForeignClassMethods {
    // TODO: Iterator vs direct array iteration?
    // TODO: See notes on findMethod above, same thing applies here.
    if(vm) |vm_ptr| {
        if(data.class_lookup.getKey(@ptrToInt(vm_ptr))) |a_list| {
            for(a_list.items) |item| {
                if(std.mem.eql(u8,item.module,module) and
                   std.mem.eql(u8,item.className,className)) {
                    return item.methods;  
                }
            }
            return error.ForeignClassNotFound;
        } else return error.InvalidVm;
    } else return error.NullVmPointer;
} 
