# zig-wren <img align="right" src="zig-wren.png">

A basic wrapper around [Wren](https://wren.io/).

This is still a WIP.  Currently it provides a low-to-mid-level wrap around the Wren bindings, as well as exposes the C api directly for advanced usage.

Note: The optional add-ons for random and meta are included and working (from limited testing).

---

**Thanks to [@nektro](https://github.com/nektro) for providing the zigmod integration!**

---

## Adding to your project with zigmod

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

---

## Usage

Add this import to the top of whatever source file you will use it in:
```zig
const wren = @import("wren");
```
and you are ready to go!

Check `examples/all_the_new_things.zig` for usage (kind of messy).  Almost every feature is implemented in that file.  

There is also `examples/all_the_old_things.zig` which is the original implementation, it shows how to use it in a lower-level manner, or what to do if you need custom callbacks
for any of the Wren externals.  

Aside from the above files, Wren's [embedding guide](https://wren.io/embedding/) has everything else you should need to get started integrating Wren into your Zig project.
