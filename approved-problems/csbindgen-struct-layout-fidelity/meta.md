---
Repository: https://github.com/Cysharp/csbindgen
Issue: N/A
Commit: 512344b9756f04356510f322f0c745a7b15de602
Language: Rust
Category: feature-request
Title: Add layout-faithful struct emission to csbindgen's C# output
---

# Add layout-faithful struct emission to csbindgen's C# output

Add layout-faithful struct emission to csbindgen, so every struct and union it writes to C# has the size and field offsets of the Rust type it came from.

Compute layouts with Rust's `repr(C)` rules on a 64-bit target. Pointers, function pointers, `usize`, `isize`, `c_long` and `c_ulong` take 8 bytes, `c_float` takes 4 and `c_double` 8. An enum takes the size of its `repr` integer, 4 bytes for `repr(C)`. Enums with a `usize` or `isize` `repr` get a `ulong` or `long` C# base, and 128-bit ones are not emitted. `packed(N)` caps the alignment of every field at N, with plain `packed` meaning 1, and `align(N)` raises the alignment of the type. Type aliases are followed wherever a type appears, including inside arrays. An array length is an integer literal. bindgen's bitfield storage `__BindgenBitfieldUnit<[u8; N]>` is those N bytes. An `Option` takes its payload's size only when the payload is a function pointer, `NonNull`, `Box` or `NonZero` integer type. Any other `Option`, an array with any other length, a skipped enum, or an enum or struct without `repr` has no fixed layout, so a struct holding one is emitted as it is today. A union is laid out the same with or without `repr`. In C#, a raw pointer to an array points to the array's innermost element type, and a raw pointer to `()` is `void*`.

An array whose innermost element is a type C# allows in a fixed buffer, including a niche `Option` whose payload is such a type, becomes one `fixed` buffer holding every element in row-major order, so `[[f32; 4]; 4]` becomes `fixed float name[16]`. Any other array becomes one field per innermost element, named after the field with `_0`, `_1` and so on appended, in the same row-major order. A field whose Rust size is zero (`()`, `PhantomData`, a zero-length array, a zero-size struct) produces no field, but its alignment still counts.

Then give each struct the plainest C# layout that matches Rust. A packed struct gets `[StructLayout(LayoutKind.Sequential, Pack = N)]`. If C#'s sequential layout of the emitted fields still differs from Rust in any field offset or in the total size, the struct gets `[StructLayout(LayoutKind.Explicit, Size = S)]` with S the Rust size and a `[FieldOffset]` on every emitted field. A union gets `Size = S` only when its Rust size differs from C#'s, and every union field, including each array element field, sits at its Rust offset. Every other struct keeps today's attribute, and a struct whose Rust size is zero is emitted exactly as it is today, fields included, even when packed.

On the C# side, `Int128` and `UInt128` take 16 bytes but only 8-byte alignment, while Rust aligns `i128` and `u128` to 16. When a struct contains another struct, use the layout .NET gives the emitted C# type: any C# struct, sequential or explicit, is aligned to the largest alignment among its emitted fields, capped at N under `Pack = N`.
