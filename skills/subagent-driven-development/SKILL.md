---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
disable-model-invocation: true
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) + human review gate before commit = high quality, verified iteration

**Human review workflow:** After implementer completes work and both reviews (spec + quality) pass, STOP and present the changes for human review. Only after human approval should you commit. This happens once per task before moving to the next task.

**For throwaway/prototype work:** If the code won't be peer-reviewed or go to production (personal tools, prototypes, throwaway exploratory code), see **superpowers:prototype-driven-development** — same workflow without the human gates.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Stay in this session?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
    "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
}
```

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Two-stage review after each task: spec compliance first, then code quality
- Human review gate before each commit (coordinator presents changes, human approves, coordinator commits)

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task (single-pass)";
        "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests, self-reviews (NO COMMIT)" [shape=box];
        "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [shape=box];
        "Coordinator triages spec findings, dispatches implementer to fix spec gaps (once)" [shape=box];
        "Dispatch code-reviewer + writing-quality-reviewer in parallel (one message)" [shape=box];
        "Coordinator merges + triages findings, resolves conflicts" [shape=box];
        "Coordinator dispatches implementer to apply accepted fixes (once)" [shape=box];
        "Present applied-fix diff + summary to human for review" [shape=box style=filled fillcolor=yellow];
        "Human approves?" [shape=diamond style=filled fillcolor=yellow];
        "Address human feedback" [shape=box];
        "Coordinator commits changes" [shape=box];
        "Mark task complete in TodoWrite" [shape=box];
    }

    "Read plan, extract all tasks with full text, note context, create TodoWrite" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Run /code-review with full diff of all changes" [shape=box];
    "Surviving findings?" [shape=diamond];
    "Dispatch implementer subagent to fix code review findings" [shape=box];
    "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, extract all tasks with full text, note context, create TodoWrite" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, self-reviews (NO COMMIT)" [label="no"];
    "Implementer subagent implements, tests, self-reviews (NO COMMIT)" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)";
    "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" -> "Coordinator triages spec findings, dispatches implementer to fix spec gaps (once)";
    "Coordinator triages spec findings, dispatches implementer to fix spec gaps (once)" -> "Dispatch code-reviewer + writing-quality-reviewer in parallel (one message)";
    "Dispatch code-reviewer + writing-quality-reviewer in parallel (one message)" -> "Coordinator merges + triages findings, resolves conflicts";
    "Coordinator merges + triages findings, resolves conflicts" -> "Coordinator dispatches implementer to apply accepted fixes (once)";
    "Coordinator dispatches implementer to apply accepted fixes (once)" -> "Present applied-fix diff + summary to human for review";
    "Present applied-fix diff + summary to human for review" -> "Human approves?";
    "Human approves?" -> "Address human feedback" [label="no"];
    "Address human feedback" -> "Present applied-fix diff + summary to human for review" [label="re-present"];
    "Human approves?" -> "Coordinator commits changes" [label="yes"];
    "Coordinator commits changes" -> "Mark task complete in TodoWrite";
    "Mark task complete in TodoWrite" -> "More tasks remain?";
    "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
    "More tasks remain?" -> "Run /code-review with full diff of all changes" [label="no"];
    "Run /code-review with full diff of all changes" -> "Surviving findings?";
    "Surviving findings?" -> "Dispatch implementer subagent to fix code review findings" [label="yes"];
    "Dispatch implementer subagent to fix code review findings" -> "Run /code-review with full diff of all changes" [label="re-review"];
    "Surviving findings?" -> "Use superpowers:finishing-a-development-branch" [label="no"];
}
```

## The Per-Task Review Cycle Is Single-Pass

Each per-task reviewer (spec-review, code-review, writing-quality) runs **once**. The coordinator dispatches the implementer **once** to fix that cycle's findings, then the human gate verifies. There are no per-task re-review loops.

**Scope guardrail:** single-pass applies ONLY to the per-task cluster above. The final `/code-review` (after all tasks) keeps its own multi-pass re-review loop, and `/council` is untouched. Never remove the `Run /code-review → Surviving findings? → fix → re-review` edges or the "Skip the final `/code-review`" Red Flag.

### The coordinator

"The coordinator" is the main SDD orchestrator session — the top-level agent that reads the plan, dispatches subagents, and runs `git commit`. It holds `task` (to dispatch) and `bash`/`edit` **only to commit and orchestrate — never to author code or fix findings**. It turns findings into fixes ONLY by dispatching the `implementer` subagent (consistent with the existing invariant that the coordinator delegates all code changes). Triage is a decision, not an edit.

### Parallel dispatch

Dispatch `code-reviewer` and `writing-quality-reviewer` as two `Task` calls in one assistant message. If the harness runs them concurrently, that is a latency win; if it serialises them, the outcome is identical (two independent finding lists, then merge). Parallelism is a latency optimisation, not a correctness requirement.

### Merge + triage rule (quality stage)

- Merge the two reviewers' outputs into one list, severity-ordered (Critical first), preserving each finding's original severity. The `code-reviewer` uses **Minor** as its lowest tier and the writing-quality reviewer uses **Suggestion**; treat **Minor** and **Suggestion** as the same lowest tier for triage.
- A finding belongs to whichever reviewer flagged it. Two findings on the same `file:line` from different reviewers are both real — keep both.
- Apply all Critical and Important findings. Apply Suggestions too, EXCEPT a Suggestion is dropped only when (a) applying it would conflict with a Critical/Important finding, or (b) it targets generated or third-party code. List every dropped Suggestion in the human-gate summary as "not applied, reason: [a|b]".
- **Conflict resolution (narrow):** a conflict exists only when applying one finding's fix would violate the other's rule (e.g. code-reviewer wants a "why" comment; writing-quality rejects its wording). Mere colocation is NOT a conflict. On a real conflict, satisfy the higher-severity finding and adopt the lower-severity finding's own supplied replacement text to reword it. The coordinator needs no STE knowledge — each writing-quality finding carries a compliant replacement.
- Dispatch the implementer once with the triaged, conflict-resolved list, then present to the human gate.

### Spec-gap triage rule

Symmetric with the quality rule, applied to the spec-reviewer's output after spec-review (once):
- Apply all spec-reviewer Critical and Important findings. Apply Suggestions unless they conflict with the plan.
- A genuinely ambiguous spec gap (fix depends on intent the plan does not settle) is NOT guessed — surface it at the human gate.
- Dispatch the implementer once, then proceed to the quality stage. No spec re-review.

### Implementer dispatch for applying fixes

The coordinator applies both spec-gap fixes and quality fixes by dispatching the existing `implementer` subagent via `implementer-prompt.md` — no new template. The triaged finding list (each item: `file:line`, what to change, suggested replacement text) is the task description. The implementer edits; it does not re-derive findings.

### Reviewer failure / unreconcilable conflict

SDD's implementer BLOCKED cases do not map to a read-only reviewer. Use this instead:
- **Errored / timed-out reviewer:** re-dispatch once. If it fails again, proceed with the other reviewer's findings and note the failure in the human-gate summary. Do not block the task.
- **Malformed output** (a finding missing `file:line`, severity, or — for writing-quality — a replacement): treat that finding as unusable, list it in the human-gate summary as "could not auto-apply," and apply the well-formed findings normally.
- **Finding without a usable replacement:** the coordinator cannot author a fix (no STE knowledge), so it surfaces the finding to the human gate rather than dropping it silently.
- **Unreconcilable conflict:** if two Critical findings genuinely cannot both be satisfied, do NOT guess — present both to the human at the gate.

### Human gate presentation

Because single-pass makes the human gate the sole verification of applied fixes, present the **actual diff of what the coordinator applied** (not just a "spec ✅ / quality ✅" stat line), plus the fix summary (which findings applied, which dropped and why, any items surfaced for a decision).

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture, design, and review tasks**: use the most capable available model.

**Task complexity signals:**
- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent
- `./writing-quality-reviewer-prompt.md` - Dispatch writing-quality reviewer subagent (parallel with code quality)

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: docs/superpowers/plans/feature-plan.md]
[Extract all 5 tasks with full text and context]
[Create TodoWrite with all tasks]

Task 1: Hook installation script

[Get Task 1 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/superpowers/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Ready for review (NOT committed)

[Dispatch spec compliance reviewer on uncommitted diff]
Spec reviewer: ✅ Spec compliant - all requirements met, nothing extra

[Dispatch code quality reviewer on uncommitted diff]
Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.

You: [Present changes to human]
  Changes ready for review:
  - Modified: src/commands/install-hook.sh
  - Added: tests/install-hook.test.sh
  - All tests passing (5/5)
  - Spec compliant ✅
  - Quality approved ✅
  
  git diff --stat shows 2 files changed, 87 insertions(+)
  
  Review and approve to commit?

Task 2: Recovery modes

[Get Task 2 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Human: Approved. Commit it.

[Coordinator commits with message composed from task]
git commit -m "feat: add install-hook command with --force flag

Implements hook installation at user level (~/.config/superpowers/hooks/)
with optional --force flag to overwrite existing hooks.

Tested: 5/5 tests passing"

[Mark Task 1 complete]

Task 2: Recovery modes

[Get Task 2 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Ready for review (NOT committed)

[Dispatch spec compliance reviewer on uncommitted diff]
Spec reviewer: ❌ Missing progress reporting; extra --json flag not requested

[Coordinator triages: apply both. Dispatches implementer once to fix spec gaps]
Implementer: Removed --json flag, added progress reporting

[Dispatch code-reviewer ∥ writing-quality-reviewer in one message]
Code reviewer: Important — magic number (100)
Writing-quality reviewer: Suggestion — comment uses "should"; replacement: "Adjust the interval when the run is slow."

[Coordinator merges + triages, dispatches implementer once to apply accepted fixes]
Implementer: Extracted PROGRESS_INTERVAL constant; reworded comment

You: [Present applied-fix diff + summary to human]
  Modified: src/recovery.sh; Added: tests/recovery.test.sh (8/8 passing)
  Applied: PROGRESS_INTERVAL extraction; comment reworded (STE-7). Dropped: none.
  git diff shown below. Review and approve to commit?

Human: Approved. Commit it.

[Coordinator commits with message composed from task]
git commit -m "feat: add verify and repair recovery modes

Implements verify mode to check hook integrity and repair mode
to fix corrupted hooks with progress reporting every 100 items.

Tested: 8/8 tests passing"

[Mark Task 2 complete]

...

[After all 5 tasks complete, all committed after human review]
[Run /code-review with git diff of all changes since start]
Code review debate:
  Reviewer A: Found 2 issues (magic constant, missing error handling)
  Reviewer B: Challenged magic constant finding
  Rebuttal: Magic constant finding dropped, error handling confirmed
  Synthesis: 1 surviving finding - missing error handling in parser

[Present to human, get approval]
[Dispatch implementer to fix, get human review, commit]

[Re-run /code-review]
Code review debate: No surviving findings

[Use superpowers:finishing-a-development-branch]
Done!
```

## Final Code Review

After all tasks are complete (all individually reviewed and committed), run a multi-model critical code review of the entire implementation.

**Run:** `/code-review` with the full `git diff` of all changes since the plan started (use the base commit SHA captured at the start).

The `/code-review` command has its own logic, just run it as instructed and wait for the response.

**After the debate completes:**
- If there are surviving findings, present them to human, get approval to proceed
- Dispatch an implementer subagent to fix them
- Present fixes for human review
- Human approves, then commit
- Re-run `/code-review` after fixes
- Repeat until clean
- Then proceed to finishing-a-development-branch

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**vs. Executing Plans:**
- Same session (no handoff)
- Human review gate ensures quality before commits
- Review checkpoints automatic

**Efficiency gains:**
- No file reading overhead (controller provides full text)
- Controller curates exactly what context is needed
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)

**Quality gates:**
- Self-review catches issues before handoff
- Per-task review: spec compliance gate, then parallel code-quality + writing-quality reviewers; the coordinator triages and applies fixes before the human gate (all on uncommitted code)
- Human review before each commit
- Multi-model critical final code review (findings must survive cross-examination)
- Per-task cycle is single-pass; the human gate verifies applied fixes. The final `/code-review` re-reviews until clean.
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- More subagent invocations (implementer + 2 reviewers per task)
- Controller does more prep work (extracting all tasks upfront)
- Per-task quality stage runs two reviewers (code-reviewer + writing-quality-reviewer); single-pass removes the previously unbounded per-task re-review iterations.
- Human review adds latency per task
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Start implementation on main/master branch without explicit user consent
- Skip reviews (spec compliance OR code quality OR human review)
- Skip the final `/code-review` (per-task reviews passing doesn't replace holistic review)
- Proceed with unfixed issues
- Commit before human review
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- Add or expand comments in a task's code blocks. The plan's code-block comments are intentionally concise; pass them through unchanged and keep rationale in the surrounding prose, not in the code.
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (spec reviewer found issues = not done)
- Add per-task re-review loops. The per-task review cycle is single-pass: the coordinator dispatches the implementer once to fix findings, then the human gate verifies. (This does NOT apply to the final `/code-review`, which keeps its re-review loop.)
- Let implementer self-review replace actual review (both are needed)
- **Start code quality review before spec compliance is ✅** (wrong order)
- Move to next task while either review has open issues

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If a per-task reviewer finds issues:**
- The coordinator triages, then dispatches the implementer once to apply the accepted fixes
- The human gate verifies the applied fixes (no per-task re-review)
- The final `/code-review` still re-reviews until clean — that loop is unchanged

**If human feedback received:**
- Address concerns fully
- Re-present for approval
- Don't commit until approved

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:requesting-code-review** - Code review template for reviewer subagents
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **superpowers:test-driven-development** - Subagents follow TDD for each task

**Alternative workflows:**
- **superpowers:executing-plans** - Use for parallel session instead of same-session execution
- **superpowers:prototype-driven-development** - Use for throwaway/prototype work without human review gates

Base directory for this skill: file:///Users/twhitney/workspace/superpowers/calm-frost/skills/subagent-driven-development
Relative paths in this skill (e.g., scripts/, reference/) are relative to this base directory.
Note: file list is sampled.

<skill_files>
<file>/Users/twhitney/workspace/superpowers/calm-frost/skills/subagent-driven-development/code-quality-reviewer-prompt.md</file>
<file>/Users/twhitney/workspace/superpowers/calm-frost/skills/subagent-driven-development/implementer-prompt.md</file>
<file>/Users/twhitney/workspace/superpowers/calm-frost/skills/subagent-driven-development/spec-reviewer-prompt.md</file>
</skill_files>
