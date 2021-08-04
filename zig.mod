id: qsilhsif195wu43wxzu7bl8w13aczkytyitil95gxcv61y17
name: wren
main: src/wren.zig
description: Light Zig wrapper around the Wren scripting language.
dependencies:
  - src: git https://github.com/wren-lang/wren
    id: 3elkc7kyiezkr2jjs7fqqbsf3606zf7wq5nj2yj3z2ofsm6m
    license: MIT
    description: The Wren Programming Language.
    c_include_dirs:
      - src/include
      - src/vm
      - src/optional
    c_source_files:
      - src/vm/wren_compiler.c
      - src/vm/wren_core.c
      - src/vm/wren_debug.c
      - src/vm/wren_primitive.c
      - src/vm/wren_utils.c
      - src/vm/wren_value.c
      - src/vm/wren_vm.c
      - src/optional/wren_opt_meta.c
      - src/optional/wren_opt_random.c
