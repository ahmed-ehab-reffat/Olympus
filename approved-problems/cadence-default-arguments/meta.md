# Add default arguments to functions and initializers

A call has to pass one argument for every parameter, so a function which wants an optional part has to be written twice. Extend the language so a parameter may declare a default argument: an expression after its type annotation. Function declarations, function expressions and initializers all accept them. A parameter which follows one that has a default argument must have one as well. A parsed program keeps the expression, so printing a declaration back out shows the default it was written with.

A call may leave off any argument whose parameter has a default, not only the last ones. The arguments it does pass stay in the order the parameters are declared, and a call which supplies them out of that order, repeats a label, or names a parameter which is not there is rejected by the checker.

A default argument is evaluated once for every call which leaves it off, and the ones a call leaves off are evaluated in the order their parameters are declared. It is evaluated in the scope of its own declaration, before any parameter of the call is bound, so the parameters are not visible to it: a name it uses which also names a parameter refers to the outer declaration. A member function may use `self` in a default argument. Because a default argument is evaluated implicitly, it has to be a view expression, and a parameter whose type is a resource, or holds one, may not have a default argument at all.

Default arguments belong to a declaration rather than to a type. A binding which takes its type from a function keeps them, while writing that type out drops them, so what a call may leave off comes from the declaration it reaches, while the value it uses comes from the function which runs. A function with no implementation of its own, such as an interface requirement, may not declare one, because there is no scope to evaluate it in.

Transaction parameters and event parameters keep the rules they have today.
