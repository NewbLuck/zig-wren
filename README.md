# zig-wren 

A basic wrapper around [Wren](https://wren.io/).
This is still **VERY MUCH** a WIP, it's not much more than an implementation and renaming at the moment.
This will eventually get an optional Zigification, I will try to leave the C-style code to prevent breaking changes.

Note: The optional add-ons for random and meta *should* be included and working, haven't tested them yet so YMMV.

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

Check `examples/all_the_things.zig` for usage (kind of messy as it is my current figure-stuff-out scratchpad).  Almost every feature is implemented in that file.
Aside from the above, Wren's [embedding guide](https://wren.io/embedding/) has everything else you should need to get started integrating Wren into your Zig project.

Everything has been tucked into the main wren struct.  As a rule of thumb, replace the initial `wren`, `Wren`, or `WREN_` in the standard library names with `wren.` to access them.

There are a few helpers in wren.utils to make life slightly easier, there will be more to come.
Also planning to Zig-ify the types and provide thicker wrapping to get away from all the C pointers.
