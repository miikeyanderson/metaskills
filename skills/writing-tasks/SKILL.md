---
name: writing-tasks
description: Create and execute writing-tasks using a multi-model council - Claude plans tasks, Codex and Gemini review each task and each completed change, and all work is represented as native Tasks for Claude Code.
---

# Council Write Tasks

## Overview

Use this skill whenever you have a multi-step writing or refactor request and want a multi-model council (Claude + Codex-MCP + Gemini-MCP) to plan and review the work. Tasks are the persistent, structured way for Claude Code (and its subagents) to track work across sessions, so this skill always expresses the plan as Tasks first, then executes them one by one.

Use it:

- When starting a new Claude Code session with a multi-step writing or doc change.
- Mid-session when a "big refactor" or complex doc request appears.
- Any time the user request clearly requires more than one step and benefits from Codex/Gemini review.

**Announce at start (in-session):**

> "I'm using the council-write-tasks skill with writing-tasks-with-codex-and-gemini. I will create native Tasks for this plan, have Codex-MCP and Gemini-MCP review them, then execute one Task at a time with council reviews."

---

## Input Pattern

This skill assumes the user starts with something like:

```text
I want you to create tasks for this plan:

[PASTED PLAN / SPEC / REQUEST]

I want you to use the writing-tasks-with-codex-and-gemini skill.
```

If the user does not provide a clear plan/spec, first ask brief clarification questions to get enough detail to define good Tasks (goal, scope, constraints).

---

## Task File Header

When you materialize the plan into a file (for example, `docs/tasks/writing/YYYY-MM-DD-<topic-name>.md`), start with:

```markdown
# [Document / Artifact Name] Council Writing Tasks

**Goal:** [One sentence describing what this work should achieve]

**Audience:** [Who this is for, what they know, what they care about]

**Scope:** [What is in/out of scope for this work]

***
```

This mirrors the `writing-tasks` format but emphasizes the council workflow.

---

## Task List Structure (Native Tasks Style)

Represent the work as parent tasks with bite-sized steps, in the same structure as `writing-tasks`:

```markdown
- [ ] Parent Task Title – "[High-level action or outcome]"
  - [ ] 1. [Atomic step (2–5 minutes), starts with a verb]
  - [ ] 2. [Atomic step (2–5 minutes), starts with a verb]
  - [ ] 3. [Atomic step (2–5 minutes), starts with a verb]
```

Guidelines (same as writing-tasks):

- Parent tasks group related steps toward one outcome.
- Steps are strictly ordered, one observable action each.
- Prefer more, smaller tasks over a few huge ones; encode dependencies explicitly when needed.

In parallel, mirror these into Claude Code's Tasks system:

- Create a Task per parent task with title, description, status, and any dependencies.
- Treat the Tasks list as the canonical backlog for this work.

---

## Council Workflow (Codex + Gemini)

### Phase 1 – Plan Tasks

1. Parse the user's plan/spec and draft the full writing-tasks list using the structure above.
2. Create or update the project's Tasks backlog to reflect this list (one Task per parent task, with dependencies where relevant).
3. Present the draft tasks to the user briefly for sanity check (optional but recommended for big jobs).

### Phase 2 – Council Review of Plan

After you have a draft task list:

1. Call **codex-mcp** and **gemini-mcp** to review the *plan itself* (not the code yet).
   - Ask them to check: coverage, ordering, risk areas, missing steps, and over-scoped tasks.
2. Synthesize their feedback into a single, reconciled update to the task list.
   - Resolve disagreements explicitly; prefer safer, clearer, more testable tasks.
3. Show the updated task list and a short summary of council feedback to the user.
4. After user confirmation, freeze the plan and proceed to execution.

Prompt shape to Codex/Gemini (conceptual):

> "Here is a task plan for [topic]. Review for completeness, ordering, risk, and clarity. Suggest concrete edits to task titles and steps, not vague advice."

---

## Execution Loop (One Task at a Time)

Once the plan is confirmed:

For each Task, in dependency-safe order:

1. **Select next Task**
   - Use the Tasks backlog to pick the highest-priority unblocked Task.
   - Announce: which Task you're executing and show its steps.

2. **Execute steps**
   - Perform each numbered step in order (edit files, update docs, run tools).
   - Keep changes small and commit incrementally where appropriate.

3. **Per-task Council Review**
   - After completing the Task's steps but before finalizing:
     - Call codex-mcp and gemini-mcp with the relevant diffs/files.
     - Ask them to review only the scope of this Task (correctness, clarity, style, regressions).
   - Reconcile their feedback:
     - If they agree on issues → fix those before continuing.
     - If they disagree → briefly analyze and choose a conservative, safe option.

4. **Confirm and update**
   - Once changes look good with no outstanding issues:
     - Mark the Task as done in the Tasks backlog.
     - Optionally note key decisions/risks in the Task's metadata/notes.
   - Then move on to the next Task and repeat the loop.

Important constraints:

- Never silently skip a Task or a step.
- If a Task expands, split it into smaller Tasks and update dependencies before proceeding.

---

## Final Council Review (After Last Task)

After the last Task is finished:

1. Call codex-mcp and gemini-mcp for a **final high-level review** of:
   - The overall change (diff set, key files).
   - Whether the original Goal/Scope have been met.
   - Any remaining risks, follow-up tasks, or cleanup.
2. Synthesize a concise "task plan postmortem":
   - What we did, what the council flagged, what follow-ups (if any) should become new Tasks.
3. Create Tasks for any follow-up work instead of burying it in prose.

Then tell the user something like:

> "Council workflow complete: all planned Tasks are done, Codex and Gemini have performed a final review, and follow-up Tasks (if any) are added to the backlog."

---

## Execution Block in the Task File

At the end of each council writing-tasks file, include:

```markdown
## Execution (Council Mode)

These writing tasks are meant to be executed with a council workflow:

1. Use Claude Code Tasks as the source of truth.
2. For each Task:
   - Execute the steps.
   - Ask Codex and Gemini (via MCP) to review the changes for that Task.
   - Address issues, then mark the Task done.
3. After the final Task:
   - Ask Codex and Gemini for a high-level review of the entire plan and outcome.
   - Add any follow-up work as new Tasks.

Do not skip council reviews. If they raise issues repeatedly on similar patterns, consider updating this task list and any relevant guidelines.
```
