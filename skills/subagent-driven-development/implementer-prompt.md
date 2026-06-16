# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent. Use the `implementer`
subagent type, which runs on a different model for cost-efficient execution and
has built-in self-review behavior (see `agents/implementer.md`).

```
Task tool (subagent_type: "implementer"):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    Work from: [directory]
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
