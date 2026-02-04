---
name: creating-hooks
description: Use when creating new hooks, editing existing hooks, or automating workflows around Claude Code events
---

# Creating Hooks

## Overview

**Hooks are shell commands that execute at specific lifecycle points in Claude Code.**

Use hooks to automate formatting, validation, notifications, and other workflows around tool usage and session events.

**Complete field reference:** See reference.md for all hook types, events, configuration fields, and examples.

## When to Use Hooks

- Auto-format files after edits (Prettier, linters)
- Block modifications to protected files
- Send notifications when Claude needs attention
- Validate tool inputs before execution
- Inject context after compaction
- Run verification before marking work complete

## When NOT to Use Hooks

- One-time automation → Just run the command manually
- Complex multi-step logic → Use a skill with `context: fork` instead
- Decisions requiring judgment → Use prompt/agent hooks sparingly

## Hook Types Quick Reference

| Type | Purpose | Use Case |
|------|---------|----------|
| `command` | Run shell command | Formatting, validation, notifications |
| `prompt` | Single-turn Claude evaluation | Decisions requiring judgment |
| `agent` | Multi-turn subagent with tools | Verification requiring file inspection |

## Hook Events Quick Reference

| Event | When | Can Block |
|-------|------|-----------|
| `SessionStart` | Session begins/resumes | No |
| `UserPromptSubmit` | Before Claude processes prompt | Yes |
| `PreToolUse` | Before tool executes | Yes |
| `PostToolUse` | After tool succeeds | No |
| `Stop` | Claude finishes responding | Yes |

## Basic Configuration Pattern

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<regex pattern>",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/script.sh"
          }
        ]
      }
    ]
  }
}
```

## Hook Locations

| Location | Path | Scope |
|----------|------|-------|
| User | `~/.claude/settings.json` | All projects |
| Project | `.claude/settings.json` | This project |
| Local | `.claude/settings.local.json` | This project, not shared |
| Plugin | `<plugin>/hooks/hooks.json` | When plugin enabled |

## Common Patterns

### Auto-format on Edit

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

### Block Protected Files

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
          }
        ]
      }
    ]
  }
}
```

## Testing Hooks

1. Run `/hooks` to see configured hooks
2. Test scripts manually: `echo '{"tool_name":"Bash"}' | ./my-hook.sh`
3. Check exit code: `echo $?`
4. Use verbose mode (`Ctrl+O`) for debugging

## Related Skills

- @creating-skills: Apply TDD principles when creating hooks
- See reference.md for complete configuration options
