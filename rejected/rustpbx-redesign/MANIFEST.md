# RustPBX redesign research archive manifest

Archived on 2026-07-25 after both post-SipFlow redesign directions failed.

## Preserved evidence

- `AUDIT.md`: pinned-source findings for RWI command idempotency and atomic hot
  reload, cheapest legitimate implementation shapes, and rejection rationale.

The earlier SipFlow-specific rejection is preserved separately under
`archive/rustpbx-sipflow/`.

## Retired checkout

The clean partial clone at `work/rustpbx-redesign/upstream/` was pinned to
`ac15e936ee0c8f7bd1eaedc83609d05096ccaf58`. It contained no edits or unique
prototype and is reproducible from the public repository, so it was retired
from the workspace rather than archived. During this task it was moved to
temporary recovery path
`/private/tmp/olympus-rustpbx-redesign-clean-20260725/`.

## Reuse rule

Do not retry the SipFlow, RWI idempotency/resume, or atomic reload directions by
adding more command types, formatting, cluster policies, or private
architecture constraints.
