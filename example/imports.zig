const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

pub fn main() anyerror!void {
    // Initialize the data structures for the wrapper
    wren.init(alloc);
    defer wren.deinit();

    // Set up a VM configuration using the supplied default bindings
    var config:wren.Configuration = undefined;
    wren.util.initDefaultConfig(&config);

    // Create a new VM from our config we generated previously
    const vm = wren.newVM(&config);
    defer wren.freeVM(vm);

    // Import a separate Wren code file from Wren
    // The importer fn is defined in the configuration, the default
    // appends ".wren" to the desired import. 
    std.debug.print("\n=== Imports ===\n",.{});
    try wren.util.run(vm,"main",
        \\ System.print("start import")
        \\ import "example/test"
        \\ System.print("end import")
    );
    
}
