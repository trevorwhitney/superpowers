---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
disable-model-invocation: true
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Mode Lock

When invoked from brainstorming, a mode lock is already set in the conversation:

```
Mode lock: TDD ping-pong
```

**Canonical values:**

- `TDD ping-pong`
- `agentic production`
- `agentic prototype`

**Canonical lock lines:**

- `Mode lock: TDD ping-pong`
- `Mode lock: agentic production`
- `Mode lock: agentic prototype`

**Rules:**

- If mode lock is present in the session, read it and do not ask a second preset question.
- If mode lock is missing (direct invocation), ask once for the same three presets, then lock that selection for execution routing.
- Expected format: `Mode lock: <canonical value>` as a bare line (no markdown decoration).
- Normalization: trim whitespace, case-fold for comparison, and strip wrapping markdown (backticks, asterisks) and surrounding angle brackets if present.
- If the value is not one of the canonical values after normalization, treat mode lock as missing and ask once.
- `TDD ping-pong` → emit test-only plan format with TDD-mode header (see Plan Document Header and TDD Ping-Pong Task Structure below).
- `agentic production` → emit standard plan format with non-TDD header.
- `agentic prototype` → emit standard plan format with non-TDD header.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

Use this structure for non-TDD modes (`agentic production` and `agentic prototype`).

**Each step is one action (2-5 minutes):**

- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Stage the changes" - step
- "Pause for human review of staged changes (no commit yet)" - step
- "Commit after explicit human confirmation" - step

## Plan Document Header

**Every plan MUST start with this header. Choose the template that matches the mode lock:**

### For `TDD ping-pong` mode:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:tdd-ping-pong
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

### For `agentic production` or `agentic prototype` modes:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Choose appropriate workflow:
> - superpowers:subagent-driven-development (production code with human review)
> - superpowers:prototype-driven-development (throwaway/prototype code, no human gates)
> - superpowers:executing-plans (fallback if subagents unavailable)
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**

- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v` Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v` Expected: PASS

- [ ] **Step 5: Stage changes (do not commit yet)**

```bash
git add tests/path/test.py src/path/file.py
```

- [ ] **Step 6: Pause for human review (required stop)**

Review staged changes and STOP. Do not commit. Wait for explicit human confirmation to continue.

- [ ] **Step 7: Commit after confirmation**

```bash
git commit -m "feat: add specific feature"
```
````

## TDD Ping-Pong Task Structure

Use this structure when mode lock is `TDD ping-pong`.

- Provide concrete test snippets for each cycle.
- Provide minimal compile scaffolding only when required by language constraints: placeholders must fail loudly (panic/throw); zero-value returns are allowed only when language constraints require them and must still preserve a failing path.
- Do not provide production implementation code snippets.
- Provide breadcrumbs to existing files/patterns when useful.

### Task N: [Functional Slice]

**Files:**
- Modify test: `exact/path/to/test`
- Optional compile scaffolding: `exact/path/to/source`
- Breadcrumbs: `exact/path/to/reference`

- [ ] **Cycle 1: Write failing test**

```go
func TestBehavior(t *testing.T) {
    got, err := Target(input)
    require.NoError(t, err)
    require.Equal(t, expected, got)
}
```

- [ ] **Cycle 1: Verify RED**

Run: `go test ./path -run TestBehavior -v`  
Expected: FAIL for missing implementation.

- [ ] **Cycle 1: Pause for human GREEN**

Pause and wait for human implementation.

- [ ] **Cycle 1: Verify GREEN and quick review**

Run: `go test ./path -run TestBehavior -v`  
Expected: PASS for intended reason.

If a concern is found, ask: "Add a new test for this concern, or move on with the plan?"

## Comments in Plan Code

Code blocks in tasks are pasted into the implementer and become the shipped code, comments included. So the comments you write in plan code blocks must already meet the project's comment standard: **describe what the code does and its contract — never why it was built this way.**

Put rationale — the design discussion, alternatives, the constraint being satisfied — in the **prose before the code block**, where it belongs. Do not encode it in the block's comments.

Test each comment: if a pure refactor (same behavior, different implementation) would make it false or pointless, it is justifying the implementation. Move it to the prose and reduce the comment to the contract.

**Bad** — the comment fossilizes the design discussion:

```go
// indexedSeq attaches a stable pile index so the loser tree can break ties
// deterministically. The index must be readable when the tree snapshots each
// sequence (loser.Tree calls at() eagerly inside moveNext), so it must travel
// with the sequence rather than be derived at yield time.
type indexedSeq[R any] struct {
    rowReader[R]
    idx int
}
```

**Good** — the design discussion moves to prose; the comment keeps the invariant a maintainer needs:

> We sever the tie between the loser tree and each sequence by storing the index
> on the sequence rather than deriving it at yield time.

```go
// indexedSeq wraps a rowReader with its pile index. The index must be a stored
// field (not derived lazily): the loser tree reads it eagerly when it snapshots
// each sequence.
type indexedSeq[R any] struct {
    rowReader[R] // promotes Next/Value/Err/Close
    idx int
}
```

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Self-Review

After saving the plan, run a multi-model critical review before offering execution choices.

**Run:** `/plan-review` with the full plan text as the argument.

The `/plan-review` command has its own logic, just run it as instructed and wait for the response.

**After the review completes:**

- If the revised plan has meaningful changes, update the plan file with the revised version and commit
- If the original plan is already lean, note that and proceed
- Either way, continue to Execution Handoff

## Execution Handoff

After plan-review completes, route execution based on the mode lock established earlier. Do not re-ask the mode question; execute immediately with the established mode lock.

**If mode lock is present (from brainstorming flow):**

Announce and route immediately:

```
Plan complete and saved to `docs/superpowers/plans/<filename>.md`.
Mode lock is `<preset>`, so I will use `<mapped-skill>` for execution.
```

Routing map:

- `TDD ping-pong` → invoke `superpowers:tdd-ping-pong`
- `agentic production` → invoke `superpowers:subagent-driven-development`
- `agentic prototype` → invoke `superpowers:prototype-driven-development`

**If mode lock is absent (direct invocation of writing-plans):**

Ask once for the mode choice:

```
Plan complete and saved to `docs/superpowers/plans/<filename>.md`.

Which execution mode should I use?

1. **TDD ping-pong** - Test-driven cycles with human review gates
2. **agentic production** - Fresh subagent per task, automated review, human gates
3. **agentic prototype** - Subagent per task, automated review, no human gates
```

Wait for their choice, lock it, then invoke the mapped skill with the same routing map above.
