---
Repository: https://github.com/python-control/python-control
Issue: N/A
Commit: 75a658b6f731785dfdebedadcb06dad522ec63e3
Language: Python
Title: Add analysis points and loop transfer analysis to interconnected systems
---

# Add analysis points and loop transfer analysis to interconnected systems

`interconnect` gains an `analysis_points` keyword naming places loops can later break. Each entry names a subsystem signal in the connection forms `interconnect` accepts, without a gain; one matching both is taken as the output.

A lone specification or list names each point after its signal's base name, a dictionary maps chosen names, and a point covers every channel named. `analysis_point_labels` lists them in declaration order; `find_analysis_point` returns a point's kind, `'output'` or `'input'`, with its positions among the stacked signals of that kind, or None. An input point counts from the first subsystem input, not from anywhere in the outputs.

A generated name joins subsystem and point or channel with the hierarchical state name delimiter, not the dot. Only names the library generates are built that way; a declared point takes its signal's base name, or the one its dictionary key gives, never a prefixed form. A subsystem contributes its own points under such names, each still on the signal it named, not the subsystem's port. Contributed points follow declared ones in subsystem order and serve anywhere they do.

Points at different signals are different locations. Only a name repeated in one call, or two names opening one channel, is an error.

`analysis_point(name, size=1)`, a static unit gain named `name` carrying it on both sides of `size` channels, any timebase, contributes a point called `name` alone, never prefixed by the block. Under implicit connection it is the only source others draw from, never itself.

Declaring points changes nothing else: inputs, outputs, states, labels and dynamics stay put, and the string form lists each point with its signal.

`open_loop(sys, points=None, name=None)` breaks the named loops, defaulting to all. At a subsystem output it removes every internal connection fed by it, drives each destination from a new injection through the gain it carried, and reports the signal on a new measurement.

At a subsystem input it removes only that input's feeds, drives it from the injection, and measures the internal sum that would have fed it, leaving what an interconnection input adds. Connections to an interconnection output are left alone; unbroken loops stay closed.

Injections follow the inputs of `sys`, measurements its outputs, one per channel in the order listed, labelled `p_inj` and `p_meas` for point `p`, bracketing the channel number when several. A specification used in place of a name ends its channels the same way, on a leading part of the implementation's choosing.

A broken point is no longer listed: opening a location retires the point declared there however that location was named, and closing gives the name back. `close_loop(sys, points=None, name=None)` reconnects each injection to its measurement, drops both channels and redeclares it; opening every point at once, contributed included, and closing them all restores the system.

`loop_transfer(sys, points=None, openings=None, name=None)` runs from those injections to those measurements with `sys` inputs at zero, after the loops in `openings` break too.

Closing a loop equates injection and measurement, so `sensitivity` is `(I - L)**-1` and `complementary_sensitivity` is `I - S`, both square, both taking `openings`, injections labelling inputs and measurements outputs.

`io_transfer(sys, inputs=None, outputs=None, opened=None, name=None)` runs between chosen inputs and outputs, by label or index, a negative index counting from the end, numpy integers included, defaulting to all, with the loops in `opened` broken, the rest closed. An entry naming a subsystem signal adds a channel, an input adding to what drives it, an output reporting it.

`replace_point(sys, point, value=None, name=None)` reroutes every connection the point breaks through `value` applied to that signal, leaving the point. `value` is a scalar, a square array with one row per channel, or an LTI system of the same size; zero leaves the loop open, one changes nothing, a dictionary replaces several. It has no default: leaving it out is an error rather than a zero.

Each takes a subsystem signal specification for a point name. The signal need not be declared: any subsystem signal can be opened, measured or replaced on the spot, and one used so never joins the list. All take an interconnected system, name their result, keep its states, and never modify it, even on error. `loop_transfer`, `sensitivity`, `complementary_sensitivity` and `io_transfer` need it linear.

It is an error to pass anything else, name an absent point, close a closed point, repeat a name, open one channel twice or onto taken labels, or give a specification a gain.

It is also an error to hand `io_transfer` a wrong-kind signal, ask `analysis_point` for a fractional or sub-unit size, or hand `replace_point` a missing, wrong sized, or dictionary-accompanied value.
