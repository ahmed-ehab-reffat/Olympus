# Upstream ownership audit - pdfminer.six logical structure tree

Status: `clear as of 2026-08-20 at the pinned commit`.

Repository and local-history searches covered `StructTreeRoot`, `ParentTree`,
`StructParents`, `RoleMap`, `ClassMap`, `MCR`, `OBJR`, semantic structure,
logical structure, tagged PDF, and MCID association. The source contains
syntactic marked-content interpreter/device hooks and `TagExtractor`, but no
semantic structure-tree model or content association implementation.

All visible issue and pull-request states, changelog/history references, local
candidate/problem indexes, and archive manifests were searched during the
trajectory-informed gate. No exact implementation, active owner, declined
design, or duplicate local problem was found. Adjacent tagged-content work
concerns syntactic tag extraction, not catalog structure semantics.

This audit is pin- and date-specific. Recheck upstream ownership immediately
before submission if time has elapsed or the repository pin changes.
