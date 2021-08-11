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

    // This code has some issues, and Wren knows it!
    // The default runner will output a stack trace to stdout, and
    // the returned error will be of type wren.ErrType
    std.debug.print("\n=== Have an Error ===\n",.{});
    wren.util.run(vm,"main",
        \\ System.print("Hello from error!)
        \\ System.prit("Ohno!")
    ) catch |err| {
        std.debug.print("THIS IS FINE - {s}\n",.{err});
    };

}
