const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

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

    // Test the optional 'Meta' module
    // Using Meta.eval to interpret Wren source from Wren
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
    // Test the evenness of the random distribution
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
    
}
