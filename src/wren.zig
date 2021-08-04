const std = @import("std");
const c = @import("c.zig");
const ext = @import("externs.zig");

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

pub const util = struct{

    /// Tests if a c string matches a zig string
    pub fn matches (cstr:[*c]const u8,str:[]const u8) bool {
        return std.mem.eql(u8,std.mem.span(cstr),str);
    }

    /// Loads a Wren source file based on the current working path
    /// Appends '.wren' onto the end of the given path
    /// Caller must deallocate file contents?
    pub fn loadWrenSourceFile (allocator:*std.mem.Allocator,path:[]const u8) ![*c]const u8 {
        const file_size_limit:usize = 1024 * 1024 * 2; // 2Mb, should be pretty reasonable

        const c_dir = std.fs.cwd();
        const fpath = std.mem.concat(allocator,u8,
            &[_][]const u8{std.mem.span(path),".wren"[0..]}
        ) catch unreachable;
        defer allocator.free(fpath);

        const cpath = c_dir.realpathAlloc(allocator,".") catch unreachable;
        defer allocator.free(cpath);

        std.debug.print("Loading module: {s} from location {s}\n",.{fpath,cpath});
        const file_contents = try c_dir.readFileAlloc(allocator,fpath,file_size_limit);

        const rval = @ptrCast([*c]const u8,file_contents);
        return rval;
    }
};