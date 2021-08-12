const std = @import("std");
const deps = @import("./deps.zig");

const ExampleBuild = struct {
    label:[]const u8,
    file:[]const u8,
    exe:*std.build.LibExeObjStep,
};

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const example_defs = &[_][2][]const u8 {
        [_][]const u8{ "everything","example/everything.zig" },
        [_][]const u8{ "basic","example/basic.zig" },
        [_][]const u8{ "syntax_error","example/syntax_error.zig" },
        [_][]const u8{ "imports","example/imports.zig" },
        [_][]const u8{ "foreign_method","example/foreign_method.zig" },
        [_][]const u8{ "foreign_class","example/foreign_class.zig" },
        [_][]const u8{ "value_passing","example/value_passing.zig" },
        [_][]const u8{ "meta_random","example/meta_random.zig" },
        [_][]const u8{ "multi_vm","example/multi_vm.zig" },
    };

    var examples:[example_defs.len]ExampleBuild = undefined;
    for (example_defs) |example,i| {
        examples[i] = ExampleBuild {
            .label = example[0],
            .file = example[1],
            .exe = b.addExecutable(example[0],example[1]),
        };
        examples[i].exe.setBuildMode(mode);
        deps.addAllTo(examples[i].exe);
        const run_cmd = examples[i].exe.run();
        const exe_step = b.step(examples[i].label, b.fmt("run {s}.zig", .{examples[i].label}));
        exe_step.dependOn(&run_cmd.step);
    }
    
    // Provide the first entry for "run" 
    const exe = b.addExecutable("run",examples[0].file);
    exe.setBuildMode(mode);
    deps.addAllTo(exe);
    const run_cmd = exe.run();
    const exe_step = b.step("run", b.fmt("run {s}.zig", .{"run"}));
    exe_step.dependOn(&run_cmd.step);
}
