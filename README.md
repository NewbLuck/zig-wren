# zig-wren <img align="right" src="zig-wren.png">

A wrapper around [Wren](https://wren.io/).

It provides a mid-level wrap around the Wren bindings, as well as exposes the C api directly for advanced usage.  

This supports multiple concurrent VMs, as well as passing all Wren data types to and from Zig (including maps and lists).  
The only exception to this is receiving to Zig a multi-typed list from Wren due to the way tuples work in Zig, I am not big brain enough to figure it out.

This uses the Wren-supplied allocators, I plan to eventually add support for custom allocators.

The optional add-ons for random and meta are included and working fine (from limited testing).

## Adding to your project with zigmod  
(**Thanks to [@nektro](https://github.com/nektro) for providing the zigmod integration!**)

Add this into your main project's zig.mod file:
```yml
dependencies:
  - src: git https://github.com/NewbLuck/zig-wren
```
then
```
zigmod fetch
```
to pull the required files and generate the deps file.

## Adding to your project manually

You will have to first manually pull Wren master into the deps directory:
```
mkdir deps
cd deps
git clone https://github.com/wren-lang/wren
```
then in your main project's build.zig:
```zig
const wrenBuild = @import("deps/zig-wren/lib.zig");
...
wrenBuild.link(b, exe, target);
```

See example/example_build.zig for details.

## Usage

Very basic usage example:
```zig
const std = @import("std");
const wren = @import("wren");

pub fn main() !void {
    wren.init(std.heap.c_allocator);
    defer wren.deinit();
    
    var config = wren.util.defaultConfig();
    const vm = wren.newVM(&config);
    defer wren.freeVM(vm);
    
    try wren.util.run(vm,"main",
        \\ System.print("Hello from Wren!")
    );
}
```

There are lots of other examples in the `example/` directory that cover most use cases. 

The example file `everything.zig` is all the separate examples squished into one file, it doesn't have anything new.

There is also `all_the_old_things.zig` which is based on the C-style implementation, it shows how to use it in a lower-level manner, or what to do if you need custom callbacks for any of the Wren externals.  

Aside from the above files, Wren's [embedding guide](https://wren.io/embedding/) has everything else you need for any topics not covered by the examples.
