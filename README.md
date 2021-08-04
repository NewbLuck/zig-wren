# zig-wren 
A basic wrapper around [Wren](https://wren.io/).

Make sure to pull with --recursive to get Wren as well.
This runs off of the amalgamated Wren source because I was too lazy to add all the C files manually to the build, so run the amalgamation utility as described below first.

https://wren.io/getting-started.html#including-the-code-in-your-project

---

Check `examples/example_build.zig` for an example of how to set up your project's build.zig, and `examples/all_the_things.zig` for sample embedding usage.
Aside from the above, their [embedding guide](https://wren.io/embedding/) has everything else you should need to get started integrating Wren into your Zig project.

---

This is still **VERY MUCH** a WIP, but it works well enough to go through their example code.  I will try to leave the C-style code behind and keep the planned heavier wrap separated.

As a rule, all things in the current wrap that were named `Wren[Thing]` or `wren[Thing]` are now `wren.[Thing]` or `wren.[thing]`, depending on if it was a type or function.
The constants are still screaming snake case, but the leading `WREN_` got chopped off and they are living in the main wren struct.  Check `src/wren.c`, `src/c.zig`, and `src/extern.zig` for structure and signatures.

The optional add-ons for random and meta *should* be included and working, haven't tested them yet so YMMV.

There are a few helpers in wren.utils to make life slightly easier, there will be more to come.
Also planning to Zig-ify the types and provide thicker wrapping to get away from all the C pointers.
