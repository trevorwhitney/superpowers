---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring skill tool invocation before ANY response including clarifying questions
disable-model-invocation: true
---

# Using Superpowers

You have a library of skills loaded via the `skill` tool.

<SUBAGENT-STOP>If you were dispatched as a subagent for a specific task, skip this skill.</SUBAGENT-STOP>

## The Rule

Invoke relevant skills BEFORE any response or action — including clarifying questions. If there is even a 1% chance a skill applies, call `skill("name")` to load it. Some loadable skills are not listed in `<available_skills>` — they get pulled in by other skills via natural-language references like *"invoke writing-plans skill"*. If you call a name that doesn't exist, the tool returns the full available-names list so you can recover.

When a skill fires:

1. Announce: *"Using [skill] to [purpose]"*
2. If the skill has a checklist, create a TodoWrite entry per item before proceeding.
3. Follow the skill exactly. Rigid skills (TDD, debugging) must not be adapted away; flexible skills (patterns) adapt to context — the skill body says which.

## Priority Order

User instructions (CLAUDE.md, AGENTS.md, direct requests) > skills > default system prompt. If user instructions conflict with a skill, follow the user.

## When Multiple Skills Apply

Process skills first (brainstorming, systematic-debugging) determine HOW to approach the task. Implementation skills second guide execution. *"Let's build X"* → brainstorming first. *"Fix this bug"* → debugging first.
