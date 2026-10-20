---
Repository: https://github.com/Cysharp/csbindgen
Issue: N/A
Commit: 512344b9756f04356510f322f0c745a7b15de602
Language: Rust
Category: feature-request
Title: Evaluate constant expressions in csbindgen's C# consts and enums
---

# Evaluate constant expressions in csbindgen's C# consts and enums

If you declare a constant or an enum variant's discriminant in Rust with an expression like `1 << 3` or `MASK | 1`, that expression's value will be present in the C# code output by csbindgen. Currently, csbindgen only outputs discriminants and constants that are literals or negative integer literals.

Const initializers and enum discriminants can use unsuffixed and suffixed literals, parens, the unary `-` and `!` operators, all binary operators, `as` casts to and from integral, floating-point, Boolean, and character types, the `MAX` and `MIN` of an integral type, paths to other consts, and paths to fieldless enum variants inside an `as` cast, and these paths can go through `use` imports, including renamed ones and globs over an enum's variants. Const, enum, and type alias names are unique, both within and between input files. Every generated const and enum discriminant fits the C# type csbindgen already uses for it. Declared types are Rust primitives or aliases of Rust primitives, other than `i128`, `u128`, and the C primitives from `std::os::raw`, though values inside an expression can still have type `i128` or `u128`. Enum `repr`s are a fixed-size integer, `C`, or none.

Values behave like Rust values in a 64-bit architecture. Unsuffixed integer and floating-point literals have the type needed in context, including the target type of an `as` cast of the same kind (or `u8` for a cast to `char`) if only parens and unary operators sit between the two, and otherwise default to `i32` and `f64`.

Emit constants and enum discriminants as C# literals of the same type as in the csbindgen output now, with the same value.
