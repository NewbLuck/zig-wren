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
/// A single virtual machine for executing Wren code.
/// Wren has no global state, so all state stored by a running interpreter lives
/// here.
pub const VM = c.WrenVM;
/// A handle to a Wren object.
/// This lets code outside of the VM hold a persistent reference to an object.
/// After a handle is acquired, and until it is released, this ensures the
/// garbage collector will not reclaim the object it references.
pub const Handle = c.WrenHandle;

/// A generic allocation function that handles all explicit memory management
/// used by Wren. It's used like so:
/// - To allocate new memory, [memory] is NULL and [newSize] is the desired
///   size. It should return the allocated memory or NULL on failure.
/// - To attempt to grow an existing allocation, [memory] is the memory, and
///   [newSize] is the desired size. It should return [memory] if it was able to
///   grow it in place, or a new pointer if it had to move it.
/// - To shrink memory, [memory] and [newSize] are the same as above but it will
///   always return [memory].
/// - To free memory, [memory] will be the memory to free and [newSize] will be
///   zero. It should return NULL.
pub const ReallocateFn = c.WrenReallocateFn;
/// A function callable from Wren code, but implemented in C.
pub const ForeignMethodFn = c.WrenForeignMethodFn;
/// A finalizer function for freeing resources owned by an instance of a foreign
/// class. Unlike most foreign methods, finalizers do not have access to the VM
/// and should not interact with it since it's in the middle of a garbage
/// collection.
pub const FinalizerFn = c.WrenFinalizerFn;
/// Gives the host a chance to canonicalize the imported module name,
/// potentially taking into account the (previously resolved) name of the module
/// that contains the import. Typically, this is used to implement relative
/// imports.
pub const ResolveModuleFn = c.WrenResolveModuleFn;
/// Gives the host a chance to canonicalize the imported module name,
/// potentially taking into account the (previously resolved) name of the module
/// that contains the import. Typically, this is used to implement relative
/// imports.
pub const LoadModuleCompleteFn = c.WrenLoadModuleCompleteFn;
/// The result of a loadModuleFn call. 
/// [source] is the source code for the module, or NULL if the module is not found.
/// [onComplete] an optional callback that will be called once Wren is done with the result.
pub const LoadModuleResult = c.WrenLoadModuleResult;
/// Loads and returns the source code for the module [name].
pub const LoadModuleFn = c.WrenLoadModuleFn;
/// Returns a pointer to a foreign method on [className] in [module] with
/// [signature].
pub const BindForeignMethodFn = c.WrenBindForeignMethodFn;

/// Displays a string of text to the user.
pub const WriteFn = c.WrenWriteFn;
/// Reports an error to the user.
///
/// An error detected during compile time is reported by calling this once with
/// [type] `WREN_ERROR_COMPILE`, the resolved name of the [module] and [line]
/// where the error occurs, and the compiler's error [message].
///
/// A runtime error is reported by calling this once with [type]
/// `WREN_ERROR_RUNTIME`, no [module] or [line], and the runtime error's
/// [message]. After that, a series of [type] `WREN_ERROR_STACK_TRACE` calls are
/// made for each line in the stack trace. Each of those has the resolved
/// [module] and [line] where the method or function is defined and [message] is
/// the name of the method or function.
pub const ErrorFn = c.WrenErrorFn;
/// Returns a pair of pointers to the foreign methods used to allocate and
/// finalize the data for instances of [className] in resolved [module].
pub const ForeignClassMethods = c.WrenForeignClassMethods;
/// The callback Wren uses to find a foreign class and get its foreign methods.
///
/// When a foreign class is declared, this will be called with the class's
/// module and name when the class body is executed. It should return the
/// foreign functions uses to allocate and (optionally) finalize the bytes
/// stored in the foreign object when an instance is created.
pub const BindForeignClassFn = c.WrenBindForeignClassFn;
/// The VM configuration for Wren
pub const Configuration = c.WrenConfiguration;
/// The result type, maps to ResType enum.
pub const InterpretResult = c.WrenInterpretResult;
/// The error type, maps to ErrType enum
pub const ErrorType = c.WrenErrorType;
/// The slot data type, maps to DataType enum
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
/// Get the current wren version number.
///
/// Can be used to range checks over versions.
pub const getVersionNumber = ext.wrenGetVersionNumber;
/// Initializes [configuration] with all of its default values.
///
/// Call this before setting the particular fields you care about.
pub const initConfiguration = ext.wrenInitConfiguration;
/// Creates a new Wren virtual machine using the given [configuration]. Wren
/// will copy the configuration data, so the argument passed to this can be
/// freed after calling this. If [configuration] is `NULL`, uses a default
/// configuration.
pub const newVM = ext.wrenNewVM;
/// Disposes of all resources is use by [vm], which was previously created by a
/// call to [newVM].
pub const freeVM = ext.wrenFreeVM;
/// Immediately run the garbage collector to free unused memory.
pub const collectGarbage = ext.wrenCollectGarbage;
/// Runs [source], a string of Wren source code in a new fiber in [vm] in the
/// context of resolved [module].
pub const interpret = ext.wrenInterpret;
/// Creates a handle that can be used to invoke a method with [signature] on
/// using a receiver and arguments that are set up on the stack.
///
/// This handle can be used repeatedly to directly invoke that method from C
/// code using [wrenCall].
///
/// When you are done with this handle, it must be released using
/// [wrenReleaseHandle].
pub const makeCallHandle = ext.wrenMakeCallHandle;
/// Calls [method], using the receiver and arguments previously set up on the
/// stack.
///
/// [method] must have been created by a call to [makeCallHandle]. The
/// arguments to the method must be already on the stack. The receiver should be
/// in slot 0 with the remaining arguments following it, in order. It is an
/// error if the number of arguments provided does not match the method's
/// signature.
///
/// After this returns, you can access the return value from slot 0 on the stack.
pub const call = ext.wrenCall;
/// Releases the reference stored in [handle]. After calling this, [handle] can
/// no longer be used.
pub const releaseHandle = ext.wrenReleaseHandle;
/// Returns the number of slots available to the current foreign method.
pub const getSlotCount = ext.wrenGetSlotCount;
/// Ensures that the foreign method stack has at least [numSlots] available for
/// use, growing the stack if needed.
///
/// Does not shrink the stack if it has more than enough slots.
///
/// It is an error to call this from a finalizer.
pub const ensureSlots = ext.wrenEnsureSlots;
/// Gets the type of the object in [slot].
pub const getSlotType = ext.wrenGetSlotType;
/// Reads a boolean value from [slot].
///
/// It is an error to call this if the slot does not contain a boolean value.
pub const getSlotBool = ext.wrenGetSlotBool;
/// Reads a byte array from [slot].
///
/// The memory for the returned string is owned by Wren. You can inspect it
/// while in your foreign method, but cannot keep a pointer to it after the
/// function returns, since the garbage collector may reclaim it.
///
/// Returns a pointer to the first byte of the array and fill [length] with the
/// number of bytes in the array.
///
/// It is an error to call this if the slot does not contain a string.
pub const getSlotBytes = ext.wrenGetSlotBytes;
/// Reads a number from [slot].
///
/// It is an error to call this if the slot does not contain a number.
pub const getSlotDouble = ext.wrenGetSlotDouble;
/// Reads a foreign object from [slot] and returns a pointer to the foreign data
/// stored with it.
///
/// It is an error to call this if the slot does not contain an instance of a
/// foreign class.
pub const getSlotForeign = ext.wrenGetSlotForeign;
/// Reads a string from [slot].
///
/// The memory for the returned string is owned by Wren. You can inspect it
/// while in your foreign method, but cannot keep a pointer to it after the
/// function returns, since the garbage collector may reclaim it.
///
/// It is an error to call this if the slot does not contain a string.
pub const getSlotString = ext.wrenGetSlotString;
/// Creates a handle for the value stored in [slot].
///
/// This will prevent the object that is referred to from being garbage collected
/// until the handle is released by calling [releaseHandle()].
pub const getSlotHandle = ext.wrenGetSlotHandle;
/// Stores the boolean [value] in [slot].
pub const setSlotBool = ext.wrenSetSlotBool;
/// Stores the array [length] of [bytes] in [slot].
///
/// The bytes are copied to a new string within Wren's heap, so you can free
/// memory used by them after this is called.
pub const setSlotBytes = ext.wrenSetSlotBytes;
/// Stores the numeric [value] in [slot].
pub const setSlotDouble = ext.wrenSetSlotDouble;
/// Creates a new instance of the foreign class stored in [classSlot] with [size]
/// bytes of raw storage and places the resulting object in [slot].
///
/// This does not invoke the foreign class's constructor on the new instance. If
/// you need that to happen, call the constructor from Wren, which will then
/// call the allocator foreign method. In there, call this to create the object
/// and then the constructor will be invoked when the allocator returns.
///
/// Returns a pointer to the foreign object's data.
pub const setSlotNewForeign = ext.wrenSetSlotNewForeign;
/// Stores a new empty list in [slot].
pub const setSlotNewList = ext.wrenSetSlotNewList;
/// Stores a new empty map in [slot].
pub const setSlotNewMap = ext.wrenSetSlotNewMap;
/// Stores null in [slot].
pub const setSlotNull = ext.wrenSetSlotNull;
/// Stores the string [text] in [slot].
///
/// The [text] is copied to a new string within Wren's heap, so you can free
/// memory used by it after this is called. The length is calculated using
/// [strlen()]. If the string may contain any null bytes in the middle, then you
/// should use [setSlotBytes()] instead.
pub const setSlotString = ext.wrenSetSlotString;
/// Stores the value captured in [handle] in [slot].
///
/// This does not release the handle for the value.
pub const setSlotHandle = ext.wrenSetSlotHandle;
/// Returns the number of elements in the list stored in [slot].
pub const getListCount = ext.wrenGetListCount;
/// Reads element [index] from the list in [listSlot] and stores it in
/// [elementSlot].
pub const getListElement = ext.wrenGetListElement;
/// Sets the value stored at [index] in the list at [listSlot], 
/// to the value from [elementSlot]. 
pub const setListElement = ext.wrenSetListElement;
/// Takes the value stored at [elementSlot] and inserts it into the list stored
/// at [listSlot] at [index].
///
/// As in Wren, negative indexes can be used to insert from the end. To append
/// an element, use `-1` for the index.
pub const insertInList = ext.wrenInsertInList;
/// Returns the number of entries in the map stored in [slot].
pub const getMapCount = ext.wrenGetMapCount;
/// Returns true if the key in [keySlot] is found in the map placed in [mapSlot].
pub const getMapContainsKey = ext.wrenGetMapContainsKey;
//EXTENSION: Returns the key into the [keySlot] and value into [valueSlot] of the 
// map in [mapSlot] at the map index of [index]
pub const getMapElement = ext.wrenGetMapElement;
/// Retrieves a value with the key in [keySlot] from the map in [mapSlot] and
/// stores it in [valueSlot].
pub const getMapValue = ext.wrenGetMapValue;
/// Takes the value stored at [valueSlot] and inserts it into the map stored
/// at [mapSlot] with key [keySlot].
pub const setMapValue = ext.wrenSetMapValue;
/// Removes a value from the map in [mapSlot], with the key from [keySlot],
/// and place it in [removedValueSlot]. If not found, [removedValueSlot] is
/// set to null, the same behaviour as the Wren Map API.
pub const removeMapValue = ext.wrenRemoveMapValue;
/// Looks up the top level variable with [name] in resolved [module] and stores
/// it in [slot].
pub const getVariable = ext.wrenGetVariable;
/// Looks up the top level variable with [name] in resolved [module], 
/// returns false if not found. The module must be imported at the time, 
/// use wrenHasModule to ensure that before calling.
pub const hasVariable = ext.wrenHasVariable;
/// Returns true if [module] has been imported/resolved before, false if not.
pub const hasModule = ext.wrenHasModule;
/// Sets the current fiber to be aborted, and uses the value in [slot] as the
/// runtime error object.
pub const abortFiber = ext.wrenAbortFiber;
/// Returns the user data associated with the WrenVM.
pub const getUserData = ext.wrenGetUserData;
/// Sets user data associated with the WrenVM.
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

/// Data type returned from slot-checking functions
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
/// Result from a wren call or code execution
pub const ResType = enum(u32) {
    success = 0,
    compile_error = 1,
    runtime_error = 2,
};
/// Type of error
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

/// This is a handle to a method in Wren that can be used to call the method
/// and optionally get data back.
/// arg_types shoud be a tuple of the Zig-compatible argument types of the 
/// Wren method, and the return type should be the type you want back, or null.
pub fn MethodCallHandle(
    /// The module name, usually "main"
    comptime module:[*c]const u8,
    /// The class name
    comptime className:[*c]const u8,
    /// The signature of the method
    comptime signature:[*c]const u8,
    /// A tuple or types being passed to the method, in the same order as
    /// they are defined in the method.
    /// - This will handle conversions between Wren's double and all i/f types.  
    /// - To pass a list, either use a typed slice for single-typed lists, or 
    ///   pass a tuple of types for a multi-type list.
    /// - Strings are recognized by std.meta.trait.isZigString, as well as
    ///   [*c]const u8 and [*c] u8.
    comptime arg_types:anytype,
    /// The Zig type being returned for the method.  The same auto-casting
    /// rules apply as arg_types.
    comptime ret_type:anytype
) type {
    return struct {
        const Self = @This();
        
        vm:?*VM = undefined,
        method_sig:?*Handle = undefined,
        class_handle:?*Handle = undefined,
        slots:u8 = 0,

        /// Prepare the handle by grabbing all needed handles and signatures.
        /// Small performance hit.
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

        /// Releases the Wren handles
        pub fn deinit (self:*Self) void {
            releaseHandle(self.vm,self.method_sig);
            releaseHandle(self.vm,self.class_handle);
        }

        /// Calls the method that this type defines with a tuple of given values
        /// that match the type def.
        /// What currently works:
        /// - OUT/IN All number types (i8/i32/usize/f16/f64/etc)
        /// - OUT/IN Bool
        /// - OUT/IN Strings (as []const u8])
        /// - OUT/   Null
        /// - OUT/IN Single-typed lists (as slice)
        /// - OUT/-- Multi-typed lists (as tuple)
        /// - ---/IN Maps (as a hashmap, AutoHashMap or StringHashMap)
        pub fn callMethod (self:*Self, args:anytype) !ret_type {
            ensureSlots(self.vm, self.slots + 1);
            setSlotHandle(self.vm, 0, self.class_handle);
            // Process out our arguments
            inline for(arg_types) |v,i| {
                switch(@typeInfo(v)) {
                    .Int => setSlotDouble(self.vm, i + 1, @intToFloat(f64,args[i])),
                    .Float => setSlotDouble(self.vm, i + 1, @floatCast(f64,args[i])),
                    .Bool => setSlotBool(self.vm, i + 1, args[i]),
                    .Null => setSlotNull(self.vm, i + 1, args[i]),
                    .Pointer => |ptr| { 
                        //String, or slice of strings or values (Wren list)
                        comptime var T = ptr.child;
                        comptime var is_str = util.isCString(v) or std.meta.trait.isZigString(v);
                        comptime var is_int = std.meta.trait.isIntegral(T);
                        comptime var is_astr = util.isCString(T) or std.meta.trait.isZigString(T);
                        comptime var is_bool = (T == bool);
                        if(ptr.size == .Slice) {
                            if(is_str) {
                                setSlotString(self.vm,i + 1,args[i]);
                            } else {
                                setSlotNewList(self.vm,i + 1);
                                inline for(args[i]) |vx,ix| {
                                    if(is_astr) {
                                        setSlotString(self.vm,i + 2,vx);
                                    } else if(is_bool) {
                                        setSlotBool(self.vm,i + 2,vx);
                                    } else if(is_int) {
                                        setSlotDouble(self.vm,i + 2, @intToFloat(f64,vx));
                                    } else {
                                        setSlotDouble(self.vm,i + 2, @floatCast(f64,vx));
                                    }
                                    insertInList(self.vm,i + 1,@intCast(c_int,ix),i + 2);
                                }
                            }
                        }
                    },
                    .Struct => |ptr| {
                        if(!ptr.is_tuple) {
                            // HASHMAPS HERE
                            if(!util.isHashMap(v)) return error.UnsupportedParameterType;
                            //const kv_type = util.getHashMapTypes(v);

                            return error.UnimplementedParameterType;
                            // construct the map
                        } 
                        // Tuples, used to pass multi-type Wren lists
                        setSlotNewList(self.vm,i + 1);
                        inline for(args[i]) |vt,it| { //tuple index
                            comptime var T = @TypeOf(vt);
                            comptime var is_str = util.isCString(T) or std.meta.trait.isZigString(T);
                            comptime var is_int = std.meta.trait.isIntegral(T);
                            comptime var is_bool = (T == bool);
                            if(is_str) {
                                setSlotString(self.vm,i + 2,vt);
                            } else if(is_bool) {
                                setSlotBool(self.vm,i + 2,vt);
                            } else if(is_int) {
                                setSlotDouble(self.vm,i + 2, @intToFloat(f64,vt));
                            } else {
                                setSlotDouble(self.vm,i + 2, @floatCast(f64,vt));
                            }
                            insertInList(self.vm,i + 1,@intCast(c_int,it),i + 2);
                        }
                    },
                    else => return error.UnsupportedParameterType,
                }
            } 
            // Call method
            var cres:InterpretResult = call(self.vm,self.method_sig);
            switch(@intToEnum(ResType,cres)) {
                .compile_error => return error.CompileError,
                .runtime_error => return error.RuntimeError,
                else => { },
            }
            // Read our return back in
            if(ret_type == void) return;
            switch(@typeInfo(ret_type)) {
                .Int => return @floatToInt(ret_type,getSlotDouble(self.vm,0)),
                .Float => return @floatCast(ret_type,getSlotDouble(self.vm,0)),
                .Bool => return getSlotBool(self.vm,0),
                .Pointer => |ptr| {
                    comptime var T = ptr.child;
                    comptime var is_str = util.isCString(ret_type) or std.meta.trait.isZigString(ret_type);
                    comptime var is_int = std.meta.trait.isIntegral(T);
                    comptime var is_astr = util.isCString(T) or std.meta.trait.isZigString(T);
                    comptime var is_bool = (T == bool);
                    if(ptr.size == .Slice) {
                        // String
                        if(is_str) {
                            return std.mem.span(getSlotString(self.vm,0));
                        } 
                        // Single-type list(as slice)
                        ensureSlots(self.vm,2);
                        var idx:c_int = 0;
                        var list = std.ArrayList(T).init(data.allocator);
                        while(idx < getListCount(self.vm,0)) : (idx += 1) {
                            getListElement(self.vm,0,idx,1);
                            if(is_astr) { // C String
                                try list.append(std.mem.span(getSlotString(self.vm,1)));
                            } else if(is_bool) { // Number
                                // Bool
                                try list.append(getSlotBool(self.vm,1));
                            } else if(is_int) { // Number
                                // Int
                                try list.append(@floatToInt(T,getSlotDouble(self.vm,1)));
                            } else {
                                // Float
                                try list.append(@floatCast(T,getSlotDouble(self.vm,1)));
                            }
                        }
                        return list.toOwnedSlice();
                    }
                },    
                .Struct => {
                    if(!util.isHashMap(ret_type)) return error.UnsupportedParameterType;
                    ensureSlots(self.vm,3);

                    const kv_type = util.getHashMapTypes(ret_type);
                    comptime var key_str = util.isCString(kv_type.key) or std.meta.trait.isZigString(kv_type.key);
                    comptime var key_int = std.meta.trait.isIntegral(kv_type.key);
                    comptime var key_bool = (kv_type.key == bool);
                    
                    comptime var val_str = util.isCString(kv_type.value) or std.meta.trait.isZigString(kv_type.value);
                    comptime var val_int = std.meta.trait.isIntegral(kv_type.value);
                    comptime var val_bool = (kv_type.value == bool);

                    var map = ret_type.init(data.allocator);
                    
                    var idx:c_int = 0;
                    var mc = getMapCount(self.vm,0);
                    std.debug.print("CT: {any}",.{mc});
                    while(idx < mc) : (idx += 1) {
                        getMapElement(self.vm,0,idx,1,2);
                        std.debug.print(" >> {any}",.{std.mem.span(getSlotString(self.vm,1))});
                        std.debug.print(" >> {any}\n",.{std.mem.span(getSlotString(self.vm,2))});
                        var val:kv_type.value = undefined;
                        if(val_str) {
                            val = std.mem.span(getSlotString(self.vm,2));
                        } else if(val_bool) {
                            val = getSlotBool(self.vm,2);
                        } else if (val_int) {
                            val = @floatToInt(kv_type.value,getSlotDouble(self.vm,2));
                        } else {
                            val = @floatCast(kv_type.value,getSlotDouble(self.vm,2));
                        }

                        if(key_str) {
                            try map.put(std.mem.span(getSlotString(self.vm,1)),val);
                        } else if(key_bool) {
                            try map.put(getSlotBool(self.vm,1),val);
                        } else if(key_int) {
                            try map.put(@floatToInt(kv_type.key,getSlotDouble(self.vm,1)),val);
                        } else {
                            try map.put(@floatCast(kv_type.key,getSlotDouble(self.vm,1)),val);
                        }
                    }
                    return map;
                },              
                // Tuple for diff value lists?
                else => return error.UnsupportedReturnType,
            }

        }

    };

}
