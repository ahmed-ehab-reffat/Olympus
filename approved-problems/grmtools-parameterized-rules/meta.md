---
Repository: https://github.com/softdevteam/grmtools
Language: Rust
Issue: none (original feature request)
Commit: c1a9bd0f820285754e17fc002f1cb69667ee3055
Title: Add parameterised rules to the Yacc grammar reader
---
# Add parameterised rules to the Yacc grammar reader

A rule name in a `.y` file may be followed by a list of parameters in angle brackets written straight after the name, and a production may then use that rule by giving it arguments in the same shape. `Comma<T>` declares one parameter, `Sep<T,D>` two. Repeating a name in one declaration is an error, though the same argument may be given to more than one parameter. Spaces are allowed inside the brackets, but a list of either kind must name at least one thing and may not end with a comma.

An argument is the name of an ordinary rule, another such call, or a token, either quoted or introduced by `%token`. A call may be written anywhere a rule may be written in a production, and also in `%start` and in `%expect-unused`.

Each distinct set of arguments yields one rule. Its name is the parameterised rule's name followed by the argument names in angle brackets, separated by commas with no spaces; a token argument is written between single quotes there, whichever quotes it was given with. Arguments are built before the call that uses them, and the new rules follow every rule the file writes, ordered by when each name was first needed, counting a need that arises while another rule is being built. The parameterised rule itself is not a rule of the resulting grammar.

Inside the body every use of a parameter becomes the argument it was given, and a parameter given a token stands for that token. Actions and `%prec` are carried over unchanged, and a production without `%prec` takes its precedence from the last token of the rule that was built. A `%prec` naming a parameter takes the token that parameter was given, and is an error when it was given a rule. Where a rule declares a Rust type, each whole-word occurrence of a parameter in that type becomes the type declared by the argument rule; a parameter that is named in the type but given a token is an error.

A rule may use itself with the arguments it already has, reusing the rule being built; a grammar needing more than 128 of these rules is an error. So are: arguments given to a rule that takes none or to a name that is not a rule, the wrong number of arguments, a parameterised name used with no arguments in a production or in `%start`, an argument naming nothing, and an unclosed list. An error points at the call it objects to, or at the name where there is no call. A parameterised rule nothing uses is reported as an unused rule unless `%expect-unused` names it.
