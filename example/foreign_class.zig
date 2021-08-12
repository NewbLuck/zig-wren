const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

// This will be a foreign class in Wren
pub const Point = struct {
    size:f64 = 0,
    pub fn setSize (vm:?*wren.VM) void {
        // Get the Wren class handle which holds our Zig instance memory
        if(wren.getSlotForeign(vm, 0)) |ptr| {
            // Convert slot 0 memory back into the Zig class
            var point = wren.foreign.castDataPtr(Point,ptr);
            // Get the constructor argument
            var nsize:f64 = wren.getSlotAuto(vm,f64,1);
            std.debug.print(" [+] Setting point to: {d}\n",.{nsize});
            // Error checking
            if(nsize < 1.0) {
                // Error handling, put error msg back in slot 0 and abort the fiber
                wren.setSlotAuto(vm,0,"That is way too small!");
                wren.abortFiber(vm, 0);
                return;
            }
            // Otherwise set the value
            point.*.size = nsize;
            std.debug.print(" [+] Point is now: {d}\n",.{nsize});
        }
    }
};

// A pair of allocate and finalize functions to keep Wren and Zig in sync
// when using the Point class above.
// Allocate is called on Wren class creation and finalize on Wren destruction.
pub fn pointAllocate(vm:?*wren.VM) void {
    std.debug.print(" [+] ALLOC Point\n",.{});
    
    // Tell Wren how many bytes we need for the Zig class instance
    var ptr:?*c_void = wren.setSlotNewForeign(vm, 0, 0, @sizeOf(Point));
    
    // Get the parameter given to the class constructor in Wren
    var size_param:f64 = wren.getSlotAuto(vm, f64, 1);
    
    // Get a typed pointer to the Wren-allocated 
    var pt_ptr = wren.foreign.castDataPtr(Point, ptr);
    
    // Create the Zig class instance into the Wren memory location,
    // applying the passed value to keep them in sync
    pt_ptr.* = Point { .size = size_param };
    
    std.debug.print(" [+] ALLOC Point Done\n",.{});
}
pub fn pointFinalize(data:?*c_void) void {
    _=data;
    std.debug.print(" [+] Finalize Point\n",.{});
    // Do whatever cleanup is needed here, deinits etc
}


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

    // Register our foreign class, defining the createion and destruction fns
    try wren.foreign.registerClass(vm,"main","Point",pointAllocate,pointFinalize);
    // Register our method, see example/foreign_method.zig
    try wren.foreign.registerMethod(vm,"main","Point","setSize(_)",false,Point.setSize);
    
    // Note that in this case, the class is defined as foreign like how
    // we can define methods as foreign.  When this class is instantiated
    // in Wren, the VM calls the function we defined so that Zig can
    // build it's copy of the data structure.
    // When the VM destructs the class, the finalize fn is called so Zig
    // can free memory, or whatever else needs to happen.
    // We intentionally cause an error in the last setSize call.    
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
    
}
