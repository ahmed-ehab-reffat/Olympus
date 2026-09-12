---
Title: Add Subquery Expressions and Derived Tables to the SQL Engine
Repository: https://github.com/erikgrinaker/toydb
Language: Rust
Issue: N/A
Commit: 51fe4fb693b2a3117330679f49d4998cf24b87e5
---

# Add Subquery Expressions and Derived Tables to the SQL Engine

Extend the SQL engine with subquery expressions, usable in SELECT, WHERE, ORDER BY, UPDATE assignments, and INSERT values. A parenthesized SELECT used as a scalar expression yields a single value, returning NULL for no rows and erroring for more than one. A value may be tested with `IN` and `NOT IN` against a parenthesized list or a subquery, a subquery tested with `EXISTS` and `NOT EXISTS`, and a comparison quantified with `ANY`, `SOME`, or `ALL` against a subquery. A parenthesized SELECT may also be a `FROM` item with an alias, a derived table. A subquery may reference columns of any enclosing query.

Results follow SQL three-valued logic, treating NULL as unknown. `IN` is true when a match is found, false when none matches with no NULL involved, and NULL otherwise; `NOT IN` negates it, so a list or subquery containing NULL never lets `NOT IN` be true. `ANY` and `SOME` are true when the comparison holds for some row and false for an empty subquery; `ALL` is true when it holds for every row and for an empty subquery, and false when it fails for some row; both are NULL when otherwise undetermined.

`EXISTS` is two-valued: true whenever the subquery returns at least one row, even an all-NULL row, and never NULL; `NOT EXISTS` negates it. A scalar subquery, and the subquery of an `IN`, `ANY`, `SOME`, or `ALL` predicate, must each select exactly one column.
