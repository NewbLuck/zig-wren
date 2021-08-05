// Import this file into your main project build and call "link" on your exe 
// if you prefer to not use a package manager.
// You must manually pull wren master into ./deps/wren, relative to this file.
// By default this uses the individual source files, see comments below to
// switch to the amalgamated source

const std = @import("std");

fn getRelativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

fn getSrcPath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str ++ "src" ++ std.fs.path.sep_str;
}

pub fn link(b: *std.build.Builder, exe: *std.build.LibExeObjStep, target: std.build.Target) void {
    // Link step
    exe.linkLibrary(getLib(b, target));
    exe.addPackage(getPackage());
}

pub fn getLib(b: *std.build.Builder, target: std.build.Target) *std.build.LibExeObjStep {
    _=target;
    comptime var path = getRelativePath();

    var wren = b.addStaticLibrary("wren", null);

    wren.linkLibC();

    var flagContainer = std.ArrayList([]const u8).init(std.heap.page_allocator);
    if (b.is_release) flagContainer.append("-Os") catch unreachable;

    wren.addIncludeDir(path ++ "deps/wren/src/include");
    
    // Uncomment this line and comment the block below to use 
    // the amalgamated source instead of separate source files
    // wren.addCSourceFile(path ++ "deps/wren/build/wren.c", flagContainer.items);

    {
        wren.addIncludeDir(path ++ "deps/wren/src/include");
        wren.addIncludeDir(path ++ "deps/wren/src/vm");
        wren.addIncludeDir(path ++ "deps/wren/src/optional");
        wren.addCSourceFile(path ++ "deps/wren/src/vm/wren_compiler.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/vm/wren_core.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/vm/wren_debug.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/vm/wren_primitive.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/vm/wren_utils.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/vm/wren_value.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/vm/wren_vm.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/optional/wren_opt_meta.c",flagContainer.items);
        wren.addCSourceFile(path ++ "deps/wren/src/optional/wren_opt_random.c",flagContainer.items);
    }

    return wren;
}

pub fn getPackage() std.build.Pkg {
    comptime var path = getSrcPath();
    return .{ .name = "wren", .path = std.build.FileSource{ .path = path ++ "wren.zig" } };
}