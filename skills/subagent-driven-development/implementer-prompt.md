# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent. Use the `implementer`
subagent type, which runs on a different model for cost-efficient execution and
has built-in self-review behavior (see `agents/implementer.md`).

```
Task tool (subagent_type: "implementer"):
  description: "Implement Task N: [task name]"
  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
         model silently inherits the session's most expensive one]
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    Read your task brief first: [BRIEF_FILE]
    It contains the full task text from the plan.

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    Work from: [directory]

    ## After Review Findings

    If a reviewer finds issues and you fix them, re-run the tests that cover
    the amended code and append the results to your report file. Reviewers
    will not re-run tests for you — your report is the test evidence.

    ## Report Format

    Write your full report to [REPORT_FILE]:
    - What you implemented (or what you attempted, if blocked)
    - What you tested and test results
    - **TDD Evidence** (if TDD was required for this task):
      - RED: command run, relevant failing output before implementation, and why the failure was expected
      - GREEN: command run and relevant passing output after implementation
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns

    Then report back with ONLY (under 15 lines — the detail lives in the
    report file):
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - One-line test summary (e.g. "14/14 passing, output pristine")
    - Your concerns, if any
    - The report file path

    If BLOCKED or NEEDS_CONTEXT, put the specifics in the final message
    itself — the controller acts on it directly.

    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
    information that wasn't provided. Never silently produce work you're unsure about.

    Do NOT commit your work — the coordinator handles commits after human review.
```

The `implementer` agent already knows how to:

- Ask clarifying questions before starting
- Follow TDD when the task specifies it
- **Do NOT commit work** - the coordinator handles commits after human review
- Self-review for completeness, quality, and discipline
- Report back in a standard format

You only need to provide the task description and context. Don't repeat
instructions the agent already has.

Code blocks in the task are intentionally concise. Reproduce their comments as
you adapt the code — do not editorialize, expand, or add narration. Follow the
project's comment rules for anything you write yourself.
