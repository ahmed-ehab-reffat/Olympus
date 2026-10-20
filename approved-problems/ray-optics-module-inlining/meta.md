---
Repository: https://github.com/ricktu288/ray-optics
Issue: N/A
Commit: daf76772c73a85e1a2568c4e2e71613bba1fab77
Language: JavaScript
Category: feature-request
Title: Add module inlining and parameter renaming to scenes
---

# Add module inlining and parameter renaming to scenes

If one module places an instance of a second module in its definition and we delete the second module, the first one breaks, and there is also no way to rename a module parameter inside its templates. Objects in the scene no longer have the same module connections when using the current `Scene.removeModule` method. Objects not in the scene but placed in other modules' definitions still have connections to removed modules.

`removeModule(name)` removes all references to the named module from scene objects and replaces all other references to the named module in other module definitions with adapted rows from the named module, rewritten in terms of their containing module. A new function, `inlineModuleInstance(moduleName, index)`, replaces the single module instance at `index` in the `objs` list of the named module with adapted rows from the module it instantiates, rewritten in terms of the containing module, and keeps that instantiated module. A new function, `renameModuleParam(moduleName, oldName, newName)`, changes the name of a parameter and of all values specified for that parameter in the named module's definition and in every instance of that module.

All return true when they succeed. After a successful execution of any of these functions, every instance in the scene expands to the same objects as before the function call, and the values of all equations in the scene are the same as before the function call. This includes expressions that multiply terms by writing them next to each other, such as `2 pi r` or `i r`. The ordering of objects in the scene may differ from the ordering before the function call after a successful execution of any of these functions. An unsuccessful execution of any of these functions returns false, and the scene is unchanged.

Inlining will not occur if any loop bounds for rows to be inlined include loop variables from the surrounding row or if any symbols are used in the inlined module but not defined in that module and defined in the surrounding row or module. Renaming will not occur if the new symbol name is not a simple symbol name or is `random` or a control point name such as `x_1` or is already used in the current module.

You may assume that definitions do not use the `random` function, that no module defines the same name twice, that a module's variables, functions and control points are not used as its loop variables, that a module's functions do not use any of its loop variables, apart from arguments with the same name, and that each instance either gives all of its parameters, as numbers or surrounded by single backticks, or gives none. Names can still repeat between different modules, a loop variable can have the same name as a parameter of its own module, and a function argument can have the same name as any other variable.
