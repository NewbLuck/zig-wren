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
    /// Called after loadModuleFn is called for module [name]. The original returned result
    /// is handed back to you in this callback, so that you can free memory if appropriate.
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
    /// The callback invoked when the foreign object is created.
    /// This must be provided. Inside the body of this, it must call
    /// [setSlotNewForeign()] exactly once.
    allocate: WrenForeignMethodFn,
    /// The callback invoked when the garbage collector is about to collect a
    /// foreign object's memory.
    /// This may be `NULL` if the foreign class does not need to finalize.    
    finalize: WrenFinalizerFn,
};
pub const WrenBindForeignClassFn = ?fn (?*WrenVM, [*c]const u8, [*c]const u8) callconv(.C) WrenForeignClassMethods;
pub const WrenConfiguration = extern struct {
    /// The callback Wren will use to allocate, reallocate, and deallocate memory.
    ///
    /// If `NULL`, defaults to a built-in function that uses `realloc` and `free`.
    reallocateFn: WrenReallocateFn,
    /// The callback Wren uses to resolve a module name.
    ///
    /// Some host applications may wish to support "relative" imports, where the
    /// meaning of an import string depends on the module that contains it. To
    /// support that without baking any policy into Wren itself, the VM gives the
    /// host a chance to resolve an import string.
    ///
    /// Before an import is loaded, it calls this, passing in the name of the
    /// module that contains the import and the import string. The host app can
    /// look at both of those and produce a new "canonical" string that uniquely
    /// identifies the module. This string is then used as the name of the module
    /// going forward. It is what is passed to [loadModuleFn], how duplicate
    /// imports of the same module are detected, and how the module is reported in
    /// stack traces.
    ///
    /// If you leave this function NULL, then the original import string is
    /// treated as the resolved string.
    ///
    /// If an import cannot be resolved by the embedder, it should return NULL and
    /// Wren will report that as a runtime error.
    ///
    /// Wren will take ownership of the string you return and free it for you, so
    /// it should be allocated using the same allocation function you provide
    /// above.    
    resolveModuleFn: WrenResolveModuleFn,
    /// The callback Wren uses to load a module.
    ///
    /// Since Wren does not talk directly to the file system, it relies on the
    /// embedder to physically locate and read the source code for a module. The
    /// first time an import appears, Wren will call this and pass in the name of
    /// the module being imported. The method will return a result, which contains
    /// the source code for that module. Memory for the source is owned by the 
    /// host application, and can be freed using the onComplete callback.
    ///
    /// This will only be called once for any given module name. Wren caches the
    /// result internally so subsequent imports of the same module will use the
    /// previous source and not call this.
    ///
    /// If a module with the given name could not be found by the embedder, it
    /// should return NULL and Wren will report that as a runtime error.
    loadModuleFn: WrenLoadModuleFn,
    /// The callback Wren uses to find a foreign method and bind it to a class.
    ///
    /// When a foreign method is declared in a class, this will be called with the
    /// foreign method's module, class, and signature when the class body is
    /// executed. It should return a pointer to the foreign function that will be
    /// bound to that method.
    ///
    /// If the foreign function could not be found, this should return NULL and
    /// Wren will report it as runtime error.    
    bindForeignMethodFn: WrenBindForeignMethodFn,
    /// The callback Wren uses to find a foreign class and get its foreign methods.
    ///
    /// When a foreign class is declared, this will be called with the class's
    /// module and name when the class body is executed. It should return the
    /// foreign functions uses to allocate and (optionally) finalize the bytes
    /// stored in the foreign object when an instance is created.    
    bindForeignClassFn: WrenBindForeignClassFn,
    /// The callback Wren uses to display text when `System.print()` or the other
    /// related functions are called.
    ///
    /// If this is `NULL`, Wren discards any printed text.    
    writeFn: WrenWriteFn,
    /// The callback Wren uses to report errors.
    ///
    /// When an error occurs, this will be called with the module name, line
    /// number, and an error message. If this is `NULL`, Wren doesn't report any    
    errorFn: WrenErrorFn,
    /// The number of bytes Wren will allocate before triggering the first garbage
    /// collection.
    ///
    /// If zero, defaults to 10MB.    
    initialHeapSize: usize,
    /// After a collection occurs, the threshold for the next collection is
    /// determined based on the number of bytes remaining in use. This allows Wren
    /// to shrink its memory usage automatically after reclaiming a large amount
    /// of memory.
    ///
    /// This can be used to ensure that the heap does not get too small, which can
    /// in turn lead to a large number of collections afterwards as the heap grows
    /// back to a usable size.
    ///
    /// If zero, defaults to 1MB.    
    minHeapSize: usize,
    /// Wren will resize the heap automatically as the number of bytes
    /// remaining in use after a collection changes. This number determines the
    /// amount of additional memory Wren will use after a collection, as a
    /// percentage of the current heap size.
    ///
    /// For example, say that this is 50. After a garbage collection, when there
    /// are 400 bytes of memory still in use, the next collection will be triggered
    /// after a total of 600 bytes are allocated (including the 400 already in
    /// use.)
    ///
    /// Setting this to a smaller number wastes less memory, but triggers more
    /// frequent garbage collections.
    ///
    /// If zero, defaults to 50.    
    heapGrowthPercent: c_int,
    /// User-defined data associated with the VM.
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
