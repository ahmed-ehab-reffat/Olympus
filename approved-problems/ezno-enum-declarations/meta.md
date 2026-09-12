---
Repository: https://github.com/kaleidawave/ezno
Language: Rust
Issue: none (original feature request)
Commit: 8a763a0a1e92317b4822a9ea1cfaaf150b036f12
Title: Check enum declarations in the type checker
---

# Check enum declarations in the type checker

Check `enum` declarations as TypeScript does. A declaration introduces a value and a type under its name. A member with no initialiser takes the one before it plus one, and zero when first, so an explicit value moves the rest. An initialiser is a number, a string, a reference to a member already declared, on its own or as `Other.Member`, carrying whatever that member holds, or a constant expression over numbers built from arithmetic, bitwise, shift and unary operators and parentheses. Anything else leaves it without a value. An initialiser is only read for its value, never checked as an ordinary expression. Infinities and `NaN` are ordinary member values. A member with no initialiser after one holding no number is `Enum member must have initializer` and gets none. A repeated name is `Duplicate enum member 'A'` and the first keeps its value.

The value carries every member under its name, and one holding a number under that number, giving back its name. Strings are not reachable that way, and of two members sharing a number the later owns it. Neither a member nor its entry can be written to, which is `Cannot assign to 'A' because it is a read-only property`, or removed, which is `The operand of a 'delete' operator cannot be a read-only property`.

The type of a member is that member alone: assignable to the value it holds, its own declaration and `number` or `string`, while a member of another never is, whatever the values. A number is assignable to a declaration when one of its members holds it, and any number when a member has no value or it is empty. A number reaches a member's own type when that member holds it, and the `number` type itself reaches a declaration holding a numeric member or holding none, and a member type holding a number. No string is ever assignable to either, nor anything but a number. A member can be named `E.A` in an annotation. Comparing a value of the type against a member or a number narrows it to that value; narrowing never loses the declaration type. A declaration prints as its name, a member as `E.A` and the value as `typeof E`.

A `const enum` declares no value: a member is read by its name or a string literal, any other index access is `A const enum member can only be accessed using a string literal`, and naming it elsewhere is `'const' enums can only be used in property or index access expressions`. Its members must be constant, otherwise `const enum member initializers must be constant expressions`. Members of a `declare enum` with no initialiser have no value, not an error. A declaration can be exported. A later declaration of the same name adds to it, counting restarts from zero in each, while one that mixes `const` with an ordinary declaration is `Enum declarations can only merge with declarations of the same kind`.
