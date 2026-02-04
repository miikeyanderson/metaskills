---
name: creating-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Creating Skills

## Overview

**Creating skills IS Test-Driven Development applied to process documentation.**

**Personal skills live in agent-specific directories (`~/.claude/skills` for Claude Code, `~/.codex/skills` for Codex)**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand @tdd before using this skill.

**Complete field reference:** See reference.md for all frontmatter fields, string substitutions, and special features.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future Claude instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## When NOT to Create a Skill

**Stop before you start.** Not every useful pattern deserves a skill. Ask these questions first:

**Reuse frequency:** Will this be used 3+ times across sessions or projects?
- One-off solution → Document in session notes, not a skill
- Project-specific → Consider project CLAUDE.md instead

**Non-obviousness:** Would a competent agent fail without this guidance?
- If Claude already handles it well → No skill needed
- If it's standard practice → No skill needed

**Cross-project value:** Does this apply beyond a single codebase?
- Tightly coupled to one project's structure → Use CLAUDE.md
- General technique → Skill candidate

**Maintenance burden:** Can you commit to testing and updating this?
- Skills rot without periodic review
- Untested skills cause more harm than no skill

**If you answered "no" to any of these, don't create a skill.**

## Skill Types and Configuration

Different skill types benefit from different configurations. Choose based on your use case:

### Reference Skills (knowledge/conventions)

**Use case:** Style guides, API patterns, domain knowledge

**Typical configuration:**
```yaml
---
name: api-conventions
description: Use when writing or reviewing API endpoints
user-invocable: true
---
```

**Key options:**
- Keep `context: inline` (default) - runs alongside conversation
- Consider `user-invocable: false` for background knowledge Claude should use but users shouldn't invoke directly

### Task Skills (actions with side effects)

**Use case:** Deploy, commit, send messages, external API calls

**Typical configuration:**
```yaml
---
name: deploy
description: Use when deploying to production
disable-model-invocation: true
context: fork
agent: general-purpose
allowed-tools: Bash(*)
argument-hint: "[environment]"
---

Deploy to $ARGUMENTS environment:
1. Run tests
2. Build
3. Push
```

**Key options:**
- `disable-model-invocation: true` - CRITICAL for side effects, prevents auto-triggering
- `context: fork` - runs in isolated subagent
- `allowed-tools` - pre-approve tools for the workflow
- `argument-hint` - shows users what arguments to pass
- `$ARGUMENTS` - access user-provided arguments

### Research/Exploration Skills

**Use case:** Codebase exploration, deep analysis, investigation

**Typical configuration:**
```yaml
---
name: deep-research
description: Use when thoroughly researching a topic across the codebase
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
argument-hint: "[topic]"
---

Research $ARGUMENTS thoroughly using ultrathink:
1. Find relevant files
2. Analyze patterns
3. Summarize findings
```

**Key options:**
- `context: fork` with `agent: Explore` - specialized for codebase exploration
- `allowed-tools: Read, Grep, Glob` - read-only mode
- `ultrathink` keyword - enables extended thinking

### Dynamic Context Skills

**Use case:** Skills that need current data (git status, PR info, etc.)

**Typical configuration:**
```yaml
---
name: pr-summary
description: Use when summarizing a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Current PR context

- PR diff: !\`gh pr diff\`
- Comments: !\`gh pr view --comments\`
- Changed files: !\`gh pr diff --name-only\`

Summarize this PR.
```

**Key options:**
- `!\`command\`` syntax - executes shell commands BEFORE Claude sees the skill
- Output replaces the placeholder - Claude receives actual data

**Security for dynamic injection:**
- **Failure handling:** What if the command fails? Add fallback text or handle gracefully
- **Output size:** Large outputs bloat context. Use `| head -100` or similar limits
- **Sensitive data:** Don't inject secrets, tokens, or PII into skill content
- **Command safety:** Avoid commands that modify state - injection runs every time skill loads

```yaml
# Safe pattern with fallback
- PR diff: !\`gh pr diff 2>/dev/null || echo "No PR context available"\`
- Recent commits: !\`git log --oneline -5 2>/dev/null || echo "Not a git repo"\`
```

### Skills with Lifecycle Hooks

**Use case:** Validation before/after skill runs

**Typical configuration:**
```yaml
---
name: safe-deploy
description: Use when deploying with pre-flight checks
disable-model-invocation: true
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-deploy.sh"
---
```

**Key options:**
- `hooks` - attach automation to skill lifecycle
- See hooks/reference.md for hook configuration

## Configuration Decision Guide

Ask these questions when creating a skill:

**1. Does this skill have side effects?**
- Yes → Add `disable-model-invocation: true`
- No → Leave default (Claude can auto-invoke)

**2. Should this run in isolation or with conversation context?**
- Isolation (task execution) → Add `context: fork`
- With context (reference/guidance) → Leave default (`inline`)

**3. Does it need specific tools?**
- Pre-approve safe tools → Add `allowed-tools: Tool1, Tool2`
- Restrict to read-only → `allowed-tools: Read, Grep, Glob`

**4. Does it accept arguments?**
- Yes → Add `argument-hint: "[what-to-pass]"`
- Use `$ARGUMENTS` or `$0`, `$1` in content

**5. Does it need current data?**
- Yes → Use `!\`command\`` for dynamic injection

**6. Should users see it in the menu?**
- No (background knowledge) → Add `user-invocable: false`
- No (Claude shouldn't auto-use) → Add `disable-model-invocation: true`

**7. Does it need deep analysis?**
- Yes → Include `ultrathink` in content

**8. Does it need validation/automation?**
- Yes → Add `hooks` configuration

## SKILL.md Structure

**Frontmatter (YAML):**
```yaml
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions]
# Optional power features - see reference.md for all options:
# argument-hint: "[expected-args]"
# disable-model-invocation: true
# user-invocable: false
# allowed-tools: Read, Grep, Glob
# context: fork
# agent: Explore
# model: claude-3.7-sonnet
# hooks: ...
---
```

**Content structure:**
```markdown
# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
Bullet list with SYMPTOMS and use cases
When NOT to use

## Core Pattern (for techniques/patterns)
Before/after code comparison

## Quick Reference
Table or bullets for scanning

## Implementation
Use $ARGUMENTS for user input
Use !\`command\` for dynamic data

## Common Mistakes
What goes wrong + fixes
```

## The Description Field (CSO)

**CRITICAL: Description = When to Use, NOT What the Skill Does**

The description should ONLY describe triggering conditions. Do NOT summarize the skill's workflow.

**Why this matters:** When a description summarizes workflow, Claude may follow the description instead of reading the full skill. Testing revealed a description saying "code review between tasks" caused Claude to do ONE review, even though the skill showed TWO reviews.

```yaml
# ❌ BAD: Summarizes workflow
description: Use when executing plans - dispatches subagent per task with code review

# ✅ GOOD: Just triggering conditions
description: Use when executing implementation plans with independent tasks
```

**Content guidelines:**
- Start with "Use when..."
- Include specific triggers, symptoms, situations
- Write in third person
- **NEVER summarize the skill's process or workflow**
- Keep under 500 characters

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Production code** | Skill document (SKILL.md) |
| **Test fails (RED)** | Agent violates rule without skill |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing? Delete it. Start over.

**No exceptions:**
- Not for "simple additions"
- Not for "just adding a section"
- Don't keep untested changes as "reference"
- Delete means delete

## Scoping (Before You Write Tests)

Before running baseline tests, define your skill's scope:

**One-sentence objective:** What behavior change does this skill enforce?
- "Agents will always run tests before committing"
- "Agents will use the project's error handling pattern"

**Explicit boundaries:** What is IN scope?
- List the specific situations/triggers
- List the tools/files affected

**Non-goals:** What is OUT of scope?
- Prevent scope creep during development
- Clarify what adjacent problems this skill does NOT solve

**Dependencies:** What must exist for this skill to work?
- Required tools (gh, jq, etc.)
- Required environment variables
- Required background skills
- Behavior when dependencies are missing

**Example scope statement:**
```
Objective: Agents run linter before committing code changes.
In scope: Pre-commit validation for JS/TS files
Out of scope: CI pipeline config, linter rule customization
Dependencies: eslint installed, .eslintrc exists
```

## RED-GREEN-REFACTOR for Skills

### RED: Write Failing Test (Baseline)

Run pressure scenario with subagent WITHOUT the skill:
- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

### GREEN: Write Minimal Skill

Write skill addressing those specific rationalizations. Choose appropriate configuration options from reference.md.

Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

## Testing Different Skill Types

### Discipline-Enforcing Skills
**Test with:** Pressure scenarios, multiple combined pressures
**Success:** Agent follows rule under maximum pressure

### Technique Skills
**Test with:** Application scenarios, edge cases, missing information
**Success:** Agent successfully applies technique

### Reference Skills
**Test with:** Retrieval scenarios, application scenarios, gap testing
**Success:** Agent finds and correctly applies information

## Required Test Categories

Beyond skill-type-specific tests, every skill needs these:

### Negative Tests (False Trigger Prevention)
Prove skill is NOT invoked when conditions don't match:
- Similar but different scenarios
- Edge cases that look like triggers but aren't
- **Pass criterion:** Skill stays dormant, agent uses default behavior

### Ambiguity Tests (Skill Selection)
When multiple skills could apply:
- Create scenario where 2+ skills have overlapping triggers
- Verify correct skill is selected
- **Pass criterion:** Right skill activates, wrong skills stay dormant

### Regression Tests
After any edit, rerun ALL prior failing scenarios:
- Keep baseline transcripts as test fixtures
- Any regression = edit rejected
- **Pass criterion:** All previously-passing scenarios still pass

### Environment Tests
Verify graceful handling of missing dependencies:
- Required tools not installed
- Required env vars missing
- Restricted permissions
- **Pass criterion:** Clear error message, no silent failure

## Scoring Rubric

Rate each test scenario 0-2:
- **0:** Complete failure (wrong behavior, crash, silent skip)
- **1:** Partial success (mostly right, minor issues)
- **2:** Full compliance (exactly correct behavior)

**Pass threshold:** Average score ≥ 1.5 across all scenarios, no zeros.

## Skill Creation Checklist

### MVP Checklist (Minimum Viable Skill)

Get a working skill quickly:

- [ ] **Gate:** Pass "When NOT to Create" criteria
- [ ] **Scope:** One-sentence objective + boundaries
- [ ] **RED:** Run 1 baseline scenario, document failure
- [ ] **GREEN:** Write minimal skill addressing that failure
- [ ] **Verify:** Run scenario WITH skill, confirm compliance
- [ ] **Frontmatter:** Name (hyphenated), description ("Use when...")

### Advanced Checklist (Production Quality)

Full robustness for shared/critical skills:

**Pre-work:**
- [ ] Define explicit non-goals
- [ ] Declare all dependencies (tools, env vars, background skills)
- [ ] Consider failure behavior when dependencies missing

**Testing:**
- [ ] 3+ pressure scenarios (discipline skills)
- [ ] Negative tests (skill stays dormant when it should)
- [ ] Ambiguity tests (correct skill selected among competitors)
- [ ] Environment tests (missing tools, restricted permissions)
- [ ] Score ≥ 1.5 average, no zeros

**Configuration:**
- [ ] `disable-model-invocation` for side effects
- [ ] `context: fork` for isolated execution
- [ ] `allowed-tools` scoped to minimum required
- [ ] `argument-hint` if skill accepts input
- [ ] Safe `!\`command\`` patterns with fallbacks
- [ ] `hooks` for validation/automation

**Quality:**
- [ ] Common mistakes section
- [ ] Keep SKILL.md under 500 lines
- [ ] Regression tests saved as fixtures

**Deployment:**
- [ ] Commit and push

## Directory Structure

```
.claude/
  skills/
    skill-name/
      SKILL.md              # Main reference (required)
      reference.md          # Heavy reference (if needed)
      scripts/              # Reusable tools (if needed)
```

## Anti-Patterns

### ❌ Ignoring Power Features
Using only `name` and `description` when `context: fork`, `allowed-tools`, or `disable-model-invocation` would make the skill safer/better.

### ❌ Missing `disable-model-invocation` on Side Effects
Deploy, commit, send message skills MUST have `disable-model-invocation: true`.

### ❌ Hardcoding Data That Changes
Use `!\`git status\`` instead of describing "current state".

### ❌ Not Using Arguments
If skill should accept input, use `argument-hint` and `$ARGUMENTS`.

### ❌ Narrative Examples
"In session 2025-10-03, we found..." → Too specific, not reusable.

### ❌ Overfitting to One Baseline
Writing skill that only addresses the single rationalization you observed. Test with multiple pressure combinations to find other failure modes.

### ❌ Over-Permissive `allowed-tools`
Using `Bash(*)` when you only need `Bash(npm test)`. Scope tools to minimum required.

### ❌ Hidden Prerequisites
Skill assumes `gh`, `jq`, or custom scripts exist without declaring them. Always list dependencies in skill content or use Scoping section.

### ❌ Circular Skill Dependencies
Skill A requires Skill B which requires Skill A. Map dependencies before creating.

### ❌ Demo Pass Bias
Testing happy path once and calling it done. Run negative tests, ambiguity tests, and environment tests.

### ❌ Unsafe Dynamic Injection
Using `!\`command\`` without considering: What if command fails? What if output is huge? What if it contains sensitive data? Add fallbacks and sanitization.

## Related resources

- Subagents: delegate tasks to specialized agents
- Hooks: automate workflows around skill execution
- Plugins: package and distribute skills

Skills:
@~/metaskills/.claude/skills

Hooks:
@~/metaskills/.claude/hooks

Commands:
@~/metaskills/.claude/commands
