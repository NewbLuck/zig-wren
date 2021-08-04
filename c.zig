pub const struct_WrenVM = opaque {};
pub const WrenVM = struct_WrenVM;
pub const struct_WrenHandle = opaque {};
pub const WrenHandle = struct_WrenHandle;
pub const WrenReallocateFn = ?fn (?*c_void, usize, ?*c_void) callconv(.C) ?*c_void;
pub const WrenForeignMethodFn = ?fn (?*WrenVM) callconv(.C) void;
pub const WrenFinalizerFn = ?fn (?*c_void) callconv(.C) void;
pub const WrenResolveModuleFn = ?fn (?*WrenVM, [*c]const u8, [*c]const u8) callconv(.C) [*c]const u8;
pub const WrenLoadModuleCompleteFn = ?fn (?*WrenVM, [*c]const u8, struct_WrenLoadModuleResult) callconv(.C) void;
pub const struct_WrenLoadModuleResult = extern struct {
    source: [*c]const u8,
    onComplete: WrenLoadModuleCompleteFn,
    userData: ?*c_void,
};
pub const WrenLoadModuleResult = struct_WrenLoadModuleResult;
pub const WrenLoadModuleFn = ?fn (?*WrenVM, [*c]const u8) callconv(.C) WrenLoadModuleResult;
pub const WrenBindForeignMethodFn = ?fn (?*WrenVM, [*c]const u8, [*c]const u8, bool, [*c]const u8) callconv(.C) WrenForeignMethodFn;
pub const WrenWriteFn = ?fn (?*WrenVM, [*c]const u8) callconv(.C) void;
pub const WREN_ERROR_COMPILE: c_int = 0;
pub const WREN_ERROR_RUNTIME: c_int = 1;
pub const WREN_ERROR_STACK_TRACE: c_int = 2;
pub const WrenErrorType = c_uint;
pub const WrenErrorFn = ?fn (?*WrenVM, WrenErrorType, [*c]const u8, c_int, [*c]const u8) callconv(.C) void;
pub const WrenForeignClassMethods = extern struct {
    allocate: WrenForeignMethodFn,
    finalize: WrenFinalizerFn,
};
pub const WrenBindForeignClassFn = ?fn (?*WrenVM, [*c]const u8, [*c]const u8) callconv(.C) WrenForeignClassMethods;
pub const WrenConfiguration = extern struct {
    reallocateFn: WrenReallocateFn,
    resolveModuleFn: WrenResolveModuleFn,
    loadModuleFn: WrenLoadModuleFn,
    bindForeignMethodFn: WrenBindForeignMethodFn,
    bindForeignClassFn: WrenBindForeignClassFn,
    writeFn: WrenWriteFn,
    errorFn: WrenErrorFn,
    initialHeapSize: usize,
    minHeapSize: usize,
    heapGrowthPercent: c_int,
    userData: ?*c_void,
};
pub const WREN_RESULT_SUCCESS: c_int = 0;
pub const WREN_RESULT_COMPILE_ERROR: c_int = 1;
pub const WREN_RESULT_RUNTIME_ERROR: c_int = 2;
pub const WrenInterpretResult = c_uint;
pub const WREN_TYPE_BOOL: c_int = 0;
pub const WREN_TYPE_NUM: c_int = 1;
pub const WREN_TYPE_FOREIGN: c_int = 2;
pub const WREN_TYPE_LIST: c_int = 3;
pub const WREN_TYPE_MAP: c_int = 4;
pub const WREN_TYPE_NULL: c_int = 5;
pub const WREN_TYPE_STRING: c_int = 6;
pub const WREN_TYPE_UNKNOWN: c_int = 7;
pub const WrenType = c_uint;

// Extern fns in externs.zig

pub const WREN_VERSION_MAJOR = @as(c_int, 0);
pub const WREN_VERSION_MINOR = @as(c_int, 4);
pub const WREN_VERSION_PATCH = @as(c_int, 0);
pub const WREN_VERSION_STRING = "0.4.0";
pub const WREN_VERSION_NUMBER = ((WREN_VERSION_MAJOR * @import("std").zig.c_translation.promoteIntLiteral(c_int, 1000000, .decimal)) + (WREN_VERSION_MINOR * @as(c_int, 1000))) + WREN_VERSION_PATCH;
