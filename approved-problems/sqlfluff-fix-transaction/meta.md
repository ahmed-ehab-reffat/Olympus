---
Repository: https://github.com/sqlfluff/sqlfluff
Issue: N/A
Commit: 978dfbe3da1c5b589a308339331eb28b94945cb0
Language: Python
Title: Add a Staged Fix Transaction to the Linter Fix Loop
---
# Add a Staged Fix Transaction to the Linter Fix Loop

Add a `fix_transaction` boolean setting, off by default, that stages each fix pass of the linter as a transaction.

Two fixes from different rules conflict when the source positions they touch overlap, and a `create_before` and a `create_after` on one anchor compose rather than compete. Conflicts are settled by rule code: the rule whose code sorts first keeps its fix. The surviving fixes are applied as one batch. If the result does not parse, or if it returns the file to a state already seen, the whole batch is discarded.

Every proposed fix leaves a `FixOutcome` in `LintedFile.fix_outcomes`, importable from `sqlfluff.core.linter.fix_transaction`, carrying `rule_code`, `line_no` and `line_pos`, a `status` of `applied` or `skipped`, a `reason` of `conflict`, `unparsable` or `oscillation` when skipped and `None` when applied, and `conflict_with` naming the winning rule. `FixOutcome.to_dict()` returns those fields as a mapping. With the setting off, `fix_outcomes` is empty.

`LintedFile` also provides `applied_fixes()`, `skipped_fixes()` and `fix_conflicts()`, which return the `FixOutcome` records that were applied, that were skipped, and that were skipped for a conflict; `conflict_groups()` (mapping each winning rule code to the rule codes its fixes displaced); `oscillating_rules()` (the rules rolled back for cycling); and `fix_transaction_report()`. The report has `applied` and `skipped` counts, a `reasons` count per reason, a `total`, a `summary()` method returning a string and a `to_dict()`. Across a whole run, the methods `LintingResult.get_fix_outcomes()`, `fix_transaction_report()` and `conflict_groups()` aggregate the same data. When `sqlfluff fix` runs a transaction it prints the report.
