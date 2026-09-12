# Gap analysis — pdfminer.six logical structure tree, version 1

Verdict: `pass`.

Repository: `pdfminer/pdfminer.six` at
`a18de2a9c479b4c847538500017b449ddaec177e`.

Artifact identifiers: prompt `3eaebbc7…`, tests `f564861a…`, reference
`faac3cf4…`, Dockerfile `071e5599…`, baseline tree `c8313669…`, and reference
tree `71d1cccc…`. Full hashes are recorded in `ENVIRONMENT.md`.

The final prompt vocabulary clarification and representation-neutral empty-items
assertion do not add, remove, or merge a coverage cell. The complete
exact-version gate was repeated and retained the same 14 focused outcomes.

## Atomic requirement map

| Public obligation | Qualifiers and independent dimensions | Strongest test | Coverage |
|---|---|---|---|
| Expose high-level extraction and return `None` without a structure root | file API; tagged versus untagged | `test_untagged_document_has_no_structure_tree` | direct |
| Expose document-level extraction without rendering | parsed-document API; empty `items` | `test_document_api_parses_tree_without_rendered_items` | direct |
| Preserve explicit `/K` order | element, integer MCID, MCR, OBJR | `test_mixed_children_preserve_order_roles_attributes_and_object` | direct |
| Expose original and mapped roles | `/S` versus `/RoleMap`; BDC tag deliberately differs | mixed-child test | direct |
| Expand direct and class attributes | scalar/array `A`; scalar/array ClassMap values; multiple `C` names | mixed-child test | direct |
| Expose OBJR page, object ID, and object | ordered object-reference child | mixed-child test | direct |
| Keep MCID identity scoped | same MCID on two pages; actual distinct `LTChar` objects | `test_same_mcid_stays_scoped_to_page_and_inherited_page_changes` | direct |
| Resolve page inheritance and override | element inheritance; nested element override; MCR-local override | same-MCID test and `test_mcr_page_overrides_inherited_element_page` | direct |
| Resolve inline and named marked-content properties | inline dictionaries across most fixtures; resource name in one fixture | `test_named_marked_content_properties_bind_layout` | direct |
| Associate actual layout objects | text, image, and vector producers | same-MCID, image, and vector tests | direct |
| Associate explicit Form MCRs | containing page, Form stream, Form StructParents, MCID | `test_explicit_form_mcr_uses_form_stream_context` | direct |
| Recover reverse ParentTree associations | page and Form contexts; root `Nums` | `test_parent_tree_recovers_page_and_form_content_in_reverse` | direct |
| Traverse a hierarchical ParentTree | positive `Kids` leaf plus limits | `test_parent_tree_traverses_child_number_tree_nodes` | direct |
| Terminate malformed graphs safely | structure cycle, ParentTree cycle, dangling refs, invalid values; strict/nonstrict | three malformed-input tests | direct |
| Preserve semantic rather than visual/tag order | BDC tag differs; `/K` mixed order is asserted | mixed-child test | direct |

## Equivalence classes and weak cells

| Dimension | Grouped equivalent cells | Separate repository branches | Weak or uncovered cell | Evidence |
|---|---|---|---|---|
| content producer | individual glyphs within a text operator are one renderer branch | text, image XObject, vector path | none after hardening | `render_char`, `render_image`, and `paint_path` are distinct methods |
| content scope | different MCID values within one scope use the same compound-key logic | page versus Form; repeated MCID across pages | reusable Form occurrence across multiple invocations intentionally unspecified | page lifecycle and recursive `do_Do` are separate |
| page source | inherited pages within a subtree are equivalent after resolution | element-local and MCR-local `Pg` | none | separate structure dictionaries own `Pg` |
| structure child | repeated elements share the element walker | integer, MCR, OBJR, nested element | none | distinct PDF child representations |
| ParentTree shape | additional depth repeats the same recursive step | root `Nums`, positive `Kids`, cyclic `Kids` | arbitrary tree depth grouped with one positive level | repository `NumberTree` recursion |
| attributes | multiple entries repeat ordered expansion | direct dict/list, `C` name/list, ClassMap dict/list | revision-number annotations intentionally out of scope | prompt promises dictionaries, not revision selection policy |
| malformed values | different missing object IDs share resolution failure | structure cycle, number cycle, dangling, invalid literal | arbitrary corrupt streams out of scope | prompt names graph/value failures, not general PDF repair |

## Gap trials

| Plausible incorrect implementation | Focused result | Full-suite result if needed | Targeted probe result | Decision |
|---|---:|---:|---:|---|
| Traverse only root ParentTree `Nums` while detecting direct child cycles | passed predecessor; 13/14 final | 249/249 | reference pass; mutant fails only positive `Kids` test | admitted |
| Ignore MCR-local `Pg` and always inherit the element page | passed predecessor; 13/14 final | 249/249 | reference pass; mutant fails only MCR override test | admitted |
| Record text/Form content but omit `LTImage` | passed predecessor; 13/14 final | 249/249 | reference pass; mutant fails only image test | admitted |
| Record text/images but omit vector layout objects | 13/13 predecessor; 13/14 final | 249/249 | reference pass; mutant fails only vector test | admitted |
| Process only the first entry of `A` and `C` arrays | 13/13 predecessor; 13/14 final | 249/249 | reference pass; mutant fails only mixed metadata test | admitted by strengthening existing fixture |
| Key lookup by MCID alone | fails same-MCID page test | not escalated | existing reference pass / mutant fail | already covered |
| Ignore resource-named BDC property lists | fails named-property test | not escalated | existing reference pass / mutant fail | already covered |
| Parse only forward `/K` children | fails page/Form reverse test | not escalated | existing reference pass / mutant fail | already covered |
| Expose OBJR ID but not the resolved target | fails mixed-child test | not escalated | existing reference pass / mutant fail | already covered |
| Drop RoleMap or ClassMap expansion | fails mixed-child test | not escalated | existing reference pass / mutant fail | already covered |

Every admitted probe independently fails on the pristine implementation because
the public API is absent. The five survivor trees preserve all participant-owned
production paths and passed the complete upstream suite; their defects are
isolated to semantic association behavior.

## Rejected gap candidates

- Repeating the same MCID with arbitrary numeric values adds fixtures but no new
  scope branch.
- Testing every vector shape or image colorspace repeats the established
  `paint_path` or `render_image` producer boundary.
- Additional ParentTree depth repeats the positive `Kids` recursion already
  covered.
- ParentTree association for object `/StructParent`, namespace dictionaries,
  accessibility reading-order heuristics, and repair of corrupt content streams
  are outside the public page/Form contract.
- A Form reused on multiple pages is not assigned occurrence semantics by the
  prompt; asserting one aggregation policy would prescribe an unstated choice.
- Exact exception messages and exact malformed-tree retention were rejected;
  the prompt permits repository syntax/type errors or omission.

## Final coverage statement

All atomic public obligations and all repository-grounded independent branches
identified in this audit have direct black-box coverage. No actionable survivor
remains in the attempted mutation set. This pass is evidence for that set, not
proof that every possible false positive is impossible.
