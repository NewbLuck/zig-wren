const std = @import("std");
const wren = @import("wren");

pub var alloc = std.testing.allocator;

// This is basically all the separate example programs squished together into 
// one file so they can be ran all at once. 
// See the other Zig files in example/ for cleaner examples.

// This will be a foreign class in Wren
pub const Point = struct {
    size:f64 = 0,
    pub fn setSize (vm:?*wren.VM) void {
        // Get the Wren class handle which holds our Zig instance memory
        if(wren.getSlotForeign(vm, 0)) |ptr| {
            // Convert slot 0 memory back into the Zig class
            var point = wren.foreign.castDataPtr(Point,ptr);
            // Get the argument
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
// Allocate is called on Wren creation and finalize on Wren destruction.
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

// A function we will call from Wren
pub fn mathAdd (vm:?*wren.VM) void {
    var a:f64 = wren.getSlotAuto(vm, f64, 1);
    var b:f64 = wren.getSlotAuto(vm, f64, 2);
    wren.setSlotDouble(vm, 0, a + b);
}

// A slightly different function we will call from Wren
pub fn mathAddSec (vm:?*wren.VM) void {
    var a:f64 = wren.getSlotAuto(vm, f64, 1);
    var b:f64 = wren.getSlotAuto(vm, f64, 2);
    wren.setSlotAuto(vm, 0, a + b + b + a);
}

fn testBasic (vm:?*wren.VM) !void {
    // Interpret code in the "main" module
    std.debug.print("\n=== Basic Test ===\n",.{});
    try wren.util.run(vm,"main",
        \\ System.print("Hello from Wren!")
        \\ System.print("Testing line 2!")
    );
}

fn testSyntaxError (vm:?*wren.VM) !void {
    // Interpret known-bad code
    std.debug.print("\n=== Have an Error ===\n",.{});
    wren.util.run(vm,"main",
        \\ System.print("Hello from error!)
        \\ System.prit("Ohno!")
    ) catch |err| {
        std.debug.print("THIS IS FINE - {s}\n",.{err});
    };
}

fn testForeign (vm:?*wren.VM) !void {
    // Register our foreign methods
    try wren.foreign.registerMethod(vm,"main","Math","add(_,_)",true,mathAdd);

    // Try calling Zig code from Wren code
    std.debug.print("\n=== Calling Zig from Wren ===\n",.{});
    try wren.util.run(vm,"main",
        \\ class Math {
        \\     foreign static add(a, b)
        \\ }
        \\ System.print(Math.add(3,5))
    );

    // Register our foreign class and method
    try wren.foreign.registerClass(vm,"main","Point",pointAllocate,pointFinalize);
    try wren.foreign.registerMethod(vm,"main","Point","setSize(_)",false,Point.setSize);
    
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
}

fn testValuePassing (vm:?*wren.VM) !void {
    // Try calling Wren code from Zig code
    std.debug.print("\n=== Calling Wren from Zig ===\n",.{});
    try wren.util.run(vm,"main",
        \\ class TestClass {
        \\   static doubleUp(num) {
        \\     return num + num
        \\   }
        \\   static text(txt) {
        \\     return txt + "return"
        \\   }
        \\   static splat(val,count) {
        \\     return [val] * count 
        \\   }
        \\   static addArray(arr) {
        \\     return arr[0] + arr[1] 
        \\   }
        \\   static addStr(str1,str2) {
        \\     return [str1,str2] 
        \\   }
        \\   static fArr(flot,inte) {
        \\     return [flot] * inte 
        \\   }
        \\   static notMe(iambool) {
        \\     return !iambool 
        \\   }
        \\   static blah(farr) {
        \\     return farr + farr 
        \\   }
        \\   static tup(vtup,vint) {
        \\     return vtup[1] + vint
        \\   }
        \\   static fmap(imap) {
        \\     imap["Add1"] = "Wren"
        \\     imap["Add2"] = "Wren"
        \\     return imap
        \\   }
        \\ }
    );

    var needs_adding:usize = 41;
    std.debug.print("Before Call: {}\n",.{needs_adding});
    
    // (module, class, method sig, arg types tuple, return type)
    var wm = try wren.MethodCallHandle("main","TestClass","doubleUp(_)",.{usize},usize).init(vm);
    defer wm.deinit();
    needs_adding = try wm.callMethod(.{needs_adding});
    std.debug.print("Int->Int: {}\n",.{needs_adding});

    var wm2 = try wren.MethodCallHandle("main","TestClass","text(_)",.{[]const u8},[]const u8).init(vm);
    defer wm2.deinit();
    var ostr = try wm2.callMethod(.{"Input "});
    std.debug.print("String->String: {s}\n",.{ostr});

    var wm3 = try wren.MethodCallHandle("main","TestClass","splat(_,_)",.{i32,i32},[]i32).init(vm);
    defer wm3.deinit();
    var oslc = try wm3.callMethod(.{3,5});
    std.debug.print("IntArray->Slice: {any}\n",.{oslc});

    var wm4 = try wren.MethodCallHandle("main","TestClass","addArray(_)",.{[]u32},i32).init(vm);
    defer wm4.deinit();
    var oarr = try wm4.callMethod(.{ .{3,5} });
    std.debug.print("IntSlice->Int: {any}\n",.{oarr});

    var wm5 = try wren.MethodCallHandle("main","TestClass","addStr(_,_)",.{[]const u8,[]const u8},[]const []const u8).init(vm);
    defer wm5.deinit();
    var oast = try wm5.callMethod(.{"abc","def"});
    std.debug.print("String->StringSlice: {s}\n",.{oast});

    var wm6 = try wren.MethodCallHandle("main","TestClass","fArr(_,_)",.{f32,i32},[]f32).init(vm);
    defer wm6.deinit();
    var ofsp = try wm6.callMethod(.{2.34,5});
    std.debug.print("Float,Int->FloatSlice: {any}\n",.{ofsp});

    var wm7 = try wren.MethodCallHandle("main","TestClass","notMe(_)",.{bool},bool).init(vm);
    defer wm7.deinit();
    var oboo = try wm7.callMethod(.{false});
    std.debug.print("Bool->Bool: {any}\n",.{oboo});

    var wm8 = try wren.MethodCallHandle("main","TestClass","blah(_)",.{[]f32},[]f32).init(vm);
    defer wm8.deinit();
    var obla = try wm8.callMethod(.{ .{2.34,2.34} });
    std.debug.print("FloatSlice->FloatSlice: {any}\n",.{obla});

    var wm9 = try wren.MethodCallHandle("main","TestClass","tup(_,_)",.{ std.meta.Tuple(&[_]type{[]const u8,i32}),i32 },i32).init(vm);
    defer wm9.deinit();
    var otup = try wm9.callMethod(.{ .{"poo",3}, 39 });
    std.debug.print("Str,Int Tuple->Int: {any}\n",.{otup});

    var wm10 = try wren.MethodCallHandle("main","TestClass","fmap(_)",.{ std.StringHashMap([]const u8) },std.StringHashMap([]const u8)).init(vm);
    defer wm10.deinit();
    var nmap = std.StringHashMap([]const u8).init(std.testing.allocator);
    defer nmap.deinit();
    nmap.put("Init1","Zig") catch unreachable;
    nmap.put("Init2","Zig") catch unreachable;
    var omap = try wm10.callMethod(.{ nmap });
    std.debug.print("SMap->Map: \n",.{});
    var it = omap.iterator();
    while(it.next()) |entry| {
        std.debug.print("  >> {s}: {s}\n",.{entry.key_ptr.*,entry.value_ptr.*});
    }

}

fn testImports (vm:?*wren.VM) !void {
    // Test importing a separate Wren code file
    std.debug.print("\n=== Imports ===\n",.{});
    try wren.util.run(vm,"main",
        \\ System.print("start import")
        \\ import "example/test"
        \\ System.print("end import")
    );
}

fn testOptionalModules (vm:?*wren.VM) !void {
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
}

fn testMultiVm (vm:?*wren.VM) !void {
    // Using additional VMs
    var config:wren.Configuration = undefined;
    wren.util.initDefaultConfig(&config);
    
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
}

pub fn main() anyerror!void {
    std.debug.print("Version Major: {}\n",.{wren.version.major});
    std.debug.print("Version Minor: {}\n",.{wren.version.minor});
    std.debug.print("Version Patch: {}\n",.{wren.version.patch});
    std.debug.print("Version String: {s}\n",.{wren.version.string});
    std.debug.print("Version Number: {d}\n",.{wren.version.number});

    // Initialize the data structures for the wrapper
    wren.init(alloc);
    defer wren.deinit();

    // Set up a VM configuration using the supplied default bindings
    var config = wren.util.defaultConfig();

    // Create a new VM from our config we generated previously
    const vm = wren.newVM(&config);
    defer wren.freeVM(vm);

    // Run all of our examples
    std.debug.print("\n>>>>>> Starting Examples <<<<<<\n",.{});
    try testBasic(vm);
    try testSyntaxError(vm);
    try testForeign(vm);
    try testValuePassing(vm);
    try testImports(vm);
    try testOptionalModules(vm);
    try testMultiVm(vm);
    std.debug.print("\n>>>>>> Examples Done <<<<<<\n",.{});
    
    // deferred wren.deinit unloads the VMs, 
    // this runs finalize on Zig-bound classes
}
