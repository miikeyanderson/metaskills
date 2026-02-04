# Create Reference Documentation

Create a `reference.md` file for the skill or component at: `$ARGUMENTS`

## Step 1: Request Documentation

Ask the user:

> Please paste the fetched documentation text from the Claude Code docs for this component.
>
> You can fetch it using WebFetch or copy it from https://code.claude.com/docs/

Wait for the user to provide the documentation text before proceeding.

## Step 2: Create Reference File

After receiving the documentation, create a `reference.md` file at the target location using the format below.

### Target Path

- If `$ARGUMENTS` contains a path, use: `$ARGUMENTS/reference.md`
- If `$ARGUMENTS` is just a name, use: `.claude/skills/$ARGUMENTS/reference.md`

### Required Format

The reference file MUST use this format optimized for agent retrieval:

**DO NOT USE:**
- Tables
- ASCII diagrams
- Complex nested structures

**DO USE:**
- `##` headers for major sections
- `###` headers for categories/groupings
- `####` headers for individual fields or items
- Bullet points with **bold** labels for properties

### Field Documentation Pattern

For each field, use this pattern:

```markdown
#### `field_name`

- **Type**: String
- **Required**: Yes/No
- **Default**: value (if applicable)
- **Description**: What this field does
```

### Section Structure Pattern

```markdown
## Section Name

Brief description of what this section covers.

### Category Name

#### `item_one`

- **Type**: String
- **Description**: What it does

#### `item_two`

- **Type**: Boolean
- **Default**: `false`
- **Description**: What it does
```

### File Template

```markdown
# [Component Name] Complete Reference

This document provides a comprehensive reference for all available options, fields, and features when [doing X] in Claude Code.

---

## [First Major Section]

[Content using list format]

---

## [Second Major Section]

[Content using list format]

---

## Example Configurations

[Code examples with explanations]

---

## Troubleshooting

### [Common Issue 1]

1. Step to diagnose
2. Step to fix

### [Common Issue 2]

1. Step to diagnose
2. Step to fix

---

## Related resources

[List relevant topics with brief descriptions, no URLs]

Example:

- Subagents: delegate tasks to specialized agents
- Plugins: package and distribute skills with other extensions
- Hooks: automate workflows around tool events

Include directory references for loading related content into Claude's context using home-relative paths:

[Topic Name]:
@~/metaskills/.claude/path/to/directory

Example:

Skills:
@~/metaskills/.claude/skills

Commands:
@~/metaskills/.claude/commands

Hooks:
@~/metaskills/.claude/hooks

## Step 3: Confirm Creation

After creating the file, confirm:
- The file path created
- Number of sections included
- Any sections from the source docs that were intentionally omitted and why
