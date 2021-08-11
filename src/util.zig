const std = @import("std");
usingnamespace @import("wren.zig");

/// Returns the basic Wren default configuration with the basic handlers 
/// defined in this library 
pub fn initDefaultConfig (configuration:[*c]Configuration) void {
    initConfiguration(configuration);
    configuration.*.writeFn = bindings.writeFn;
    configuration.*.errorFn = bindings.errorFn;
    configuration.*.bindForeignMethodFn = bindings.foreignMethodFn;
    configuration.*.bindForeignClassFn = bindings.bindForeignClassFn;
    configuration.*.loadModuleFn = bindings.loadModuleFn;        
}

/// Tests if a C string matches a Zig string
pub fn matches (cstr:CString,str:[]const u8) bool {
    return std.mem.eql(u8,std.mem.span(cstr),str);
}

/// Loads a Wren source file based on the current working path
/// Appends '.wren' onto the end of the given path
/// Caller must deallocate file contents?
pub fn loadWrenSourceFile (allocator:*std.mem.Allocator,path:[]const u8) !CString {
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

/// A simple code runner
pub fn run (vm:?*VM,module:CString,code:CString) !void {
    var call_res = @intToEnum(ResType,interpret(vm,module,code));
    switch (call_res) {
        .compile_error => return error.CompileError,
        .runtime_error => return error.RuntimeError,
        .success => return,
        //else => return error.UnexpectedResult,
    }
}

/// Retuns the DataType enum of the slot type at the given index
pub fn slotType(vm:?*VM,slot:i32) DataType {
    return @intToEnum(DataType,getSlotType(vm,slot));
}

/// Returns true for types of [*c]const u8 and [*c]u8
pub fn isCString(comptime T:type) bool {
    comptime {
        const info = @typeInfo(T);
        if (info != .Pointer) return false;
        const ptr = &info.Pointer;
        return (ptr.size == .C and
                ptr.is_volatile == false and
                ptr.alignment == 1 and
                ptr.child == u8 and
                ptr.is_allowzero == true and
                ptr.sentinel == null); 
    }
}

/// Prints the current slot state to stdout via std.debug.print
pub fn dumpSlotState(vm:?*VM) void {
    const print = std.debug.print; //Lazy

    var active_slots = getSlotCount(vm);
    print("\nSlots Acitve: {}\n",.{active_slots});
    var i:c_int = 0;
    while(i < active_slots) : (i += 1) {
        var slot_type = slotType(vm,i);
        print(" [{d}]: {s}\n  '---> ",.{i,slot_type});
        switch(slot_type) {
            .wren_bool => print("{}\n",.{getSlotBool(vm,i)}),
            .wren_foreign => print("{any}\n",.{getSlotForeign(vm,i)}),
            .wren_list => print("List [{d}]\n",.{getListCount(vm,i)}),
            .wren_map => print("{s}\n",.{"MAP"}),
            .wren_null => print("{s}\n",.{"NULL"}),
            .wren_num => print("{d}\n",.{getSlotDouble(vm,i)}),
            .wren_string => print("{s}\n",.{getSlotString(vm,i)}),
            .wren_unknown => {
                var handle = getSlotHandle(vm,i);
                print("{any}\n",.{handle});
            },
        }
        
    }
}

pub fn isHashMap(comptime hash_map:anytype) bool {
    return @hasDecl(hash_map,"KV") and @hasDecl(hash_map,"Hash");
}

const KVType = struct {key:type, value:type};

pub fn getHashMapTypes(comptime hash_map:anytype) KVType {
    return .{
        .key = TypeOfField(hash_map.KV, "key"),
        .value = TypeOfField(hash_map.KV, "value"),
    };
}

pub fn TypeOfField(comptime structure: anytype, comptime field_name: []const u8) type {
    inline for (std.meta.fields(structure)) |f| {
        if (std.mem.eql(u8, f.name, field_name)) {
            return f.field_type;
        }
    }
    @compileError(field_name ++ " not found in " ++ @typeName(@TypeOf(structure)));
}
