# zig-wren 
A basic wrapper around Wren.

Make sure to pull with --recursive to get Wren as well.
This runs off of the amalgamation of the Wren source, so run the utility as described below first.

https://wren.io/getting-started.html#including-the-code-in-your-project

---

Check examples/example_build.zig for how to set up your project's build.zig, and examples/all_the_things.zig for usage.

---

As a rule, all things that were named Wren[Thing] or wren[Thing] are now wren.[thing].  
Still needs to be majorly cleaned up.

There are a few helpers in wren.utils to do things.
