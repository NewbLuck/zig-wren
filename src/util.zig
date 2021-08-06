const std = @import("std");
usingnamespace @import("wren.zig");

pub fn initDefaultConfig (configuration:[*c]Configuration) void {
    initConfiguration(configuration);
    configuration.*.writeFn = bindings.writeFn;
    configuration.*.errorFn = bindings.errorFn;
    configuration.*.bindForeignMethodFn = bindings.foreignMethodFn;
    configuration.*.bindForeignClassFn = bindings.bindForeignClassFn;
    configuration.*.loadModuleFn = bindings.loadModuleFn;        
}

/// Tests if a c string matches a zig string
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


pub fn run (vm:?*VM,module:CString,code:CString) !void {
    var call_res:InterpretResult = interpret(vm,module,code);
    switch (call_res) {
        RESULT_COMPILE_ERROR => return error.CompileError,
        RESULT_RUNTIME_ERROR => return error.RuntimeError,
        RESULT_SUCCESS => return,
        else => return error.UnexpectedResult,
    }
}    
