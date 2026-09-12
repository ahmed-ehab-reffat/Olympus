Title: Add eager JAX-to-Dr.Jit automatic differentiation

Implement the missing `drjit.wrap(source="jax", target="drjit")` direction. A decorated function is called from JAX, receives Dr.Jit values, and returns values to JAX. Both string and module forms of the `source` and `target` arguments must work.

Support eager primal evaluation and first-order differentiation in both JAX directions. `jax.jvp` must propagate input tangents through Dr.Jit forward-mode AD, while `jax.vjp` and `jax.grad` must propagate output cotangents through Dr.Jit reverse-mode AD. Multi-input and multi-output functions must use every applicable tangent or cotangent, and an input that does not affect the selected output must receive a zero cotangent.

Preserve positional and keyword arguments and nested combinations of lists, tuples, and dictionaries on input and output. Floating-point array dtypes and shapes must survive the round trip. Supported signed integer array dtypes and values must also survive without narrowing. Python integer and floating-point values may cross the boundary: floating-point scalars follow ordinary JAX differentiation semantics, while Python integers and signed integer arrays are non-differentiable and produce JAX `float0` tangents in `jax.jvp`. These values must not disrupt differentiation of floating-point leaves. Outputs may mix differentiable arrays, non-differentiable arrays, and numeric constants.

Honor broadcasting supported by both frameworks, including reducing a broadcast output cotangent to the original input shape. Repeated eager calls, including calls with different shapes, must keep derivative state independent.

Support eager `jax.vmap` composition. Mapped array leaves may use any valid integer input axis, and mapped and unmapped leaves may be mixed across nested PyTrees. Structured outputs and their requested output axes must be preserved. First-order `jax.jvp`, `jax.vjp`, and `jax.grad` must continue to work when composed inside or outside `jax.vmap`, with derivative state isolated between batch elements. Zero-sized mapped axes must return correctly shaped empty outputs.

JAX staging with `jax.jit`, higher-order differentiation, and boolean tensor exchange are outside this task.
