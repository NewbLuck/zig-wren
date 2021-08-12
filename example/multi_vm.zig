const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

// A function we will call from Wren
pub fn mathAddOne (vm:?*wren.VM) void {
    var a:f64 = wren.getSlotAuto(vm, f64, 1);
    var b:f64 = wren.getSlotAuto(vm, f64, 2);
    wren.setSlotDouble(vm, 0, a + b);
}

// A slightly different function we will call from Wren
pub fn mathAddTwo (vm:?*wren.VM) void {
    var a:f64 = wren.getSlotAuto(vm, f64, 1);
    var b:f64 = wren.getSlotAuto(vm, f64, 2);
    wren.setSlotAuto(vm, 0, a + b + b + a);
}

pub fn main() anyerror!void {
    // Initialize the data structures for the wrapper
    wren.init(alloc);
    defer wren.deinit();

    // Set up a VM configuration using the supplied default bindings
    var config:wren.Configuration = undefined;
    wren.util.initDefaultConfig(&config);

    // Create two VMs from our config
    const vm1 = wren.newVM(&config);
    defer wren.freeVM(vm1);
    const vm2 = wren.newVM(&config);
    defer wren.freeVM(vm2);

    // Register methods for "add" to both VMs, but use different fns for each
    // You can use the same if desired, this is just illustrating the fact
    // that there are different registrys for each VM.
    try wren.foreign.registerMethod(vm1,"main","Math","add(_,_)",true,mathAddOne);
    try wren.foreign.registerMethod(vm2,"main","Math","add(_,_)",true,mathAddTwo);

    std.debug.print("=== VM 1 ===\n",.{});    
    try wren.util.run(vm1,"main",
        \\ class Math {
        \\     foreign static add(a, b)
        \\ }
        \\ System.print(Math.add(3,5))
    );

    std.debug.print("=== VM 2 ===\n",.{});    
    try wren.util.run(vm2,"main",
        \\ class Math {
        \\     foreign static add(a, b)
        \\ }
        \\ System.print(Math.add(3,5))
    );
}
