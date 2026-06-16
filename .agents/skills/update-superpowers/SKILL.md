---
name: update-superpowers
description: Use when the user wants to sync their superpowers fork with upstream obra/superpowers, pull in upstream changes, or update their customized fork without losing local modifications.
---

# Update Superpowers

Safely merge upstream `obra/superpowers` changes into this fork, with backup, conflict preview, and rollback instructions.

## Intentional Local Deviations

This fork intentionally diverges from upstream in ways that must be preserved
across updates. When merging upstream, re-apply these deviations — do NOT
reintroduce upstream content that this fork has deliberately removed.

### Removed skill: `using-git-worktrees`

This fork does not use the git-worktrees workflow. The `using-git-worktrees`
skill and all references to it have been intentionally removed. When upstream
changes touch this skill, expect to re-remove it after merging.

Specifically, keep these removals:
- No `using-git-worktrees` skill directory or `SKILL.md`.
- `skills/subagent-driven-development/SKILL.md` — no `using-git-worktrees`
  line under "Required workflow skills".
- `skills/executing-plans/SKILL.md` — no `using-git-worktrees` line under
  "Required workflow skills".
- `skills/writing-plans/SKILL.md` — no "isolated worktree" Context line
  referencing `using-git-worktrees`.
- `skills/using-superpowers/references/codex-tools.md` — the Environment
  Detection section references only `finishing-a-development-branch`, not
  `using-git-worktrees`.
- `README.md` — no `using-git-worktrees` entry in the Basic Workflow or
  Skills Library lists.

After merging upstream (Step 4), if upstream reintroduced the
`using-git-worktrees` skill or any reference to it, search and remove them
again before validation:
```bash
grep -rIl "using-git-worktrees" --include="*.md" .
```
Review each hit and strip the reintroduced references. Leave historical
`docs/` specs/plans and `RELEASE-NOTES.md` entries untouched (they are a
record of past work, not active wiring).

### Added: comment-quality guidance

This fork adds comment-quality guidance that must be preserved across updates:
- `skills/writing-plans/SKILL.md` — a `## Comments in Plan Code` section (rationale in prose, contract-only comments in code blocks, with a worked example).
- `skills/subagent-driven-development/SKILL.md` — a "Never add or expand comments in a task's code blocks" bullet under Red Flags.
- `skills/subagent-driven-development/implementer-prompt.md` — a line noting code-block comments are intentionally concise; reproduce, do not editorialize.

After merging upstream (Step 4), verify these survive:
```bash
grep -rIl "Comments in Plan Code\|intentionally concise" skills/ --include="*.md"
```
If a merge dropped them, re-apply from this record.

### Changed: writing-plans offers production vs. prototype workflow choice

Upstream's `skills/writing-plans/SKILL.md` may have different execution handoff
behavior. This fork offers an explicit choice between two subagent workflows:
- **Production** (with human review gates) — `superpowers:subagent-driven-development`
- **Prototype** (no human gates) — `superpowers:prototype-driven-development`

Keep:
- `skills/writing-plans/SKILL.md` — the `## Execution Handoff` section asks the
  user to choose between production and prototype workflows, listing their
  differences clearly.
- The plan header template lists all three options (including `executing-plans`
  as a fallback).

After merging upstream (Step 4), verify this choice structure survives:
```bash
grep -n "prototype-driven-development" skills/writing-plans/SKILL.md
```
This should show the execution handoff section and plan header. If upstream
removed the prototype option, re-apply this record.

### Added: Human review gates and prototype workflow

This fork adds mandatory human review gates to production workflows and a
separate prototype workflow that bypasses them. Key changes:

**`skills/subagent-driven-development/SKILL.md`:**
- Core principle includes "human review gate before commit"
- Human review workflow section describes stopping for human approval before each commit
- Workflow diagram includes yellow "Present changes to human for review" and "Human approves?" nodes
- Example workflow shows human approval gates and coordinator commits
- Mentions `prototype-driven-development` as alternative for throwaway work
- Red Flags include "Commit before human review"

**`skills/prototype-driven-development/SKILL.md`** (new skill):
- Entire skill for throwaway/prototype work without human gates
- Same automated reviews (spec + quality) but no human approval step
- No final `/code-review`
- Strong Red Flags: "Never use for production code, peer-reviewed code, security changes"
- "If someone will read this code in a code review, use subagent-driven-development"

**`skills/subagent-driven-development/implementer-prompt.md`:**
- "Do NOT commit work — the coordinator handles commits after human review"

**`skills/subagent-driven-development/code-quality-reviewer-prompt.md`:**
- Uses `DIFF_SPEC: Uncommitted working tree changes` instead of `BASE_SHA/HEAD_SHA`

**`skills/executing-plans/SKILL.md`:**
- Lists both production and prototype workflow options

**`skills/brainstorming/SKILL.md`:**
- Mentions prototype option in Implementation section

After merging upstream (Step 4), verify these survive:
```bash
grep -rn "human review gate\|prototype-driven-development" skills/subagent-driven-development/ skills/writing-plans/ skills/brainstorming/ skills/executing-plans/ --include="*.md"
grep -n "Do NOT commit" skills/subagent-driven-development/implementer-prompt.md
test -f skills/prototype-driven-development/SKILL.md && echo "prototype skill exists" || echo "WARNING: prototype skill missing"
```

If upstream changes conflict with these human-review mechanisms, carefully
preserve the human review gates in production workflow while ensuring prototype
workflow remains available as an explicit opt-in.

## Step 0: Preflight

```bash
git status --porcelain
```
If output is non-empty: tell user to commit or stash first, then stop.

```bash
git remote -v
```
- Verify `upstream` exists and its URL contains `obra/superpowers` (matches both HTTPS and SSH).
- Verify `origin` URL does NOT contain `obra/superpowers` — it must be the user's fork. Stop with instructions if it does.

If `upstream` is missing:
```bash
git remote add upstream https://github.com/obra/superpowers.git
```

```bash
git fetch upstream --prune
```

Detect upstream branch:
```bash
git symbolic-ref refs/remotes/upstream/HEAD
```
Fall back to checking for `upstream/main`, then `upstream/master`. Ask the user if neither exists. Store as `UPSTREAM_BRANCH`.

## Step 1: Safety Net

```bash
HASH=$(git rev-parse --short HEAD)
TIMESTAMP=$(date +%Y%m%dT%H%M%S)
git branch backup/pre-update-$HASH-$TIMESTAMP
git -c tag.gpgsign=false tag pre-update-$HASH-$TIMESTAMP
```

Note: `-c tag.gpgsign=false` forces a lightweight tag. Without it, a global
`tag.gpgsign=true` config makes `git tag <name>` create a signed annotated tag,
which opens an editor for the message and invokes GPG — both can fail in
non-interactive shells.

If the tag step fails for editor/signing reasons, the backup branch is still
sufficient for rollback. You can retry the tag with:

```bash
git -c tag.gpgsign=false tag pre-update-$HASH-$TIMESTAMP
```

Save the tag name — you'll need it for the summary and rollback.

## Step 2: Preview (no edits yet)

```bash
BASE=$(git merge-base HEAD upstream/$UPSTREAM_BRANCH)
git log --oneline $BASE..upstream/$UPSTREAM_BRANCH
git log --oneline $BASE..HEAD
git diff --name-only $BASE..upstream/$UPSTREAM_BRANCH
```

Bucket the upstream-changed files:
- `skills/` — unlikely to conflict unless user edited upstream skills
- `docs/` — low risk
- `tests/` — low risk
- `package.json`, config files — medium risk
- Other source files — higher risk if locally modified

Present the bucketed summary and ask the user to choose:
- **A) Merge** — merge all upstream changes
- **B) Abort** — stop here (preview only)

If Abort: stop.

## Step 3: Conflict Preview

```bash
git merge-tree $(git merge-base HEAD upstream/$UPSTREAM_BRANCH) HEAD upstream/$UPSTREAM_BRANCH
```

If conflicts: show the list, note the user can resolve with `git mergetool` after the merge, and ask to proceed. If none: proceed.

## Step 4: Merge

```bash
git merge upstream/$UPSTREAM_BRANCH --no-edit
```

If conflicts occur:
- Run `git status` and list conflicted files with a brief summary.
- Instruct: "Run `git mergetool` in your terminal to resolve, then confirm here."
- Do NOT edit conflict markers yourself.
- Once user confirms: `git commit --no-edit` if merge did not auto-commit.

After the merge completes, re-apply the **Intentional Local Deviations**
(see top of this skill) — in particular, re-remove any `using-git-worktrees`
references upstream may have reintroduced.

## Step 5: Validation

Check in order, run the first found:
1. `package.json` has a `test` script → `npm test`
2. `Makefile` has a `test` target → `make test`
3. Executables in `tests/` → run them

If none found: report "Validation limited — no test scripts found." If validation fails: show the error, only fix issues clearly caused by the merge, and ask before making any other changes.

## Step 6: Summary + Rollback

Report:
- Backup tag: `<tag>`
- New HEAD: `git rev-parse --short HEAD`
- Upstream HEAD: `git rev-parse --short upstream/$UPSTREAM_BRANCH`
- Conflicted files resolved (if any)
- Remaining local diff: `git diff --name-only upstream/$UPSTREAM_BRANCH..HEAD`

Rollback (either works):
```bash
git reset --hard <backup-tag>
# or, if the tag step was skipped:
git reset --hard backup/pre-update-<HASH>-<TIMESTAMP>
```
