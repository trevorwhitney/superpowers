#!/usr/bin/env bash
# Guards two classes of skill rot: a relative path pointing at a file that no
# longer exists, and a frontmatter name that disagrees with its directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -d "$REPO_ROOT/skills" ]; then
    echo "  [FAIL] no skills directory at $REPO_ROOT/skills"
    exit 1
fi

FAILURES=0

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

check_relative_paths() {
    local broken=0
    local checked=0
    local md dir target
    while IFS= read -r md; do
        dir="$(dirname "$md")"
        while IFS= read -r target; do
            [ -n "$target" ] || continue
            checked=$((checked + 1))
            if [ ! -e "$dir/$target" ]; then
                echo "    $md -> $target"
                broken=$((broken + 1))
            fi
        done < <(grep -o '](\.\./[^)]*)' "$md" | sed 's/^](//; s/)$//')
    done < <(find "$REPO_ROOT/skills" -name '*.md')

    if [ "$checked" -eq 0 ]; then
        fail "no relative skill references found to check — the tree looks wrong"
    elif [ "$broken" -eq 0 ]; then
        pass "every relative skill reference resolves ($checked checked)"
    else
        fail "$broken relative skill reference(s) do not resolve"
    fi
}

check_absolute_base_dirs() {
    local hits
    hits="$(grep -rl 'file:///' "$REPO_ROOT/skills" --include='*.md' || true)"
    if [ -z "$hits" ]; then
        pass "no absolute file:// base directories"
    else
        echo "$hits" | sed 's/^/    /'
        fail "absolute file:// base directory found"
    fi
}

check_frontmatter_names() {
    local bad=0
    local seen=0
    local skill_md dir_name declared
    for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
        [ -f "$skill_md" ] || continue
        seen=$((seen + 1))
        dir_name="$(basename "$(dirname "$skill_md")")"
        declared="$(sed -n 's/^name: *//p' "$skill_md" | head -1)"
        if [ "$declared" != "$dir_name" ]; then
            echo "    $dir_name declares name: $declared"
            bad=$((bad + 1))
        fi
    done

    if [ "$seen" -eq 0 ]; then
        fail "no SKILL.md files found — the tree looks wrong"
    elif [ "$bad" -eq 0 ]; then
        pass "every skill's frontmatter name matches its directory ($seen checked)"
    else
        fail "$bad skill(s) have a mismatched frontmatter name"
    fi
}

main() {
    echo "=== Test: skill references ==="
    check_relative_paths
    check_absolute_base_dirs
    check_frontmatter_names

    echo ""
    if [ "$FAILURES" -eq 0 ]; then
        echo "PASS"
    else
        echo "FAIL: $FAILURES check(s) failed"
        exit 1
    fi
}

main "$@"
