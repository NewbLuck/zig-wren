const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

pub const Point = struct {
    size:f64 = 0,
    
    pub fn setSize (vm:?*wren.VM) callconv(.C) void {
        if(wren.getSlotForeign(vm, 0)) |ptr| {
            var point = @ptrCast(*Point,@alignCast(@alignOf(*Point),ptr));
            var nsize:f64 = wren.getSlotDouble(vm, 1);
            std.debug.print(" [+] Setting point to: {d}\n",.{nsize});
            if(nsize < 1.0) {
                wren.setSlotString(vm, 0, "That is way too small!");
                wren.abortFiber(vm, 0);
                return;
            }
            point.*.size = nsize;
            std.debug.print(" [+] Point is now: {d}\n",.{nsize});
        }
    }
};

pub fn main() anyerror!void {
    // Set up a VM configuration

    var config:wren.Configuration = undefined;
    wren.initConfiguration(&config);
    config.writeFn = writeFn;
    config.errorFn = errorFn;
    config.bindForeignMethodFn = bindForeignMethodFn;
    config.bindForeignClassFn = bindForeignClassFn;
    config.loadModuleFn = loadModuleFn;

    // Create VM from our config
    var vm = wren.newVM(&config);
    defer wren.freeVM(vm);

    // Interpret code in the "main" module
    std.debug.print("\n=== Basic Test ===\n",.{});
    runCode(vm,"main",
        \\ System.print("Hello from Wren!")
        \\ System.print("Testing line 2!")
    );

    // Interpret known-bad code
    std.debug.print("\n=== Have an Error ===\n",.{});
    runCode(vm,"main",
        \\ System.print("Hello from error!)
        \\ System.prit("Ohno!")
    );

    std.debug.print("\n=== Calling Zig from Wren ===\n",.{});
    runCode(vm,"main",
        \\ class Math {
        \\     foreign static add(a, b)
        \\ }
        \\ System.print(Math.add(3,5))
    );

    std.debug.print("\n=== Calling Wren from Zig ===\n",.{});
    runCode(vm,"main",
        \\ class TestClass {
        \\   static doubleUp(num) {
        \\     return num + num
        \\   }
        \\ }
    );

    // Get the method signature handle
    var mhandle:?*wren.Handle = wren.makeCallHandle(vm,"doubleUp(_)");
    defer wren.releaseHandle(vm,mhandle);

    // Get a handle to the class that owns the method
    wren.ensureSlots(vm, 2);
    wren.getVariable(vm, "main", "TestClass", 0);
    var testClass:?*wren.Handle = wren.getSlotHandle(vm, 0);
    defer wren.releaseHandle(vm,testClass);

    // Set up local data
    var needs_adding:usize = 41;
    std.debug.print("Before Call: {}\n",.{needs_adding});

    // Load the slots with the receiver (class) and parameters
    wren.setSlotHandle(vm, 0, testClass);
    wren.setSlotDouble(vm, 1, @intToFloat(f64,needs_adding));
    
    // Call the method 
    var cres:wren.InterpretResult = wren.call(vm,mhandle);
    _=cres;

    needs_adding = @floatToInt(usize,wren.getSlotDouble(vm,0));
    std.debug.print("Call result: {}",.{needs_adding});

    std.debug.print("\n=== Using foreign classes ===\n",.{});
    runCode(vm,"main",
        \\ foreign class Point {
        \\   construct create(size) {}
        \\
        \\   foreign setSize(size)
        \\ }
        \\ var point = Point.create(20)
        \\ point.setSize(40)
        \\ point.setSize(0)
    );

    std.debug.print("\n=== Imports ===\n",.{});
    runCode(vm,"main",
        \\ System.print("start import")
        \\ import "deps/wren/test"
        \\ System.print("end import")
    );

}

pub fn runCode (vm:?*wren.VM,module:[*c]const u8,code:[*c]const u8) void {
    var call_res:wren.InterpretResult = wren.interpret(vm,module,code);
    switch (call_res) {
        wren.RESULT_COMPILE_ERROR => std.debug.print("Compile Error!\n",.{}),
        wren.RESULT_RUNTIME_ERROR => std.debug.print("Runtime Error!\n",.{}),
        wren.RESULT_SUCCESS => std.debug.print("Success!\n",.{}),
        else => unreachable,
    }
}

pub fn writeFn(vm:?*wren.VM, text:[*c]const u8) callconv(.C) void {
    _=vm;
    std.debug.print("{s}",.{text});
}

pub fn errorFn(vm:?*wren.VM, err_type:wren.ErrorType, module:[*c]const u8, line:c_int, msg:[*c]const u8) callconv(.C) void {
    _=vm;
    var err_desc = switch(err_type) {
        wren.ERROR_COMPILE => "Compile Error",
        wren.ERROR_RUNTIME => "Runtime Error",
        wren.ERROR_STACK_TRACE => "Stack Trace",
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

pub fn bindForeignMethodFn(
    vm:?*wren.VM,
    module:[*c]const u8,
    className:[*c]const u8,
    isStatic:bool,
    signature:[*c]const u8
) callconv(.C) wren.ForeignMethodFn {
    _=vm;
    std.debug.print(" [+] Looking up method {s}:{s}.{s}\n",.{module,className,signature});
    if (wren.util.matches(module,"main")) {
        if (wren.util.matches(className,"Math")) {
            if (isStatic and wren.util.matches(signature,"add(_,_)")) {
                std.debug.print(" [+] Found mathAdd\n",.{});
                return mathAdd; // C function for Math.add(_,_).
            }
            // Other foreign methods on Math...
        }
        if (wren.util.matches(className, "Point")) {
            if (!isStatic and wren.util.matches(signature,"setSize(_)")) {
                std.debug.print(" [+] Found setSize\n",.{});
                return Point.setSize;
            }
        }        
    }
    unreachable;
    // Other modules...
}

pub fn bindForeignClassFn (
    vm:?*wren.VM, 
    module:[*c]const u8, 
    className:[*c]const u8
) callconv(.C) wren.ForeignClassMethods {
    std.debug.print(" [+] Foreign start\n",.{});
    _=vm;
    if (wren.util.matches(module, "main")) {
        if (wren.util.matches(className, "Point")) {
            std.debug.print(" [+] Foreign bind\n",.{});
            return .{
                .allocate = pointAllocate,
                .finalize = pointFinalize,
            };
        }
    }
    std.debug.print(" [+] Foreign BIND FAIL\n",.{});
    return .{
        .allocate = null,
        .finalize = null
    };
}

pub fn pointAllocate(vm:?*wren.VM) callconv(.C) void {
    std.debug.print(" [+] ALLOC Point\n",.{});
    var ptr:?*c_void = wren.setSlotNewForeign(vm, 0, 0, @sizeOf(Point));
    var size_param:f64 = wren.getSlotDouble(vm, 1);
    var pt_ptr:*Point = @ptrCast(*Point,@alignCast(@alignOf(*Point),ptr));
    pt_ptr.* = Point { .size = size_param };
    std.debug.print(" [+] ALLOC Point Done\n",.{});
}
pub fn pointFinalize(data:?*c_void) callconv(.C) void {
    _=data;
    std.debug.print(" [+] Finalize Point\n",.{});
    // Do cleanup here
}

pub fn mathAdd (vm:?*wren.VM) callconv(.C) void {
    var a:f64 = wren.getSlotDouble(vm, 1);
    var b:f64 = wren.getSlotDouble(vm, 2);
    wren.setSlotDouble(vm, 0, a + b);
}

pub fn loadModuleFn(vm:?*wren.VM,name:[*c]const u8) callconv(.C) wren.LoadModuleResult {
    _=vm;
    var src = wren.util.loadWrenSourceFile(alloc,std.mem.span(name)) catch unreachable;
    return .{
        .source = src,
        .onComplete = loadModuleCompleteFn,   // ?fn, called on done running to free mem
        .userData = null, // ?*c_void
    };
}

pub fn loadModuleCompleteFn (vm:?*wren.VM,module:[*c]const u8,result:wren.LoadModuleResult) callconv(.C) void {
    _=vm; 
    _=module;
    if(result.source != null) {
        var slice_len = std.mem.sliceTo(result.source,0).len;
        alloc.free(result.source[0..slice_len]);
    }
}
