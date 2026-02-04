---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), mcp__codex__codex, mcp__codex__codex-reply, Skill(codex-mcp)
description: Create git commits with Codex review
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

### Step 1: Codex Review

Use the codex-mcp skill to send the git diff to Codex for review. Ask Codex to:

1. **Review the changes** for issues, categorized by priority:
   - **P0 (Critical)**: Security vulnerabilities, data loss risks, breaking changes
   - **P1 (High)**: Bugs, logic errors, concurrency issues
   - **P2 (Medium)**: Code quality, performance concerns, missing error handling
   - **P3 (Low)**: Style issues, minor improvements, documentation gaps

2. **Recommend commit structure**: Based on the scope and nature of changes, Codex should recommend:
   - How many commits to create (avoid monolithic commits OR overly granular commits)
   - What files/changes belong in each commit
   - Suggested commit message for each

### Step 2: Fix Issues

If Codex identifies any P0 or P1 issues:
1. Fix them before committing
2. Re-run Codex review on the fixed changes
3. Only proceed to commits once P0/P1 issues are resolved

P2/P3 issues can be noted but don't block the commit.

### Step 3: Create Commits

Based on Codex's commit structure recommendation:
1. Stage files for each logical commit
2. Create commits with clear, conventional commit messages
3. Follow the repo's existing commit message style (see recent commits above)

### Output Format

Report to user:
```
## Codex Review Summary

**Issues Found:**
- P0: [count] - [brief list if any]
- P1: [count] - [brief list if any]
- P2: [count] - [brief list if any]
- P3: [count] - [brief list if any]

**Fixes Applied:** [list any P0/P1 fixes made]

**Commit Plan:** [X commits]
1. [commit message] - [files]
2. [commit message] - [files]
...

**Commits Created:** [list of commit hashes and messages]
```
