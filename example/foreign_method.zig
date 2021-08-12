const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

// A function we will call from Wren
pub fn mathAdd (vm:?*wren.VM) void {
    var a:f64 = wren.getSlotAuto(vm, f64, 1);
    var b:f64 = wren.getSlotAuto(vm, f64, 2);
    wren.setSlotAuto(vm, 0, a + b);
}

pub fn main() anyerror!void {
    // Initialize the data structures for the wrapper
    wren.init(alloc);
    defer wren.deinit();

    // Set up a VM configuration using the supplied default bindings
    // You can override the bindings after calling this to change them
    var config = wren.util.defaultConfig();

    // Create a new VM from our config we generated previously
    const vm = wren.newVM(&config);
    defer wren.freeVM(vm);

    // Register our foreign method to the Math class
    try wren.foreign.registerMethod(vm,"main","Math","add(_,_)",true,mathAdd);

    // Note how we define the "add" method in Wren as foreign, that
    // will tell Wren that we want to run a host function instead.
    // The method signature must match the one used in the registerMethod call.
    // See https://wren.io/method-calls.html#signature for more info.
    try wren.util.run(vm,"main",
        \\ class Math {
        \\     foreign static add(a, b)
        \\ }
        \\ System.print(Math.add(3,5))
    );
    
}
