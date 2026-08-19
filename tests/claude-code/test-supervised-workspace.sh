#!/usr/bin/env bash
# The supervised skill owns its scripts. review-package must support the
# uncommitted --working-tree mode the human gate depends on, and must refuse
# to run without a plan file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPTS="$REPO_ROOT/skills/supervised-subagent-development/scripts"

FAILURES=0
TEST_ROOT=""

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

cleanup() {
    if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
        rm -rf "$TEST_ROOT"
    fi
}

main() {
    echo "=== Test: supervised workspace ==="
    TEST_ROOT="$(mktemp -d)"
    trap cleanup EXIT

    for f in sdd-workspace task-brief review-package; do
        if [ -x "$SCRIPTS/$f" ]; then
            pass "supervised skill owns an executable $f"
        else
            fail "supervised skill is missing an executable $f"
        fi
    done

    cd "$TEST_ROOT"
    git init --quiet .
    git config user.email test@example.com
    git config user.name Test
    echo "# Plan" > plan.md
    echo "## Task 1" >> plan.md
    git add plan.md
    git commit --quiet --no-gpg-sign -m "seed"

    echo "uncommitted" > change.txt

    if "$SCRIPTS/review-package" --working-tree plan.md >/dev/null 2>&1; then
        pass "review-package --working-tree accepts a plan file"
    else
        fail "review-package --working-tree rejected a valid plan file"
    fi

    if "$SCRIPTS/review-package" --working-tree >/dev/null 2>&1; then
        fail "review-package --working-tree accepted a missing plan file"
    else
        pass "review-package --working-tree requires a plan file"
    fi

    local out
    out="$(find "$TEST_ROOT/.superpowers/sdd/plan" -name 'review-worktree-*.diff' 2>/dev/null | head -1)"
    if [ -n "$out" ] && grep -q 'uncommitted working-tree changes' "$out"; then
        pass "package covers the uncommitted working tree"
    else
        fail "package did not cover the uncommitted working tree"
    fi

    echo ""
    if [ "$FAILURES" -eq 0 ]; then
        echo "PASS"
    else
        echo "FAIL: $FAILURES check(s) failed"
        exit 1
    fi
}

main "$@"
