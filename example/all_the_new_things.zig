const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

// This will be a foreign class in Wren
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

// A pair of allocate and finalize functions to keep Wren and Zig in sync
// when using the Point class above.
// Allocate is called on Wren creation and finalize on Wren destruction.
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
    // Do whatever cleanup is needed here
}

// A function we will call from Wren
pub fn mathAdd (vm:?*wren.VM) callconv(.C) void {
    var a:f64 = wren.getSlotDouble(vm, 1);
    var b:f64 = wren.getSlotDouble(vm, 2);
    wren.setSlotDouble(vm, 0, a + b);
}
// A function we will call from Wren
pub fn mathAddSec (vm:?*wren.VM) callconv(.C) void {
    var a:f64 = wren.getSlotDouble(vm, 1);
    var b:f64 = wren.getSlotDouble(vm, 2);
    wren.setSlotDouble(vm, 0, a + b + b + a);
}


pub fn main() anyerror!void {
    // Initialize the data structures for the wrapper
    wren.init(alloc);
    defer wren.deinit();

    // Set up a VM configuration using the supplied default bindings
    var config:wren.Configuration = undefined;
    wren.util.initDefaultConfig(&config);

    // Create a new VM from our config we generated previously
    var vm = wren.newVM(&config);
    defer wren.freeVM(vm);

    // Register our foreign methods
    try wren.foreign.registerMethod(vm,"main","Math","add(_,_)",true,mathAdd);
    try wren.foreign.registerMethod(vm,"main","Point","setSize(_)",false,Point.setSize);

    // Register our foreign class
    try wren.foreign.registerClass(vm,"main","Point",pointAllocate,pointFinalize);

    // Interpret code in the "main" module
    std.debug.print("\n=== Basic Test ===\n",.{});
    try wren.util.run(vm,"main",
        \\ System.print("Hello from Wren!")
        \\ System.print("Testing line 2!")
    );

    // Interpret known-bad code
    std.debug.print("\n=== Have an Error ===\n",.{});
    wren.util.run(vm,"main",
        \\ System.print("Hello from error!)
        \\ System.prit("Ohno!")
    ) catch |err| {
        std.debug.print("THIS IS FINE - {s}\n",.{err});
    };

    // Try calling Zig code from Wren code
    std.debug.print("\n=== Calling Zig from Wren ===\n",.{});
    try wren.util.run(vm,"main",
        \\ class Math {
        \\     foreign static add(a, b)
        \\ }
        \\ System.print(Math.add(3,5))
    );

    // Try calling Wren code from Zig code
    std.debug.print("\n=== Calling Wren from Zig ===\n",.{});
    try wren.util.run(vm,"main",
        \\ class TestClass {
        \\   static doubleUp(num) {
        \\     return num + num
        \\   }
        \\ }
    );

    // Get the method signature handle, cache these for use
    var mhandle:?*wren.Handle = wren.makeCallHandle(vm,"doubleUp(_)");
    defer wren.releaseHandle(vm,mhandle);

    // Get a handle to the class that owns the method, also cache these for use
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
    _=cres; // 0/1/2 = Success/CompileFail/RuntimeFail
    std.debug.print("Return Type: {s}\n",.{wren.util.slotType(vm,0)});

    // Cast the result back to an int
    needs_adding = @floatToInt(usize,wren.getSlotDouble(vm,0));
    std.debug.print("Call result: {}\n",.{needs_adding});

    // Foreign classes in Wren defined in Zig
    std.debug.print("\n=== Using foreign classes ===\n",.{});
    wren.util.run(vm,"main",
        \\ foreign class Point {
        \\   construct create(size) {}
        \\
        \\   foreign setSize(size)
        \\ }
        \\ var point = Point.create(20)
        \\ point.setSize(40)
        \\ point.setSize(0)
    ) catch |err| {
        std.debug.print("THIS IS FINE TOO - {s}\n",.{err});
    };

    // Test importing a separate Wren code file
    std.debug.print("\n=== Imports ===\n",.{});
    try wren.util.run(vm,"main",
        \\ System.print("start import")
        \\ import "example/test"
        \\ System.print("end import")
    );

    // Test the optional 'Meta' module
    std.debug.print("\n=== Meta module ===\n",.{});
    try wren.util.run(vm,"main",
        \\ import "meta" for Meta
        \\
        \\ var a = 2
        \\ var b = 3
        \\ var source = """
        \\   var c = a * b
        \\   System.print(c)
        \\ """
        \\ Meta.eval(source)
    );

    // Test the optional 'Random' module
    std.debug.print("\n=== Random module ===\n",.{});
    try wren.util.run(vm,"main",
        \\ import "random" for Random
        \\ 
        \\ var random = Random.new(12345)
        \\ 
        \\ var below = 0
        \\ for (i in 1..1000) {
        \\   var n = random.int()
        \\   if (n < 2147483648) below = below + 1
        \\ }
        \\ 
        \\ System.print(below > 450) // expect: true
        \\ System.print(below < 550) // expect: true
    );

    // Using additional VMs
    // Create a new-new VM from our old config
    var vm2 = wren.newVM(&config);
    defer wren.freeVM(vm2);

    // Same module, name, and signature, different VM and Zig function
    try wren.foreign.registerMethod(vm2,"main","Math","add(_,_)",true,mathAddSec);

    std.debug.print("\n=== Two VMs with different backing methods ===\n",.{});
    // Original, already defined
    try wren.util.run(vm,"main",
        \\ System.print(Math.add(3,5))
    );

    // New, same Wren def but different Zig binding
    try wren.util.run(vm2,"main",
        \\ class Math {
        \\     foreign static add(a, b)
        \\ }
        \\ System.print(Math.add(3,5))
    );

    std.debug.print("\n=== Examples Done ===\n",.{});
    
    // defer unloads the VMs, this runs finalize on Zig-bound classes
}
