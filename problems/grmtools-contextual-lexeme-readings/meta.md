---
Repository: https://github.com/softdevteam/grmtools
Issue: N/A
Commit: 8ce095a386c84392bf6d7bf98bf813d06c87b708
Language: Rust
Category: feature-request
Title: Add context-dependent token readings to lrpar parsers
---
# Add context-dependent token readings to lrpar parsers

Add `%fallback` and `%split` declarations to grmtools Yacc grammars, so that an lrpar parser can read a lexeme as a different token, or as several tokens, when it cannot parse the lexeme as the lexer produced it. Today the lexer's token is final: a keyword can never stand where an identifier is expected, `>>` can never close two nested argument lists, and the grammar reader rejects both declarations as unknown.

`%fallback T A B` declares the tokens `A` and `B`, each of which may be read as `T`. `%split S P1 P2` declares the token `S`, which may be read as the tokens `P1` then `P2`. A split has at least two pieces, and their names written one after another must spell the name of `S`, as in `%split '>>' '>' '>'`; when a lexeme is read as pieces, each piece covers as many characters of it as the piece's name has, in order, so a lexeme that is not exactly as long as the name of `S` cannot be read as pieces. A token may be declared by only one `%fallback` or `%split`, and a second declaration is an error pointing at both. A fallback target must be a token of the grammar other than the declared token, and must not itself be declared by a `%fallback` or `%split`; every piece must be a token of the grammar. A target or piece that is not a token is an error at its name, and any other invalid declaration is an error at the declared token. A declared token counts as used exactly when its target, or every one of its pieces, is used.

The parser decides how to read a lexeme from its configuration at the moment the lexeme becomes the lookahead, before any reduction the lexeme would trigger. The lexeme is read as lexed if the parser can shift it from that configuration, otherwise as its fallback target if that token can be shifted from there, otherwise as its pieces if they can all be shifted one after the other. A lexeme that no reading fits keeps its own token and is a syntax error at that lexeme. A lexeme read as another token keeps its span and carries the token it was read as, in parse trees and in actions; each piece carries its own token and its part of the span.

CPCT+ error recovery reads every lexeme the same way while it searches for, ranks and applies repairs. When the lexeme at an error is a split token that no reading fits but that is as long as its token's name, recovery repairs it one piece at a time: each piece may be shifted or deleted on its own, deleting a piece costs what its token costs, the repair names the piece with its part of the span, and parsing carries on from the next piece. Recovery repairs any other lexeme as a whole, as it does today.
