---
name: prototype-driven-development
description: Execute implementation plans for prototypes and throwaway code with automated reviews but no human-in-the-loop gates
disable-model-invocation: true
---

# Prototype-Driven Development

Execute plan using subagent-driven development workflow **without human review gates**. For throwaway code, prototypes, tooling, and internal scripts that won't be peer-reviewed or go to production.

**Core principle:** Same rigorous automated review (spec + quality), but no human gate — continuous execution to completion.

**This is subagent-driven-development with one change: no human approval step before commits.**

## When to Use

**Use for:**
- Personal tools and scripts
- Prototypes and proof-of-concepts
- Throwaway exploratory code
- Internal automation that won't be peer-reviewed
- Code that's explicitly scoped as "not production ready"

**NEVER use for:**
- Code that will be peer-reviewed
- Code merging to a shared/legacy codebase
- Anything shipping to production
- Changes touching authentication, security, or payment flows
- **When in doubt, use the production workflow (subagent-driven-development)**

## The Process

Follow **superpowers:subagent-driven-development** exactly, with these deltas:

### What's Different

1. **No human review gate before commits.** After spec + quality reviews pass, coordinator commits immediately.
2. **Continuous execution resumes.** Execute all tasks without stopping (no per-task human gate).
3. **No final `/code-review`.** The multi-model adversarial review at the end is skipped (expensive and unnecessary for throwaway code).

### What's the Same

- Fresh subagent per task
- Implementer doesn't self-commit (coordinator commits)
- Two-stage automated review per task: spec compliance, then code quality
- Both reviews operate on uncommitted diffs
- Coordinator composes commit messages
- Self-review, test-driven development, all quality practices

## Workflow Diagram

The workflow is identical to subagent-driven-development through the quality review step. Then:

```
Code quality reviewer approves? 
  → yes → Coordinator commits changes (NO human gate)
  → Mark task complete
  → More tasks? 
    → yes → Next task
    → no → Use superpowers:finishing-a-development-branch (skip /code-review)
```

See subagent-driven-development/SKILL.md for the full process diagram — mentally remove the yellow "Present to human" and "Human approves?" nodes.

## Example Workflow

```
You: I'm using Prototype-Driven Development to execute this plan.

[Read plan, extract tasks, create TodoWrite]

Task 1: Add config parser

[Dispatch implementer with full task text + context]
Implementer:
  - Implemented config parser
  - 3/3 tests passing
  - Ready for review (NOT committed)

[Dispatch spec reviewer on uncommitted diff]
Spec reviewer: ✅ Spec compliant

[Dispatch quality reviewer on uncommitted diff]
Quality reviewer: ✅ Approved

[Coordinator commits immediately — no human gate]
git commit -m "feat: add config parser

Parses YAML config files with validation.

Tested: 3/3 tests passing"

[Mark Task 1 complete]

Task 2: CLI entry point
...

[After all tasks complete — skip /code-review]
[Use superpowers:finishing-a-development-branch]
Done!
```

## Prompt Templates

Use the same templates as subagent-driven-development:

- `../subagent-driven-development/implementer-prompt.md` - Dispatch implementer
- `../subagent-driven-development/spec-reviewer-prompt.md` - Spec compliance review
- `../subagent-driven-development/code-quality-reviewer-prompt.md` - Code quality review

No modifications needed — the implementer still doesn't commit, and reviewers still work on uncommitted diffs. The only difference is the coordinator's behavior after reviews pass.

## Red Flags

**Never:**
- Use prototype mode for production code
- Use prototype mode for code that will be peer-reviewed
- Use prototype mode for security-sensitive changes
- Use prototype mode for shared/legacy codebases
- Skip the automated reviews (spec + quality)
- Let the implementer commit (coordinator always commits)
- Rationalize that "this is probably prototype-quality" — when in doubt, use production workflow

**If someone will read this code in a code review, use subagent-driven-development, not this skill.**

## Integration

**Required workflow skills:**
- **superpowers:subagent-driven-development** - This skill is a delta on top of that workflow
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **superpowers:test-driven-development** - Subagents follow TDD for each task

**Alternative workflow:**
- **superpowers:subagent-driven-development** - Use for production code (human review gates)
- **superpowers:executing-plans** - Use for parallel session with manual checkpoints

Base directory for this skill: file:///Users/twhitney/workspace/superpowers/calm-frost/skills/prototype-driven-development
Relative paths in this skill (e.g., scripts/, reference/) are relative to this base directory.
