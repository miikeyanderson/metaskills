# Hooks Reference

> Reference for Claude Code hook events, configuration schema, JSON input/output formats, exit codes, async hooks, prompt hooks, and MCP tool hooks.

## Hook Lifecycle

Hooks fire at specific points during a Claude Code session. When an event fires and a matcher matches, Claude Code passes JSON context about the event to your hook handler.

```
┌─────────────────┐
│  SessionStart   │ ← Session begins or resumes
└────────┬────────┘
         ▼
┌─────────────────┐
│UserPromptSubmit │ ← User submits prompt
└────────┬────────┘
         ▼
    ┌────────────────────────────────┐
    │      AGENTIC LOOP              │
    │  ┌──────────────────────────┐  │
    │  │ PreToolUse               │  │ ← Before tool executes
    │  │ PermissionRequest        │  │ ← Permission dialog shown
    │  │ PostToolUse              │  │ ← After tool succeeds
    │  │ PostToolUseFailure       │  │ ← After tool fails
    │  │ Notification             │  │ ← Notification sent
    │  │ SubagentStart/Stop       │  │ ← Subagent lifecycle
    │  └──────────────────────────┘  │
    └────────────────────────────────┘
         ▼
┌─────────────────┐
│      Stop       │ ← Claude finishes responding
└────────┬────────┘
         ▼
┌─────────────────┐
│   PreCompact    │ ← Before context compaction
└────────┬────────┘
         ▼
┌─────────────────┐
│   SessionEnd    │ ← Session terminates
└─────────────────┘
```

## Hook Events Summary

| Event                | When it fires                                        |
| :------------------- | :--------------------------------------------------- |
| `SessionStart`       | When a session begins or resumes                     |
| `UserPromptSubmit`   | When you submit a prompt, before Claude processes it |
| `PreToolUse`         | Before a tool call executes. Can block it            |
| `PermissionRequest`  | When a permission dialog appears                     |
| `PostToolUse`        | After a tool call succeeds                           |
| `PostToolUseFailure` | After a tool call fails                              |
| `Notification`       | When Claude Code sends a notification                |
| `SubagentStart`      | When a subagent is spawned                           |
| `SubagentStop`       | When a subagent finishes                             |
| `Stop`               | When Claude finishes responding                      |
| `PreCompact`         | Before context compaction                            |
| `SessionEnd`         | When a session terminates                            |

---

## Configuration

### Hook Locations

| Location                           | Scope               | Shareable                          |
| :--------------------------------- | :------------------ | :--------------------------------- |
| `~/.claude/settings.json`          | All your projects   | No, local to your machine          |
| `.claude/settings.json`            | Single project      | Yes, can be committed to repo      |
| `.claude/settings.local.json`      | Single project      | No, gitignored                     |
| Plugin `hooks/hooks.json`          | When plugin enabled | Yes, bundled with the plugin       |
| Skill/agent frontmatter            | While active        | Yes, defined in component file     |

### Configuration Structure

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<regex pattern>",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/script.sh",
            "timeout": 600,
            "statusMessage": "Running hook..."
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns

The `matcher` field is a regex that filters when hooks fire. Use `"*"`, `""`, or omit entirely to match all.

| Event                                                                  | What matcher filters  | Example values                                         |
| :--------------------------------------------------------------------- | :-------------------- | :----------------------------------------------------- |
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest` | tool name             | `Bash`, `Edit\|Write`, `mcp__.*`                       |
| `SessionStart`                                                         | how session started   | `startup`, `resume`, `clear`, `compact`                |
| `SessionEnd`                                                           | why session ended     | `clear`, `logout`, `prompt_input_exit`, `other`        |
| `Notification`                                                         | notification type     | `permission_prompt`, `idle_prompt`, `auth_success`     |
| `SubagentStart`, `SubagentStop`                                        | agent type            | `Bash`, `Explore`, `Plan`, or custom agent names       |
| `PreCompact`                                                           | compaction trigger    | `manual`, `auto`                                       |
| `UserPromptSubmit`, `Stop`                                             | no matcher support    | always fires                                           |

### Hook Handler Types

#### Command Hooks

```json
{
  "type": "command",
  "command": "/path/to/script.sh",
  "timeout": 600,
  "statusMessage": "Running...",
  "async": false
}
```

| Field           | Required | Description                                    |
| :-------------- | :------- | :--------------------------------------------- |
| `type`          | yes      | `"command"`                                    |
| `command`       | yes      | Shell command to execute                       |
| `timeout`       | no       | Seconds before canceling (default: 600)        |
| `statusMessage` | no       | Custom spinner message                         |
| `async`         | no       | If `true`, runs in background without blocking |

#### Prompt Hooks

```json
{
  "type": "prompt",
  "prompt": "Evaluate if this should proceed: $ARGUMENTS",
  "model": "haiku",
  "timeout": 30
}
```

#### Agent Hooks

```json
{
  "type": "agent",
  "prompt": "Verify all tests pass before stopping: $ARGUMENTS",
  "model": "haiku",
  "timeout": 60
}
```

### Environment Variables

- `$CLAUDE_PROJECT_DIR`: Project root directory
- `${CLAUDE_PLUGIN_ROOT}`: Plugin's root directory
- `$CLAUDE_ENV_FILE`: (SessionStart only) Path to persist environment variables

---

## Hook Input and Output

### Common Input Fields (stdin JSON)

All hooks receive these fields:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse"
}
```

### Exit Code Behavior

| Exit Code | Meaning           | Effect                                            |
| :-------- | :---------------- | :------------------------------------------------ |
| 0         | Success           | Proceed; parse stdout for JSON                    |
| 2         | Blocking error    | Block action; stderr shown as error               |
| Other     | Non-blocking      | Continue; stderr shown in verbose mode            |

### Exit Code 2 Behavior by Event

| Hook event           | Can block? | What happens on exit 2                              |
| :------------------- | :--------- | :-------------------------------------------------- |
| `PreToolUse`         | Yes        | Blocks the tool call                                |
| `PermissionRequest`  | Yes        | Denies the permission                               |
| `UserPromptSubmit`   | Yes        | Blocks prompt processing and erases it              |
| `Stop`               | Yes        | Prevents stopping, continues conversation           |
| `SubagentStop`       | Yes        | Prevents the subagent from stopping                 |
| `PostToolUse`        | No         | Shows stderr to Claude (tool already ran)           |
| `PostToolUseFailure` | No         | Shows stderr to Claude (tool already failed)        |
| `Notification`       | No         | Shows stderr to user only                           |
| `SubagentStart`      | No         | Shows stderr to user only                           |
| `SessionStart`       | No         | Shows stderr to user only                           |
| `SessionEnd`         | No         | Shows stderr to user only                           |
| `PreCompact`         | No         | Shows stderr to user only                           |

### JSON Output Fields (stdout)

Universal fields available to all hooks:

| Field            | Default | Description                                                |
| :--------------- | :------ | :--------------------------------------------------------- |
| `continue`       | `true`  | If `false`, Claude stops entirely                          |
| `stopReason`     | none    | Message shown to user when `continue` is `false`           |
| `suppressOutput` | `false` | If `true`, hides stdout from verbose mode                  |
| `systemMessage`  | none    | Warning message shown to user                              |

---

## Event-Specific Reference

### SessionStart

**Matcher values:** `startup`, `resume`, `clear`, `compact`

**Input:**
```json
{
  "source": "startup",
  "model": "claude-sonnet-4-5-20250929",
  "agent_type": "optional-agent-name"
}
```

**Output:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Context added for Claude"
  }
}
```

**Environment persistence (SessionStart only):**
```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

### UserPromptSubmit

**No matcher support** - always fires.

**Input:**
```json
{
  "prompt": "User's submitted prompt text"
}
```

**Output:**
```json
{
  "decision": "block",
  "reason": "Explanation shown to user",
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Context for Claude"
  }
}
```

### PreToolUse

**Matcher:** Tool name (`Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Task`, `WebFetch`, `WebSearch`, `mcp__*`)

**Input:**
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

**Output (decision control):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Reason shown to user/Claude",
    "updatedInput": {
      "command": "modified command"
    },
    "additionalContext": "Extra context for Claude"
  }
}
```

### PermissionRequest

**Matcher:** Tool name (same as PreToolUse)

**Input:**
```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf node_modules" },
  "permission_suggestions": [
    { "type": "toolAlwaysAllow", "tool": "Bash" }
  ]
}
```

**Output:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow|deny",
      "updatedInput": { "command": "modified" },
      "updatedPermissions": [...],
      "message": "Reason for deny",
      "interrupt": false
    }
  }
}
```

### PostToolUse

**Matcher:** Tool name

**Input:**
```json
{
  "tool_name": "Write",
  "tool_input": { "file_path": "/path/to/file.txt", "content": "..." },
  "tool_response": { "filePath": "/path/to/file.txt", "success": true },
  "tool_use_id": "toolu_01ABC123..."
}
```

**Output:**
```json
{
  "decision": "block",
  "reason": "Explanation for Claude",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Extra info for Claude",
    "updatedMCPToolOutput": "For MCP tools only"
  }
}
```

### PostToolUseFailure

**Matcher:** Tool name

**Input:**
```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "npm test" },
  "tool_use_id": "toolu_01ABC123...",
  "error": "Command exited with non-zero status code 1",
  "is_interrupt": false
}
```

**Output:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUseFailure",
    "additionalContext": "Info about the failure"
  }
}
```

### Notification

**Matcher:** `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`

**Input:**
```json
{
  "message": "Claude needs your permission to use Bash",
  "title": "Permission needed",
  "notification_type": "permission_prompt"
}
```

### SubagentStart

**Matcher:** Agent type (`Bash`, `Explore`, `Plan`, or custom names)

**Input:**
```json
{
  "agent_id": "agent-abc123",
  "agent_type": "Explore"
}
```

**Output:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "Context for the subagent"
  }
}
```

### SubagentStop

**Matcher:** Agent type

**Input:**
```json
{
  "stop_hook_active": false,
  "agent_id": "def456",
  "agent_type": "Explore",
  "agent_transcript_path": "~/.claude/projects/.../subagents/agent-def456.jsonl"
}
```

**Output:** Same as Stop event.

### Stop

**No matcher support** - always fires.

**Input:**
```json
{
  "stop_hook_active": true
}
```

**Output:**
```json
{
  "decision": "block",
  "reason": "Must verify tests pass before stopping"
}
```

### PreCompact

**Matcher:** `manual`, `auto`

**Input:**
```json
{
  "trigger": "manual",
  "custom_instructions": ""
}
```

### SessionEnd

**Matcher:** `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`

**Input:**
```json
{
  "reason": "other"
}
```

---

## Tool Input Schemas

### Bash
```json
{
  "command": "npm test",
  "description": "Run test suite",
  "timeout": 120000,
  "run_in_background": false
}
```

### Write
```json
{
  "file_path": "/path/to/file.txt",
  "content": "file content"
}
```

### Edit
```json
{
  "file_path": "/path/to/file.txt",
  "old_string": "original text",
  "new_string": "replacement text",
  "replace_all": false
}
```

### Read
```json
{
  "file_path": "/path/to/file.txt",
  "offset": 10,
  "limit": 50
}
```

### Glob
```json
{
  "pattern": "**/*.ts",
  "path": "/optional/directory"
}
```

### Grep
```json
{
  "pattern": "TODO.*fix",
  "path": "/path/to/dir",
  "glob": "*.ts",
  "output_mode": "content|files_with_matches|count",
  "-i": true,
  "multiline": false
}
```

### WebFetch
```json
{
  "url": "https://example.com/api",
  "prompt": "Extract the API endpoints"
}
```

### WebSearch
```json
{
  "query": "react hooks best practices",
  "allowed_domains": ["docs.example.com"],
  "blocked_domains": ["spam.example.com"]
}
```

### Task
```json
{
  "prompt": "Find all API endpoints",
  "description": "Find API endpoints",
  "subagent_type": "Explore",
  "model": "sonnet"
}
```

---

## Examples

### Block Destructive Commands

```bash
#!/bin/bash
# .claude/hooks/block-rm.sh
COMMAND=$(jq -r '.tool_input.command')

if echo "$COMMAND" | grep -q 'rm -rf'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Destructive command blocked"
    }
  }'
else
  exit 0
fi
```

### Run Tests After File Changes (Async)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/run-tests.sh",
            "async": true,
            "timeout": 300
          }
        ]
      }
    ]
  }
}
```

### Verify Before Stopping (Prompt Hook)

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if all tasks are complete: $ARGUMENTS",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Prompt/agent hooks must return:
```json
{
  "ok": true,
  "reason": "Explanation when ok is false"
}
```

### Hooks in Skills/Agents (Frontmatter)

```yaml
---
name: secure-operations
description: Perform operations with security checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
---
```

---

## Debugging

Run `claude --debug` to see hook execution details. Toggle verbose mode with `Ctrl+O`.

```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Found 1 hook commands to execute
[DEBUG] Hook command completed with status 0
```

---

## Security Considerations

- Hooks run with your system user's full permissions
- Validate and sanitize all inputs
- Always quote shell variables: `"$VAR"` not `$VAR`
- Block path traversal: check for `..` in file paths
- Use absolute paths for scripts
- Skip sensitive files: `.env`, `.git/`, keys

---

## Quick Reference

| Want to...                          | Use event            | Return                                |
| :---------------------------------- | :------------------- | :------------------------------------ |
| Block a tool before it runs         | `PreToolUse`         | `permissionDecision: "deny"`          |
| Auto-approve a tool                 | `PreToolUse`         | `permissionDecision: "allow"`         |
| Modify tool input                   | `PreToolUse`         | `updatedInput: {...}`                 |
| Answer permission dialog            | `PermissionRequest`  | `decision.behavior: "allow\|deny"`    |
| React after tool succeeds           | `PostToolUse`        | `additionalContext` or `decision`     |
| React after tool fails              | `PostToolUseFailure` | `additionalContext`                   |
| Block user prompt                   | `UserPromptSubmit`   | `decision: "block"`                   |
| Add context to prompt               | `UserPromptSubmit`   | `additionalContext` or plain stdout   |
| Keep Claude working                 | `Stop`               | `decision: "block", reason: "..."`    |
| Add startup context                 | `SessionStart`       | `additionalContext` or plain stdout   |
| Set environment variables           | `SessionStart`       | Write to `$CLAUDE_ENV_FILE`           |
| Clean up on exit                    | `SessionEnd`         | Run cleanup script                    |
