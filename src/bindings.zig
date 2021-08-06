const std = @import("std");
usingnamespace @import("wren.zig");
const data = @import("data.zig");

/// Should be bound to config.bindForeignMethodFn
pub fn foreignMethodFn(
    vm:?*VM,
    module:CString,
    className:CString,
    isStatic:bool,
    signature:CString
) callconv(.C) ForeignMethodFn {
    _=vm;
    return foreign.findMethod(
        std.mem.span(module),
        std.mem.span(className),
        std.mem.span(signature),
        isStatic
    ) catch unreachable;
}

/// Should be bound to config.bindForeignMethodFn
pub fn bindForeignClassFn (
    vm:?*VM, 
    module:CString, 
    className:CString
) callconv(.C) ForeignClassMethods {
    std.debug.print(" [+] Foreign start\n",.{});
    _=vm;
    //if (wren.util.matches(module, "main")) {
    //    if (wren.util.matches(className, "Point")) {
    //        std.debug.print(" [+] Foreign bind\n",.{});
    //        return .{
    //            .allocate = pointAllocate,
    //            .finalize = pointFinalize,
    //        };
    //    }
    //}
    return foreign.findClass(std.mem.span(module),std.mem.span(className)) catch |err| {
        std.debug.print(" [+] Foreign BIND FAIL - {s}\n",.{err});
        return .{
            .allocate = null,
            .finalize = null
        };
    };
}

/// Should be bound to config.loadModuleFn
pub fn loadModuleFn(vm:?*VM,name:CString) callconv(.C) LoadModuleResult {
    _=vm;
    var src = util.loadWrenSourceFile(data.allocator,std.mem.span(name)) catch unreachable;
    return .{
        .source = src,
        .onComplete = loadModuleCompleteFn,   // ?fn, called on done running to free mem
        .userData = null,                     // ?*c_void
    };
}

/// Should be bound to the callback of the loadModuleFn definition
pub fn loadModuleCompleteFn (vm:?*VM,module:CString,result:LoadModuleResult) callconv(.C) void {
    _=vm; 
    _=module;
    if(result.source != null) {
        var slice_len = std.mem.sliceTo(result.source,0).len;
        data.allocator.free(result.source[0..slice_len]);
    }
}

/// Should be bound to config.writeFn
pub fn writeFn(vm:?*VM, text:CString) callconv(.C) void {
    _=vm;
    std.debug.print("{s}",.{text});
}

/// Should be bound to config.errorFn
pub fn errorFn(vm:?*VM, err_type:ErrorType, module:CString, line:c_int, msg:CString) callconv(.C) void {
    _=vm;
    var err_desc = switch(err_type) {
        ERROR_COMPILE => "Compile Error",
        ERROR_RUNTIME => "Runtime Error",
        ERROR_STACK_TRACE => "Stack Trace",
        else => unreachable,
    };
    std.debug.print("{s} @ ",.{err_desc});
    if(module) |mod| {
        std.debug.print("{s}:{}\n",.{mod,line});
    } else std.debug.print("{s}:{}\n",.{"[null]",line});
    if(msg) |mg| {
        std.debug.print("  {s}\n",.{mg});
    } else std.debug.print("  {s}\n",.{"[null]"});
}
