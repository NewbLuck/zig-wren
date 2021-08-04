# zig-wren 
A basic wrapper around Wren.

Make sure to pull with --recursive to get Wren as well.
This runs off of the amalgamated of the Wren source because I was too lazy to add all the C files manually to the build, so run the amalgamation utility as described below first.

https://wren.io/getting-started.html#including-the-code-in-your-project

---

Check examples/example_build.zig for an example of how to set up your project's build.zig, and examples/all_the_things.zig for usage.

---

Still needs to be majorly cleaned up, but it works well enough to go through all their examples.

As a rule, all things that were named Wren[Thing] or wren[Thing] are now wren.[thing].  

The optional add-ons for random and meta /should/ be included and working, haven't tested them yet so YMMV.

There are a few helpers in wren.utils to make life slightly easier, there will be more to come.
Also planning to Zig-ify the types and provide thicker wrapping to get away from all the C pointers.
