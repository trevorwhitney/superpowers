---
name: tdd-ping-pong
description: Use when executing a test-only plan where the agent writes failing tests and the human writes implementation between red and green cycles
disable-model-invocation: true
---

# TDD Ping-Pong Development

Execute test-only plans in a human-in-the-loop RED/GREEN cadence.

**Core principle:** Agent owns tests and verification. Human owns production implementation between each verified RED and GREEN.

**Required:** Load superpowers:test-driven-development at workflow start to establish RED/GREEN rigor and testing practices.

## Per-Cycle Loop

1. Write one failing test (plus minimal compile scaffolding only when required: placeholders must fail loudly with panic/throw; zero-value returns are allowed only when language constraints require them and must still preserve a failing path).
2. Run targeted test and verify a valid RED outcome.
3. Pause for human implementation.
4. Human says continue.
5. Re-run targeted test and verify GREEN for the intended reason.
6. Perform quick review of the latest-cycle diff (fallback: all uncommitted changes in the current task).
7. If concern found, ask whether to add a new test for it or move on.
8. If no concern, continue to next planned cycle.

## Prompts

Pause prompt:
"Cycle <n> is RED and verified. Please implement the minimal production code to make this test pass, then tell me to continue."

Concern prompt:
"I found a concern: <summary>. Should I add a new test for it, or move on with the plan?"

## Quick Review Rules

- Quick review is inline in the coordinator session (no multi-model fan-out).
- It checks obvious correctness, safety, and maintainability risks.
- In fallback/full-diff review, report most-recent-cycle concerns first.
- If the human chooses move on, record a deferred concern entry.

## Failure Handling

- If test is still RED after human continue: report failure reason and stay on current cycle.
- If test passes for the wrong reason: treat cycle as unresolved, explain why, and request correction.
- If earlier tests regress within the current task: require regression fix before moving on.

## Task Boundaries

- Task is complete when planned tests for that task are green and concerns are addressed or explicitly deferred.
- At task end, summarize diff plus deferred concerns, pause for human approval, and create a signed commit.
- Do not create task commits on `main` or `master` without explicit human approval.

## Plan Boundary

- After all tasks, request code review with `/code-review` on the complete diff.
- After review, invoke superpowers:finishing-a-development-branch for merge/branch decisions.

## Integration

- Planning source: superpowers:writing-plans
- RED/GREEN rigor: superpowers:test-driven-development
- Terminal handoff: superpowers:finishing-a-development-branch
- Alternative execution workflows: superpowers:subagent-driven-development, superpowers:prototype-driven-development, superpowers:executing-plans
