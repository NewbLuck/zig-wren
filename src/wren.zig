// Private includes
const std = @import("std");
const c = @import("c.zig");
const ext = @import("externs.zig");
const data = @import("data.zig");
const HashedArrayList = @import("libs/hashed_array_list.zig").HashedArrayList;

// Public includes
/// Utilities to make life easier
pub const util = @import("util.zig");
/// A set of default bindings for the Wren configuration that provide basic functionality
pub const bindings = @import("bindings.zig");
pub const foreign = @import("foreign.zig");

// Convenience Signatures
pub const CString = [*c]const u8;
pub const MethodFnSig = (?fn (?*VM) callconv(.C) void);

// Version
pub const VERSION_MAJOR = c.WREN_VERSION_MAJOR;
pub const VERSION_MINOR = c.WREN_VERSION_MINOR;
pub const VERSION_PATCH = c.WREN_VERSION_PATCH;
pub const VERSION_STRING = c.WREN_VERSION_STRING;
pub const VERSION_NUMBER = c.WREN_VERSION_NUMBER;

// Types
pub const VM = c.WrenVM;
pub const Handle = c.WrenHandle;

pub const ReallocateFn = c.WrenReallocateFn;
pub const ForeignMethodFn = c.WrenForeignMethodFn;
pub const FinalizerFn = c.WrenFinalizerFn;
pub const ResolveModuleFn = c.WrenResolveModuleFn;
pub const LoadModuleCompleteFn = c.WrenLoadModuleCompleteFn;
pub const LoadModuleResult = c.WrenLoadModuleResult;
pub const LoadModuleFn = c.WrenLoadModuleFn;
pub const BindForeignMethodFn = c.WrenBindForeignMethodFn;

pub const WriteFn = c.WrenWriteFn;
pub const ErrorType = c.WrenErrorType;
pub const ErrorFn = c.WrenErrorFn;
pub const ForeignClassMethods = c.WrenForeignClassMethods;
pub const BindForeignClassFn = c.WrenBindForeignClassFn;
pub const Configuration = c.WrenConfiguration;
pub const InterpretResult = c.WrenInterpretResult;

pub const Type = c.WrenType;

// Kind-of-enums
pub const ERROR_COMPILE = c.WREN_ERROR_COMPILE;
pub const ERROR_RUNTIME = c.WREN_ERROR_RUNTIME;
pub const ERROR_STACK_TRACE = c.WREN_ERROR_STACK_TRACE;

pub const RESULT_SUCCESS = c.WREN_RESULT_SUCCESS;
pub const RESULT_COMPILE_ERROR = c.WREN_RESULT_COMPILE_ERROR;
pub const RESULT_RUNTIME_ERROR = c.WREN_RESULT_RUNTIME_ERROR;

pub const TYPE_BOOL = c.WREN_TYPE_BOOL;
pub const TYPE_NUM = c.WREN_TYPE_NUM;
pub const TYPE_FOREIGN = c.WREN_TYPE_FOREIGN;
pub const TYPE_LIST = c.WREN_TYPE_LIST;
pub const TYPE_MAP = c.WREN_TYPE_MAP;
pub const TYPE_NULL = c.WREN_TYPE_NULL;
pub const TYPE_STRING = c.WREN_TYPE_STRING;
pub const TYPE_UNKNOWN = c.WREN_TYPE_UNKNOWN;


// Common
pub const getVersionNumber = ext.wrenGetVersionNumber;
pub const initConfiguration = ext.wrenInitConfiguration;
pub const newVM = ext.wrenNewVM;
pub const freeVM = ext.wrenFreeVM;
pub const collectGarbage = ext.wrenCollectGarbage;
pub const interpret = ext.wrenInterpret;
pub const makeCallHandle = ext.wrenMakeCallHandle;
pub const call = ext.wrenCall;
pub const releaseHandle = ext.wrenReleaseHandle;
pub const getSlotCount = ext.wrenGetSlotCount;
pub const ensureSlots = ext.wrenEnsureSlots;
pub const getSlotType = ext.wrenGetSlotType;
pub const getSlotBool = ext.wrenGetSlotBool;
pub const getSlotBytes = ext.wrenGetSlotBytes;
pub const getSlotDouble = ext.wrenGetSlotDouble;
pub const getSlotForeign = ext.wrenGetSlotForeign;
pub const getSlotString = ext.wrenGetSlotString;
pub const getSlotHandle = ext.wrenGetSlotHandle;
pub const setSlotBool = ext.wrenSetSlotBool;
pub const setSlotBytes = ext.wrenSetSlotBytes;
pub const setSlotDouble = ext.wrenSetSlotDouble;
pub const setSlotNewForeign = ext.wrenSetSlotNewForeign;
pub const setSlotNewList = ext.wrenSetSlotNewList;
pub const setSlotNewMap = ext.wrenSetSlotNewMap;
pub const setSlotNull = ext.wrenSetSlotNull;
pub const setSlotString = ext.wrenSetSlotString;
pub const setSlotHandle = ext.wrenSetSlotHandle;
pub const getListCount = ext.wrenGetListCount;
pub const getListElement = ext.wrenGetListElement;
pub const setListElement = ext.wrenSetListElement;
pub const insertInList = ext.wrenInsertInList;
pub const getMapCount = ext.wrenGetMapCount;
pub const getMapContainsKey = ext.wrenGetMapContainsKey;
pub const getMapValue = ext.wrenGetMapValue;
pub const setMapValue = ext.wrenSetMapValue;
pub const removeMapValue = ext.wrenRemoveMapValue;
pub const getVariable = ext.wrenGetVariable;
pub const hasVariable = ext.wrenHasVariable;
pub const hasModule = ext.wrenHasModule;
pub const abortFiber = ext.wrenAbortFiber;
pub const getUserData = ext.wrenGetUserData;
pub const setUserData = ext.wrenSetUserData;

// Meta extension
pub const metaSource = ext.wrenMetaSource;
pub const metaBindForeignMethod = ext.wrenMetaBindForeignMethod;

// Random extension
pub const randomSource = ext.wrenRandomSource;
pub const randomBindForeignClass = ext.wrenRandomBindForeignClass;
pub const randomBindForeignMethod = ext.wrenRandomBindForeignMethod;

//////////////////////////////////////////////////////////////////////////////

pub const ForeignMethod = struct {
    module:[]const u8,
    className:[]const u8,
    signature:[]const u8,
    isStatic:bool,
    ptr:ForeignMethodFn,
};

pub const ForeignClass = struct {
    module:[]const u8,
    className:[]const u8,
    methods:ForeignClassMethods,
};

pub const AllocateFnSig = (?fn (?*VM) callconv(.C) void);
pub const FinalizeFnSig = (?fn (?*c_void) callconv(.C) void);

pub const DataType = enum(u32) {
    wren_bool = 0,
    wren_num = 1,
    wren_foreign = 2,
    wren_list = 3,
    wren_map = 4,
    wren_null = 5,
    wren_string = 6,
    wren_unknown = 7,
};

pub const ResType = enum(u32) {
    success = 0,
    compile_error = 1,
    runtime_error = 2,
};

pub const ErrType = enum(u32) {
    compile = 0,
    runtime = 1,
    stack_trace = 2,
};

//////////////////////////////////////////////////////////////////////////////

pub fn init(allocator:*std.mem.Allocator) void {
    data.allocator = allocator;
    data.method_lookup = HashedArrayList(usize,ForeignMethod).init(data.allocator);
    data.class_lookup = HashedArrayList(usize,ForeignClass).init(data.allocator);
}

pub fn deinit() void {
    data.method_lookup.deinit();
    data.class_lookup.deinit();
}

//////////////////////////////////////////////////////////////////////////////

pub fn MethodCallHandle(
    module:[*c]const u8,
    className:[*c]const u8,
    signature:[*c]const u8,
    arg_types:anytype,
    ret_type:anytype
) type {
    return struct {
        const Self = @This();
        
        vm:?*VM = undefined,
        method_sig:?*Handle = undefined,
        class_handle:?*Handle = undefined,
        slots:u8 = 0,

        pub fn init (vm:?*VM) !Self {
            var sig = makeCallHandle(vm,signature);
            if(sig == null) {
                return error.InvalidSignature;
            }            

            ensureSlots(vm, 1);
            getVariable(vm, module, className, 0);
            var hnd = getSlotHandle(vm, 0);
            if(hnd == null) {
                return error.InvalidClass;
            }

            return Self {
                .vm = vm,
                .method_sig = sig,
                .class_handle = hnd,
                .slots = arg_types.len + 1
            };
        }

        pub fn deinit (self:*Self) void {
            releaseHandle(self.vm,self.method_sig);
            releaseHandle(self.vm,self.class_handle);
        }

        pub fn callMethod (self:*Self, args:anytype) !ret_type {
            ensureSlots(self.vm, self.slots);
            setSlotHandle(self.vm, 0, self.class_handle);

            inline for(arg_types) |v,i| {
                switch(@typeInfo(v)) {
                    .Int => setSlotDouble(self.vm, i + 1, @intToFloat(f64,args[i])),
                    .Float => setSlotDouble(self.vm, i + 1, @floatCast(f64,args[i])),
                    // .Array / strings ?
                    // .Void
                    else => return error.UnsupportedParameterType,
                }
            } 
        
            var cres:InterpretResult = call(self.vm,self.method_sig);
            switch(@intToEnum(ResType,cres)) {
                .compile_error => return error.CompileError,
                .runtime_error => return error.RuntimeError,
                else => {
                    if(ret_type == void) return;
                    switch(@typeInfo(ret_type)) {
                        .Int => return @floatToInt(ret_type,getSlotDouble(self.vm,0)),
                        .Float => return @floatCast(ret_type,getSlotDouble(self.vm,0)),
                        // .Array / Strings ?
                        else => return error.UnsupportedReturnType,
                    }
                },
            }

        }

    };

}
