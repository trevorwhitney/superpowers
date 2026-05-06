---
name: update-superpowers
description: Use when the user wants to sync their superpowers fork with upstream obra/superpowers, pull in upstream changes, or update their customized fork without losing local modifications.
---

# Update Superpowers

Safely merge upstream `obra/superpowers` changes into this fork, with backup, conflict preview, and rollback instructions.

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
