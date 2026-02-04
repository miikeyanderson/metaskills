---
name: using-tasks
description: Use when work requires more than one atomic action. Standard execution protocol for all multi-step work.
---

<EXTREMELY-IMPORTANT>
If work requires more than one atomic action, CREATE A TASK before doing work.

**Atomic action** = a single direct operation with no intermediate checkpoint.
If there are 2+ actions, decisions, or checkpoints → use tasks.

**If unsure, create tasks.**
</EXTREMELY-IMPORTANT>

## First 30 Seconds

```
1. TaskList              → See existing tasks
2. Pick or TaskCreate    → Claim next task or create new ones
3. TaskUpdate in_progress → Signal you're starting
4. Do the work
5. TaskUpdate completed   → After verification passes
```

## Tools Reference

| Tool | Purpose | When to Call |
|------|---------|--------------|
| `TaskCreate` | Create new task | Before starting multi-step work |
| `TaskUpdate` | Change status/details | Before starting, after completing |
| `TaskGet` | Get full task details | Before updating (if task may have changed) |
| `TaskList` | List all tasks | Session start, before handoff, before completion claims |

## The Rule

**Create a task for any work beyond one atomic action.**

Set `in_progress` before execution. Update continuously. Complete only after Definition of Done. Max 1 `in_progress` task at a time.

```
┌─────────────────────────────────────────┐
│  User request received                  │
└─────────────────┬───────────────────────┘
                  ▼
┌─────────────────────────────────────────┐
│  More than 1 atomic action?             │
│  Unsure? → Default to YES               │
└─────────────────┬───────────────────────┘
        yes       │        no (single action)
          ↓       │         ↓ just do it
┌─────────────────┴───────────────────────┐
│  TaskCreate for each step               │
│  - subject: imperative, brief           │
│  - description: full requirements       │
│  - activeForm: present continuous       │
└─────────────────┬───────────────────────┘
                  ▼
┌─────────────────────────────────────────┐
│  TaskUpdate → in_progress               │
│  (max 1 at a time per agent)            │
└─────────────────┬───────────────────────┘
                  ▼
┌─────────────────────────────────────────┐
│  Do the work                            │
└─────────────────┬───────────────────────┘
                  ▼
┌─────────────────────────────────────────┐
│  Verify (build + test)                  │
└─────────────────┬───────────────────────┘
                  ▼
┌─────────────────────────────────────────┐
│  TaskUpdate → completed                 │
└─────────────────┬───────────────────────┘
                  ▼
┌─────────────────────────────────────────┐
│  TaskList → find next unblocked task    │
└─────────────────────────────────────────┘
```

## When to Use Tasks

| Situation | Example | Action |
|-----------|---------|--------|
| Feature implementation | "Add dark mode" | TaskCreate per component |
| Bug fix (multi-file) | "Fix login crash" | TaskCreate: reproduce, isolate, fix, test |
| Refactoring | "Extract service layer" | TaskCreate per file/module |
| Plan mode output | Plan approved | TaskCreate from each plan step |
| User numbered list | "1. Do X, 2. Do Y" | TaskCreate per item |
| Migration/batch | "Update 50 files" | TaskCreate per batch |

## When NOT to Use Tasks

- Single atomic action with no follow-up step
- Pure informational response with no execution

## Why This Doesn't Create Busywork

Tasks are execution control, not bureaucracy:
- Prevent dropped steps and hidden partial work
- Make handoffs and restarts reliable
- Reduce context loss across long sessions

Keep friction low:
- 1 task = 1 outcome
- Prefer short subjects
- Close tasks immediately when done
- For tiny 2-step items, use minimal descriptions

### Micro-Task Template

For small multi-step work, keep it minimal:

```
subject: "Rename API client variable"
description: "Update `api` -> `client` in AuthService and callsite"
activeForm: "Renaming API client variable"
```

## Risks and Safeguards

| Risk | Safeguard |
|------|-----------|
| Task sprawl | 1 outcome per task, archive/complete aggressively |
| Status drift | Call `TaskGet` before `TaskUpdate` when resuming |
| Too many active tasks | Max 1 `in_progress` per agent |
| Mechanical overhead | Minimal fields for tiny tasks; detailed descriptions for complex work |

## Task Field Guidelines

| Field | Format | Example |
|-------|--------|---------|
| `subject` | Imperative, brief (5-10 words) | "Add logout button to header" |
| `description` | Full requirements, files, acceptance criteria | "Add button in HeaderView.swift, wire to AuthService.logout(), show confirmation alert before logout" |
| `activeForm` | Present continuous (shown in spinner) | "Adding logout button" |

## Status Workflow

```
pending → in_progress → completed
              ↓              ↓
          (blocked)     (reopen if regression)
              ↓
          deleted (if obsolete)
```

**Rules:**
- `in_progress` BEFORE starting work
- `completed` ONLY after verification passes
- Reopen: `completed → in_progress` if regression found
- `deleted` for obsolete/duplicate tasks
- Call `TaskGet` before `TaskUpdate` if task may have changed

## Definition of Done

Before marking `completed`:
- [ ] Code changes made
- [ ] Build passes
- [ ] Relevant tests pass
- [ ] No regressions introduced
- [ ] (If UI) Visually verified

## Red Flags

| Thought | Reality |
|---------|---------|
| "This is quick, no need for tasks" | Quick things become complex. Track it. |
| "I'll remember where I am" | Context compacts. Tasks persist. |
| "Tasks are overhead" | Lost progress is more overhead. |
| "I'm almost done anyway" | Track completion properly. |
| "Just one more file" | That's a new task. Create it. |
| "I'll create tasks after I start" | Create BEFORE starting. |
| "The user didn't ask for tasks" | Tasks are for YOU, not the user. |

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Giant catch-all task | No progress visibility | Break into 3-7 subtasks |
| Marking complete before verification | False done claims | Always verify first |
| Multiple `in_progress` tasks | Context splitting | One at a time |
| No `activeForm` | Silent spinner | Always include |
| Stale tasks left open | Confusion | Delete or complete |
| Skipping `TaskGet` before update | Stale data | Always check first |

## Task Dependencies

```json
// Task 2 blocked by Task 1
{"taskId": "2", "addBlockedBy": ["1"]}

// Unblock happens automatically when Task 1 completes
```

Check `blockedBy` in TaskList—don't start blocked tasks.

## Example Flows

### Feature Implementation
```
User: "Add user profile page"

TaskCreate: "Create ProfileView skeleton"
TaskCreate: "Add ProfileViewModel with user data"
TaskCreate: "Wire up navigation to profile"
TaskCreate: "Add unit tests for ProfileViewModel"

TaskUpdate "1" → in_progress
[build ProfileView.swift]
TaskUpdate "1" → completed
TaskList → task 2 next
```

### Bug Fix
```
User: "Login button doesn't work on iPad"

TaskCreate: "Reproduce login bug on iPad simulator"
TaskCreate: "Isolate root cause"
TaskCreate: "Fix the bug"
TaskCreate: "Add regression test"

TaskUpdate "1" → in_progress
[reproduce in simulator, document steps]
TaskUpdate "1" → completed
```

### Reopening After Regression
```
[CI reports test failure after task marked complete]

TaskGet "3" → verify current state
TaskUpdate "3" → in_progress (reopen)
[fix regression]
[verify tests pass]
TaskUpdate "3" → completed
```

## Integration with Other Skills

- **verification-before-completion**: Required before `TaskUpdate → completed`
- **Plan mode**: Convert approved plan steps into tasks
- **Subagents**: Use `owner` field to assign tasks to specific agents
