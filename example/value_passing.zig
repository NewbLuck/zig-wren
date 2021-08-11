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

    // Passing and returning a slew of different data types.
    // Values will be casted as appropriate.
    // Use a span for single-typed lists in wren, a tuple for
    // passing Wren a multi-typed list, and either an AutoHashMap or
    // StringHashMap for a map, depending on the key type.
    // Does not support returned multi-typed lists yet, not sure how to
    // fill in a pre-defined tuple at runtime.
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

    // Yes, this is ugly :)

    var needs_adding:usize = 41;
    std.debug.print("Before Call: {}\n",.{needs_adding});
    
    // This defines a method call handle to call Wren methods from Zig.
    // Pass the module/class/method sig, then argument type tuple, followed by return type.
    // .init() takes the vm handle to the vm that this will be running on.
    // To call the method, run [methHand].callMethod, passing in a tuple of the argument values.
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
