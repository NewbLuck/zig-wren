const std = @import("std");

fn getRelativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}
fn getSrcPath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str ++ "src" ++ std.fs.path.sep_str;
}

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("wren", "src/wren.zig");
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/wren.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
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
    //flagContainer.append("-Wno-return-type-c-linkage") catch unreachable;

    wren.addIncludeDir(path ++ "deps/wren/src/include");
    wren.addCSourceFile(path ++ "deps/wren/build/wren.c", flagContainer.items);

    return wren;
}

pub fn getPackage() std.build.Pkg {
    comptime var path = getSrcPath();
    return .{ .name = "wren", .path = std.build.FileSource{ .path = path ++ "wren.zig" } };
}
