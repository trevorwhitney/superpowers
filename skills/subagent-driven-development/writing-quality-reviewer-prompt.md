# Writing-Quality Reviewer Prompt Template

Use this template when dispatching a writing-quality reviewer subagent.

**Purpose:** Verify changed comments, docstrings, and product-facing docs follow comment style, comment hygiene, and ASD-STE100 Simplified Technical English.

**Dispatch in parallel with the code-quality reviewer (both read-only, one message).**

```
Task tool (subagent_type: "writing-quality-reviewer"):
  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  DIFF_SPEC: Uncommitted working tree changes (use `git diff` and `git status`)
```

**Writing-quality reviewer returns:** findings by severity (Critical/Important/Suggestion), each with file:line, description, suggested fix, and the STE rule number for SimpleEnglish findings.
