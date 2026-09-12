---
Title: Spill registers to the stack instead of failing allocation
Repository: https://github.com/mmcloughlin/avo
Language: Go
Issue: register-spilling
Commit: 16419356370fdbe6f006c6d4521bdb2c660f9411
---
# Spill registers to the stack instead of failing allocation

Make the register allocator spill. Values that do not fit in physical registers live in the function's stack frame and return to a register around each instruction that references them, for every kind of register and every form a value is referenced at, and the frame stays a valid one whatever mix of widths and locals it holds. A slot serves values that are not live at the same time, so the frame grows with how many values spill at once rather than with how many spill overall, and a function whose values all fit gets no frame.

`Reserve` withholds physical registers from automatic allocation, though a generator may still name one itself; `Pin` keeps a virtual register in a physical one for its whole function, so nothing else live at that time may occupy it. Either control covers the whole function wherever it is recorded, and either may name a register by any form, which identifies the whole register. Same-target repeats, an empty reserve, and reuse for values never live together or for forms that share no bytes are all fine.

Controls that cannot be honoured have to fail generation rather than bend. That covers two live values pinned to one register or to forms of it that share bytes; a target the allocator may never assign, such as a pseudo or restricted register; a pin across kinds, or to a register lacking a form at a width the value uses; a pin sending an already pinned value elsewhere; and too few registers left to hold the function.
