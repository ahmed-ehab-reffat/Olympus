#!/usr/bin/env bash

set -euo pipefail

IMAGE="${STATIG_VERIFY_IMAGE:-statig-local-transitions:verification}"

if [ "${1-}" != "--inside" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    exec docker run --rm --network none \
        -v "$TASK_DIR:/patches:ro" \
        "$IMAGE" \
        bash /patches/verify/mutations.sh --inside "$@"
fi
shift

PATCH_DIR="${STATIG_PATCH_DIR:-/patches}"
BASE_SOURCE="${STATIG_BASE_SOURCE:-/app}"
MUTATION_ROOT="$(mktemp -d /tmp/statig-mutations.XXXXXX)"
SHARED_TARGET="/tmp/statig-mutation-target"

semantic_mutations=(
    map_new_variants_to_legacy
    local_self_reenters
    local_self_skips_replacement
    local_self_skips_hooks
    external_origin_is_leaf
    external_origin_is_one
    external_boundary_is_unconditional
    blocking_engine_only
    awaitable_engine_only
    legacy_self_becomes_local
    blocking_variant_matches_before_depth
    awaitable_repeated_variant_skips_level
    blocking_superstate_dispatch_hooks_omitted
    awaitable_superstate_dispatch_hooks_omitted
    blocking_rootless_external_self_skips_actions
    awaitable_rootless_external_self_skips_actions
    blocking_leaf_external_cross_branch_is_leaf_local
    awaitable_leaf_external_cross_branch_is_leaf_local
    blocking_rootless_local_distinct_retains_implicit_boundary
    awaitable_rootless_local_distinct_retains_implicit_boundary
    blocking_local_self_requires_same_depth
    awaitable_local_self_requires_same_depth
    blocking_leaf_local_cross_branch_is_leaf_local
    awaitable_leaf_local_cross_branch_is_leaf_local
    blocking_top_local_distinct_is_external
    awaitable_top_local_distinct_is_external
    awaitable_local_unbalanced_path_is_leaf_local
    blocking_leaf_local_uses_pre_dispatch_hierarchy
    awaitable_leaf_local_uses_pre_dispatch_hierarchy
    blocking_superstate_local_uses_pre_dispatch_hierarchy
    awaitable_superstate_local_uses_pre_dispatch_hierarchy
)

surface_mutations=(
    outcome_loses_debug
    public_handle_exposes_origin
)

all_mutations=("${semantic_mutations[@]}" "${surface_mutations[@]}")

is_surface_mutation() {
    local candidate="$1"
    local mutation

    for mutation in "${surface_mutations[@]}"; do
        if [ "$candidate" = "$mutation" ]; then
            return 0
        fi
    done
    return 1
}

expected_failure_minimum() {
    case "$1" in
        blocking_variant_matches_before_depth | \
            awaitable_repeated_variant_skips_level | \
            blocking_superstate_dispatch_hooks_omitted | \
            awaitable_superstate_dispatch_hooks_omitted | \
            blocking_rootless_external_self_skips_actions | \
            awaitable_rootless_external_self_skips_actions | \
            blocking_leaf_external_cross_branch_is_leaf_local | \
            awaitable_leaf_external_cross_branch_is_leaf_local | \
            blocking_rootless_local_distinct_retains_implicit_boundary | \
            awaitable_rootless_local_distinct_retains_implicit_boundary | \
            blocking_local_self_requires_same_depth | \
            awaitable_local_self_requires_same_depth | \
            blocking_leaf_local_cross_branch_is_leaf_local | \
            awaitable_leaf_local_cross_branch_is_leaf_local | \
            blocking_top_local_distinct_is_external | \
            awaitable_top_local_distinct_is_external | \
            awaitable_local_unbalanced_path_is_leaf_local | \
            blocking_leaf_local_uses_pre_dispatch_hierarchy | \
            awaitable_leaf_local_uses_pre_dispatch_hierarchy | \
            blocking_superstate_local_uses_pre_dispatch_hierarchy | \
            awaitable_superstate_local_uses_pre_dispatch_hierarchy)
            echo 1
            ;;
        *)
            echo 2
            ;;
    esac
}

apply_mutation() {
    local mutation="$1"
    local blocking="statig/src/blocking/inner.rs"
    local awaitable="statig/src/awaitable/inner.rs"
    local blocking_superstate="statig/src/blocking/superstate.rs"

    case "$mutation" in
        map_new_variants_to_legacy)
            perl -pi -e \
                's/TransitionKind::Local,/TransitionKind::Legacy,/g; s/TransitionKind::External,/TransitionKind::Legacy,/g' \
                "$blocking" "$awaitable"
            ;;
        local_self_reenters)
            perl -pi -e 's/\(0, 0\)/(1, 1)/g' "$blocking" "$awaitable"
            ;;
        local_self_skips_replacement)
            perl -0pi -e \
                's{        core::mem::swap\(&mut self\.state, &mut target\);}{        if exit_levels != 0 || enter_levels != 0 {\n            core::mem::swap(&mut self.state, &mut target);\n        }}g' \
                "$blocking" "$awaitable"
            ;;
        local_self_skips_hooks)
            perl -0pi -e \
                's{        M::before_transition}{        if matches!(kind, TransitionKind::Local)\n            && M::State::same_state(&self.state, &mut target)\n        {\n            core::mem::swap(&mut self.state, &mut target);\n            return;\n        }\n\n        M::before_transition}g' \
                "$blocking" "$awaitable"
            ;;
        external_origin_is_leaf)
            perl -0pi -e \
                's{(Outcome::ExternalTransition\(state\).*?TransitionKind::External,\n\s*)result\.handler_depth,}{$1 0,}s' \
                "$blocking" "$awaitable"
            ;;
        external_origin_is_one)
            perl -0pi -e \
                's{\.checked_sub\(handler_depth\)}{.checked_sub(if handler_depth == 0 { 0 } else { 1 })}g' \
                "$blocking" "$awaitable"
            ;;
        external_boundary_is_unconditional)
            perl -0pi -e \
                's{let common_depth =\n\s*M::State::common_ancestor_depth\(&mut self\.state, target\)\.min\(boundary_depth\);}{let common_depth = boundary_depth;}g' \
                "$blocking" "$awaitable"
            ;;
        blocking_engine_only)
            perl -pi -e \
                's/TransitionKind::Local,/TransitionKind::Legacy,/g; s/TransitionKind::External,/TransitionKind::Legacy,/g' \
                "$awaitable"
            ;;
        awaitable_engine_only)
            perl -pi -e \
                's/TransitionKind::Local,/TransitionKind::Legacy,/g; s/TransitionKind::External,/TransitionKind::Legacy,/g' \
                "$blocking"
            ;;
        outcome_loses_debug)
            perl -0pi -e \
                's{\nimpl<S> Debug for Outcome<S>\nwhere\n    S: Debug,\n\{.*\n\}\n\z}{\n}s' \
                statig/src/outcome.rs
            ;;
        legacy_self_becomes_local)
            perl -0pi -e \
                's{TransitionKind::Legacy => self\.state\.transition_path\(target\),}{TransitionKind::Legacy => {\n                if M::State::same_state(&self.state, target) {\n                    (0, 0)\n                } else {\n                    self.state.transition_path(target)\n                }\n            }}g' \
                "$blocking" "$awaitable"
            ;;
        blocking_variant_matches_before_depth)
            perl -0pi -e \
                's{(    fn common_ancestor_depth\(\n.*?    \) -> usize \{\n)}{$1        if Self::same_state(&source, &target) {\n            return source.depth().min(target.depth());\n        }\n\n}s' \
                "$blocking_superstate"
            ;;
        awaitable_repeated_variant_skips_level)
            perl -pi -e \
                's/StateExt, Superstate}/StateExt, Superstate, SuperstateExt}/' \
                "$awaitable"
            perl -0pi -e \
                's{                                Some\(parent\) => \{\n                                    superstate = parent;\n                                    handler_depth \+= 1;\n                                \}}{                                Some(parent) => {\n                                    let repeated_variant =\n                                        M::Superstate::same_state(&superstate, &parent);\n                                    superstate = parent;\n                                    if !repeated_variant {\n                                        handler_depth += 1;\n                                    }\n                                }}' \
                "$awaitable"
            ;;
        blocking_superstate_dispatch_hooks_omitted)
            perl -0pi -e \
                's{\n\s*M::(?:before|after)_dispatch\(\n\s*(?:&mut self\.shared_storage|shared_storage),\n\s*StateOrSuperstate::Superstate\(&(?:superstate|parent)\),\n\s*event,\n\s*context,\n\s*\);\n}{}g' \
                "$blocking"
            ;;
        awaitable_superstate_dispatch_hooks_omitted)
            perl -0pi -e \
                's{\n\s*M::(?:before|after)_dispatch\(\n\s*&mut self\.shared_storage,\n\s*StateOrSuperstate::Superstate\(&superstate\),\n\s*event,\n\s*context,\n\s*\)\n\s*\.await;\n}{}g' \
                "$awaitable"
            ;;
        blocking_rootless_external_self_skips_actions)
            perl -0pi -e \
                's{let boundary_depth = handler_tree_depth\.saturating_sub\(1\);}{let boundary_depth = if handler_depth == 0 && source_depth == 1 {\n                    handler_tree_depth\n                } else {\n                    handler_tree_depth.saturating_sub(1)\n                };}' \
                "$blocking"
            ;;
        awaitable_rootless_external_self_skips_actions)
            perl -0pi -e \
                's{let boundary_depth = handler_tree_depth\.saturating_sub\(1\);}{let boundary_depth = if handler_depth == 0 && source_depth == 1 {\n                    handler_tree_depth\n                } else {\n                    handler_tree_depth.saturating_sub(1)\n                };}' \
                "$awaitable"
            ;;
        blocking_leaf_external_cross_branch_is_leaf_local)
            perl -0pi -e \
                's!            TransitionKind::External => \{!            TransitionKind::External if handler_depth == 0 => (1, 1),\n            TransitionKind::External => {!' \
                "$blocking"
            ;;
        awaitable_leaf_external_cross_branch_is_leaf_local)
            perl -0pi -e \
                's!            TransitionKind::External => \{!            TransitionKind::External if handler_depth == 0 => (1, 1),\n            TransitionKind::External => {!' \
                "$awaitable"
            ;;
        blocking_rootless_local_distinct_retains_implicit_boundary)
            perl -0pi -e \
                's!            TransitionKind::Local => \{\n                if M::State::same_state\(&self\.state, target\) \{!            TransitionKind::Local => {\n                if self.state.depth() == 1 && target.depth() == 1 {\n                    (0, 0)\n                } else if M::State::same_state(&self.state, target) {!' \
                "$blocking"
            ;;
        awaitable_rootless_local_distinct_retains_implicit_boundary)
            perl -0pi -e \
                's!            TransitionKind::Local => \{\n                if M::State::same_state\(&self\.state, target\) \{!            TransitionKind::Local => {\n                if self.state.depth() == 1 && target.depth() == 1 {\n                    (0, 0)\n                } else if M::State::same_state(&self.state, target) {!' \
                "$awaitable"
            ;;
        blocking_local_self_requires_same_depth)
            perl -0pi -e \
                's!            TransitionKind::Local => \{\n                if M::State::same_state\(&self\.state, target\) \{!            TransitionKind::Local => {\n                let same_depth = self.state.depth() == target.depth();\n                if M::State::same_state(&self.state, target) && same_depth {!' \
                "$blocking"
            ;;
        awaitable_local_self_requires_same_depth)
            perl -0pi -e \
                's!            TransitionKind::Local => \{\n                if M::State::same_state\(&self\.state, target\) \{!            TransitionKind::Local => {\n                let same_depth = self.state.depth() == target.depth();\n                if M::State::same_state(&self.state, target) && same_depth {!' \
                "$awaitable"
            ;;
        blocking_leaf_local_cross_branch_is_leaf_local)
            perl -0pi -e \
                's@            TransitionKind::Local => \{@            TransitionKind::Local\n                if handler_depth == 0 && !M::State::same_state(&self.state, target) =>\n            {\n                (1, 1)\n            }\n            TransitionKind::Local => {@' \
                "$blocking"
            ;;
        awaitable_leaf_local_cross_branch_is_leaf_local)
            perl -0pi -e \
                's@            TransitionKind::Local => \{@            TransitionKind::Local\n                if handler_depth == 0 && !M::State::same_state(&self.state, target) =>\n            {\n                (1, 1)\n            }\n            TransitionKind::Local => {@' \
                "$awaitable"
            ;;
        blocking_top_local_distinct_is_external)
            perl -0pi -e \
                's@            TransitionKind::Local => \{@            TransitionKind::Local\n                if handler_depth > 0\n                    && !M::State::same_state(&self.state, target)\n                    && self.state.depth().checked_sub(handler_depth) == Some(1) =>\n            {\n                let source_depth = self.state.depth();\n                let target_depth = target.depth();\n                (source_depth, target_depth)\n            }\n            TransitionKind::Local => {@' \
                "$blocking"
            ;;
        awaitable_top_local_distinct_is_external)
            perl -0pi -e \
                's@            TransitionKind::Local => \{@            TransitionKind::Local\n                if handler_depth > 0\n                    && !M::State::same_state(&self.state, target)\n                    && self.state.depth().checked_sub(handler_depth) == Some(1) =>\n            {\n                let source_depth = self.state.depth();\n                let target_depth = target.depth();\n                (source_depth, target_depth)\n            }\n            TransitionKind::Local => {@' \
                "$awaitable"
            ;;
        awaitable_local_unbalanced_path_is_leaf_local)
            perl -0pi -e \
                's!                \} else \{\n                    self\.state\.transition_path\(target\)\n                \}!                } else {\n                    let path = self.state.transition_path(target);\n                    if path.0 == path.1 {\n                        path\n                    } else {\n                        (1, 1)\n                    }\n                }!' \
                "$awaitable"
            ;;
        blocking_leaf_local_uses_pre_dispatch_hierarchy)
            perl -0pi -e \
                's!        let result = self\.dispatch\(event, context\);!        let source_depth_before_dispatch = self.state.depth();\n        let result = self.dispatch(event, context);!; s!            Outcome::LocalTransition\(state\) => \{\n                self\.transition\(state, TransitionKind::Local, result\.handler_depth, context\)\n            \}!            Outcome::LocalTransition(state) => {\n                let source_depth = if result.handler_depth == 0 {\n                    source_depth_before_dispatch\n                } else {\n                    self.state.depth()\n                };\n                self.transition(state, TransitionKind::Local, source_depth, context)\n            }!; s!                \} else \{\n                    self\.state\.transition_path\(target\)\n                \}!                } else {\n                    let target_depth = target.depth();\n                    let common_depth =\n                        M::State::common_ancestor_depth(&mut self.state, target);\n                    (\n                        handler_depth.saturating_sub(common_depth),\n                        target_depth - common_depth,\n                    )\n                }!' \
                "$blocking"
            ;;
        awaitable_leaf_local_uses_pre_dispatch_hierarchy)
            perl -0pi -e \
                's!        let result = self\.dispatch\(event, context\)\.await;!        let source_depth_before_dispatch = self.state.depth();\n        let result = self.dispatch(event, context).await;!; s!            Outcome::LocalTransition\(state\) => \{\n                self\.transition\(state, TransitionKind::Local, result\.handler_depth, context\)\n                    \.await\n            \}!            Outcome::LocalTransition(state) => {\n                let source_depth = if result.handler_depth == 0 {\n                    source_depth_before_dispatch\n                } else {\n                    self.state.depth()\n                };\n                self.transition(state, TransitionKind::Local, source_depth, context)\n                    .await\n            }!; s!                \} else \{\n                    self\.state\.transition_path\(target\)\n                \}!                } else {\n                    let target_depth = target.depth();\n                    let common_depth =\n                        M::State::common_ancestor_depth(&mut self.state, target);\n                    (\n                        handler_depth.saturating_sub(common_depth),\n                        target_depth - common_depth,\n                    )\n                }!' \
                "$awaitable"
            ;;
        blocking_superstate_local_uses_pre_dispatch_hierarchy)
            perl -0pi -e \
                's!        let result = self\.dispatch\(event, context\);!        let source_depth_before_dispatch = self.state.depth();\n        let result = self.dispatch(event, context);!; s!            Outcome::LocalTransition\(state\) => \{\n                self\.transition\(state, TransitionKind::Local, result\.handler_depth, context\)\n            \}!            Outcome::LocalTransition(state) => {\n                let source_depth = if result.handler_depth > 0 {\n                    source_depth_before_dispatch\n                } else {\n                    self.state.depth()\n                };\n                self.transition(state, TransitionKind::Local, source_depth, context)\n            }!; s!                \} else \{\n                    self\.state\.transition_path\(target\)\n                \}!                } else {\n                    let target_depth = target.depth();\n                    let common_depth =\n                        M::State::common_ancestor_depth(&mut self.state, target);\n                    (\n                        handler_depth.saturating_sub(common_depth),\n                        target_depth - common_depth,\n                    )\n                }!' \
                "$blocking"
            ;;
        awaitable_superstate_local_uses_pre_dispatch_hierarchy)
            perl -0pi -e \
                's!        let result = self\.dispatch\(event, context\)\.await;!        let source_depth_before_dispatch = self.state.depth();\n        let result = self.dispatch(event, context).await;!; s!            Outcome::LocalTransition\(state\) => \{\n                self\.transition\(state, TransitionKind::Local, result\.handler_depth, context\)\n                    \.await\n            \}!            Outcome::LocalTransition(state) => {\n                let source_depth = if result.handler_depth > 0 {\n                    source_depth_before_dispatch\n                } else {\n                    self.state.depth()\n                };\n                self.transition(state, TransitionKind::Local, source_depth, context)\n                    .await\n            }!; s!                \} else \{\n                    self\.state\.transition_path\(target\)\n                \}!                } else {\n                    let target_depth = target.depth();\n                    let common_depth =\n                        M::State::common_ancestor_depth(&mut self.state, target);\n                    (\n                        handler_depth.saturating_sub(common_depth),\n                        target_depth - common_depth,\n                    )\n                }!' \
                "$awaitable"
            ;;
        public_handle_exposes_origin)
            perl -pi -e \
                'if ($. == 92) { s/Outcome<Self>/(Outcome<Self>, usize)/ } if ($. == 112) { s/match outcome \{/(match outcome {/ } if ($. == 139) { s/^        }$/        }, 0)/ }' \
                statig/src/blocking/state.rs
            ;;
        *)
            echo "unknown mutation: $mutation" >&2
            return 2
            ;;
    esac
}

requested_mutations=("$@")
if [ "${#requested_mutations[@]}" -eq 0 ]; then
    requested_mutations=("${all_mutations[@]}")
fi

failures=0
for mutation in "${requested_mutations[@]}"; do
    repository="$MUTATION_ROOT/$mutation"
    log="$MUTATION_ROOT/$mutation.log"

    git clone --quiet --shared "$BASE_SOURCE" "$repository"
    (
        cd "$repository"
        git apply "$PATCH_DIR/test.patch"
        git apply "$PATCH_DIR/solution.patch"
        apply_mutation "$mutation"
    )

    if is_surface_mutation "$mutation"; then
        set +e
        (
            cd "$repository"
            CARGO_TARGET_DIR="$SHARED_TARGET" CARGO_TERM_COLOR=never \
                cargo +1.90.0 test \
                --manifest-path grader_tests/Cargo.toml \
                --all-features \
                --no-run \
                --offline
        ) >"$log" 2>&1
        status=$?
        set -e

        if [ "$status" -eq 0 ]; then
            echo "SURVIVED  $mutation"
            failures=$((failures + 1))
        else
            echo "CAUGHT    $mutation (public-surface compile failure)"
        fi
        continue
    fi

    if ! (
        cd "$repository"
        CARGO_TARGET_DIR="$SHARED_TARGET" CARGO_TERM_COLOR=never \
            cargo +1.90.0 test \
            --manifest-path grader_tests/Cargo.toml \
            --all-features \
            --no-run \
            --offline
    ) >"$log" 2>&1; then
        echo "INVALID   $mutation (semantic mutation did not compile)"
        tail -n 12 "$log"
        failures=$((failures + 1))
        continue
    fi

    set +e
    (
        cd "$repository"
        CARGO_TARGET_DIR="$SHARED_TARGET" CARGO_TERM_COLOR=never \
            cargo +1.90.0 nextest run \
            --manifest-path grader_tests/Cargo.toml \
            --config-file .config/nextest.toml \
            --no-fail-fast \
            --all-features \
            --offline
    ) >"$log" 2>&1
    status=$?
    set -e

    failed_tests="$(
        awk '$1 == "FAIL" { print $NF }' "$log" |
            LC_ALL=C sort -u |
            wc -l |
            tr -d ' '
    )"
    minimum_failed_tests="$(expected_failure_minimum "$mutation")"
    if [ "$status" -ne 0 ] && [ "$failed_tests" -ge "$minimum_failed_tests" ]; then
        echo "CAUGHT    $mutation ($failed_tests failing tests)"
    elif [ "$status" -ne 0 ]; then
        echo "WEAK      $mutation ($failed_tests failing tests; expected at least $minimum_failed_tests)"
        failures=$((failures + 1))
    else
        echo "SURVIVED  $mutation"
        failures=$((failures + 1))
    fi
done

if [ "$failures" -ne 0 ]; then
    echo "$failures mutation checks failed" >&2
    exit 1
fi

echo "all ${#requested_mutations[@]} mutation checks passed"
