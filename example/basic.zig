const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

pub fn main() anyerror!void {
    // Initialize the data structures for the wrapper
    wren.init(alloc);
    defer wren.deinit();

    // Set up a VM configuration using the supplied default bindings
    // To change specific ones, you can override the bindings
    // after calling initDefaultConfig.
    var config:wren.Configuration = undefined;
    wren.util.initDefaultConfig(&config);

    // Create a new VM from our config we generated previously
    const vm = wren.newVM(&config);
    defer wren.freeVM(vm);

    // Run some basic Wren code
    try wren.util.run(vm,"main",
        \\ System.print("Hello from Wren!")
        \\ System.print("Testing line 2!")
        \\ System.print("Bytes: \x48\x69\x2e")
        \\ System.print("Interpolation: 3 + 4 = %(3 + 4)!")
        \\ System.print("Complex interpolation: %((1..3).map {|n| n * n}.join())")
    );
    
    // A simple way of running a static Wren file using @embedFile
    try wren.util.run(vm,"main",@embedFile("test.wren"));
    
}
