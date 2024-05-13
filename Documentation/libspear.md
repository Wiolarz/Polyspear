
# How to build LibSpear

To build Libspear, simply type the following commands:

```
git submodule init
cd LibSpear
scons
```

After reloading the project the changes should be visible in the editor.

If you want to have autocompletion in your LSP/IDE, you can generate CompileDB (compile_commands.json) with a following command:

```
scons cdb
```

# Cross-compilation

TODO figure out
