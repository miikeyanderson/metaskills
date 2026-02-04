# Claude Code Hooks Complete Reference

This document provides a comprehensive reference for all available options, fields, and features when creating hooks in Claude Code.

---

## File Structure

Hooks are defined in JSON settings files with this structure:

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

---

## Hook Locations

Where you define a hook determines its scope:

| Location | Path | Applies to | Shareable |
|----------|------|------------|-----------|
| Personal | `~/.claude/settings.json` | All your projects | No |
| Project | `.claude/settings.json` | Single project | Yes, commit to repo |
| Local | `.claude/settings.local.json` | Single project | No, gitignored |
| Plugin | `<plugin>/hooks/hooks.json` | When plugin enabled | Yes |
| Skill/Agent | YAML frontmatter | While component active | Yes |

**Priority**: Hooks from all locations merge and run in parallel.

---

## Hook Events Reference

All available hook events and when they fire:

| Event | When it fires | Can block? |
|-------|---------------|------------|
| `SessionStart` | Session begins or resumes | No |
| `UserPromptSubmit` | User submits prompt, before processing | Yes |
| `PreToolUse` | Before a tool call executes | Yes |
| `PermissionRequest` | Permission dialog appears | Yes |
| `PostToolUse` | After a tool call succeeds | No |
| `PostToolUseFailure` | After a tool call fails | No |
| `Notification` | Claude Code sends a notification | No |
| `SubagentStart` | Subagent is spawned | No |
| `SubagentStop` | Subagent finishes | Yes |
| `Stop` | Claude finishes responding | Yes |
| `PreCompact` | Before context compaction | No |
| `SessionEnd` | Session terminates | No |

---

## Matcher Patterns Reference

The `matcher` field is a regex that filters when hooks fire. Omit or use `"*"` to match all.

| Event | What matcher filters | Example values |
|-------|---------------------|----------------|
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest` | Tool name | `Bash`, `Edit\|Write`, `mcp__.*` |
| `SessionStart` | How session started | `startup`, `resume`, `clear`, `compact` |
| `SessionEnd` | Why session ended | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |
| `Notification` | Notification type | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` |
| `SubagentStart`, `SubagentStop` | Agent type | `Bash`, `Explore`, `Plan`, custom names |
| `PreCompact` | Compaction trigger | `manual`, `auto` |
| `UserPromptSubmit`, `Stop` | No matcher support | Always fires |

**Tool names for matching**: `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Task`, `WebFetch`, `WebSearch`, `mcp__<server>__<tool>`

---

## Hook Handler Fields Reference

### Common Fields (All Types)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `type` | String | Yes | - | `"command"`, `"prompt"`, or `"agent"` |
| `timeout` | Number | No | 600/30/60 | Seconds before canceling (command/prompt/agent) |
| `statusMessage` | String | No | - | Custom spinner message while running |
| `once` | Boolean | No | `false` | Run only once per session (skills only) |

### Command Hook Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `command` | String | Yes | - | Shell command to execute |
| `async` | Boolean | No | `false` | Run in background without blocking |

### Prompt/Agent Hook Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `prompt` | String | Yes | - | Prompt text. Use `$ARGUMENTS` for hook input JSON |
| `model` | String | No | haiku | Model to use for evaluation |

---

## Environment Variables

Available in hook commands:

| Variable | Description | Available in |
|----------|-------------|--------------|
| `$CLAUDE_PROJECT_DIR` | Project root directory | All hooks |
| `${CLAUDE_PLUGIN_ROOT}` | Plugin's root directory | Plugin hooks |
| `$CLAUDE_ENV_FILE` | Path to persist environment variables | SessionStart only |
| `$CLAUDE_CODE_REMOTE` | Set to `"true"` in remote web environments | All hooks |

---

## Hook Input Reference (stdin JSON)

### Common Input Fields

All hooks receive these fields via stdin:

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | String | Current session identifier |
| `transcript_path` | String | Path to conversation JSON |
| `cwd` | String | Current working directory |
| `permission_mode` | String | `"default"`, `"plan"`, `"acceptEdits"`, `"dontAsk"`, or `"bypassPermissions"` |
| `hook_event_name` | String | Name of the event that fired |

### SessionStart Input

| Field | Type | Description |
|-------|------|-------------|
| `source` | String | `"startup"`, `"resume"`, `"clear"`, or `"compact"` |
| `model` | String | Model identifier |
| `agent_type` | String | Agent name if started with `claude --agent <name>` |

### UserPromptSubmit Input

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | String | Text the user submitted |

### PreToolUse Input

| Field | Type | Description |
|-------|------|-------------|
| `tool_name` | String | Name of the tool |
| `tool_input` | Object | Tool-specific input parameters |
| `tool_use_id` | String | Unique identifier for this tool call |

### PermissionRequest Input

| Field | Type | Description |
|-------|------|-------------|
| `tool_name` | String | Name of the tool |
| `tool_input` | Object | Tool-specific input parameters |
| `permission_suggestions` | Array | "Always allow" options user would see |

### PostToolUse Input

| Field | Type | Description |
|-------|------|-------------|
| `tool_name` | String | Name of the tool |
| `tool_input` | Object | Tool-specific input parameters |
| `tool_response` | Object | Result returned by the tool |
| `tool_use_id` | String | Unique identifier for this tool call |

### PostToolUseFailure Input

| Field | Type | Description |
|-------|------|-------------|
| `tool_name` | String | Name of the tool |
| `tool_input` | Object | Tool-specific input parameters |
| `tool_use_id` | String | Unique identifier for this tool call |
| `error` | String | Error description |
| `is_interrupt` | Boolean | Whether caused by user interruption |

### Notification Input

| Field | Type | Description |
|-------|------|-------------|
| `message` | String | Notification text |
| `title` | String | Optional notification title |
| `notification_type` | String | Type that triggered the hook |

### SubagentStart Input

| Field | Type | Description |
|-------|------|-------------|
| `agent_id` | String | Unique identifier for the subagent |
| `agent_type` | String | Agent type name |

### SubagentStop Input

| Field | Type | Description |
|-------|------|-------------|
| `stop_hook_active` | Boolean | Whether already continuing from a stop hook |
| `agent_id` | String | Unique identifier for the subagent |
| `agent_type` | String | Agent type name |
| `agent_transcript_path` | String | Path to subagent's transcript |

### Stop Input

| Field | Type | Description |
|-------|------|-------------|
| `stop_hook_active` | Boolean | Whether already continuing from a stop hook |

### PreCompact Input

| Field | Type | Description |
|-------|------|-------------|
| `trigger` | String | `"manual"` or `"auto"` |
| `custom_instructions` | String | User input from `/compact` (empty for auto) |

### SessionEnd Input

| Field | Type | Description |
|-------|------|-------------|
| `reason` | String | Why the session ended |

---

## Tool Input Schemas

### Bash

| Field | Type | Description |
|-------|------|-------------|
| `command` | String | Shell command to execute |
| `description` | String | Optional description |
| `timeout` | Number | Optional timeout in milliseconds |
| `run_in_background` | Boolean | Whether to run in background |

### Write

| Field | Type | Description |
|-------|------|-------------|
| `file_path` | String | Absolute path to file |
| `content` | String | Content to write |

### Edit

| Field | Type | Description |
|-------|------|-------------|
| `file_path` | String | Absolute path to file |
| `old_string` | String | Text to find and replace |
| `new_string` | String | Replacement text |
| `replace_all` | Boolean | Whether to replace all occurrences |

### Read

| Field | Type | Description |
|-------|------|-------------|
| `file_path` | String | Absolute path to file |
| `offset` | Number | Optional line number to start from |
| `limit` | Number | Optional number of lines to read |

### Glob

| Field | Type | Description |
|-------|------|-------------|
| `pattern` | String | Glob pattern to match |
| `path` | String | Optional directory to search |

### Grep

| Field | Type | Description |
|-------|------|-------------|
| `pattern` | String | Regex pattern to search |
| `path` | String | Optional file or directory |
| `glob` | String | Optional glob filter |
| `output_mode` | String | `"content"`, `"files_with_matches"`, or `"count"` |
| `-i` | Boolean | Case insensitive search |
| `multiline` | Boolean | Enable multiline matching |

### WebFetch

| Field | Type | Description |
|-------|------|-------------|
| `url` | String | URL to fetch |
| `prompt` | String | Prompt to run on fetched content |

### WebSearch

| Field | Type | Description |
|-------|------|-------------|
| `query` | String | Search query |
| `allowed_domains` | Array | Optional: only include these domains |
| `blocked_domains` | Array | Optional: exclude these domains |

### Task

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | String | Task for the agent |
| `description` | String | Short description |
| `subagent_type` | String | Type of agent to use |
| `model` | String | Optional model override |

---

## Exit Code Behavior

| Exit Code | Meaning | Effect |
|-----------|---------|--------|
| 0 | Success | Proceed; parse stdout for JSON |
| 2 | Blocking error | Block action; stderr shown as error |
| Other | Non-blocking error | Continue; stderr shown in verbose mode |

### Exit Code 2 Behavior by Event

| Event | Effect of exit 2 |
|-------|------------------|
| `PreToolUse` | Blocks the tool call |
| `PermissionRequest` | Denies the permission |
| `UserPromptSubmit` | Blocks and erases prompt |
| `Stop` | Prevents stopping, continues conversation |
| `SubagentStop` | Prevents subagent from stopping |
| `PostToolUse` | Shows stderr to Claude (tool already ran) |
| `PostToolUseFailure` | Shows stderr to Claude |
| `Notification` | Shows stderr to user only |
| `SubagentStart` | Shows stderr to user only |
| `SessionStart` | Shows stderr to user only |
| `SessionEnd` | Shows stderr to user only |
| `PreCompact` | Shows stderr to user only |

---

## JSON Output Reference (stdout)

### Universal Fields

Available to all hooks:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `continue` | Boolean | `true` | If `false`, Claude stops entirely |
| `stopReason` | String | - | Message shown to user when `continue` is `false` |
| `suppressOutput` | Boolean | `false` | Hide stdout from verbose mode |
| `systemMessage` | String | - | Warning message shown to user |

### Decision Control by Event

| Event | Decision pattern | Key fields |
|-------|-----------------|------------|
| `UserPromptSubmit`, `PostToolUse`, `PostToolUseFailure`, `Stop`, `SubagentStop` | Top-level `decision` | `decision: "block"`, `reason` |
| `PreToolUse` | `hookSpecificOutput` | `permissionDecision`, `permissionDecisionReason`, `updatedInput` |
| `PermissionRequest` | `hookSpecificOutput` | `decision.behavior`, `decision.updatedInput` |

### SessionStart Output

| Field | Type | Description |
|-------|------|-------------|
| `additionalContext` | String | Context added for Claude |

### UserPromptSubmit Output

| Field | Type | Description |
|-------|------|-------------|
| `decision` | String | `"block"` to prevent processing |
| `reason` | String | Shown to user when blocked |
| `additionalContext` | String | Context added for Claude |

### PreToolUse Output

| Field | Type | Description |
|-------|------|-------------|
| `permissionDecision` | String | `"allow"`, `"deny"`, or `"ask"` |
| `permissionDecisionReason` | String | Reason shown to user/Claude |
| `updatedInput` | Object | Modified tool input parameters |
| `additionalContext` | String | Context added for Claude |

### PermissionRequest Output

| Field | Type | Description |
|-------|------|-------------|
| `decision.behavior` | String | `"allow"` or `"deny"` |
| `decision.updatedInput` | Object | Modified tool input (allow only) |
| `decision.updatedPermissions` | Array | Permission rules to apply (allow only) |
| `decision.message` | String | Reason for deny |
| `decision.interrupt` | Boolean | Stop Claude on deny |

### PostToolUse Output

| Field | Type | Description |
|-------|------|-------------|
| `decision` | String | `"block"` to prompt Claude with reason |
| `reason` | String | Explanation for Claude |
| `additionalContext` | String | Additional context for Claude |
| `updatedMCPToolOutput` | Any | Replace MCP tool output |

### PostToolUseFailure Output

| Field | Type | Description |
|-------|------|-------------|
| `additionalContext` | String | Context about the failure |

### SubagentStart Output

| Field | Type | Description |
|-------|------|-------------|
| `additionalContext` | String | Context for the subagent |

### Stop / SubagentStop Output

| Field | Type | Description |
|-------|------|-------------|
| `decision` | String | `"block"` to prevent stopping |
| `reason` | String | Required when blocking; tells Claude why to continue |

### Prompt/Agent Hook Response

Must return:

| Field | Type | Description |
|-------|------|-------------|
| `ok` | Boolean | `true` to allow, `false` to block |
| `reason` | String | Required when `ok` is `false` |

---

## Hooks in Skills and Agents

Define hooks in YAML frontmatter:

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

**Note**: For subagents, `Stop` hooks are automatically converted to `SubagentStop`.

---

## Async Hooks

Set `"async": true` to run in background without blocking:

```json
{
  "type": "command",
  "command": "/path/to/script.sh",
  "async": true,
  "timeout": 300
}
```

**Limitations**:
- Only `type: "command"` supports async
- Cannot block or return decisions
- Output delivered on next conversation turn

---

## Example Configurations

### Block Destructive Commands

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-rm.sh"
          }
        ]
      }
    ]
  }
}
```

Script:
```bash
#!/bin/bash
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

### Run Tests After File Changes

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
            "prompt": "Check if all tasks are complete: $ARGUMENTS. Return {\"ok\": true} or {\"ok\": false, \"reason\": \"...\"}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Add Startup Context

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### Set Environment Variables (SessionStart)

```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
  echo 'export DEBUG=true' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

### Match MCP Tools

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__memory__.*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Memory operation' >> ~/mcp-ops.log"
          }
        ]
      }
    ]
  }
}
```

---

## Debugging

Run `claude --debug` to see hook execution details. Toggle verbose mode with `Ctrl+O`.

```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Found 1 hook commands to execute
[DEBUG] Hook command completed with status 0
```

Use `/hooks` menu to view, add, and delete hooks interactively.

---

## Security Considerations

- Hooks run with your full user permissions
- Always validate and sanitize inputs
- Quote shell variables: `"$VAR"` not `$VAR`
- Check for path traversal (`..` in file paths)
- Use absolute paths with `"$CLAUDE_PROJECT_DIR"`
- Skip sensitive files (`.env`, `.git/`, keys)

---

## Troubleshooting

### Hook Not Firing

1. Check matcher pattern matches the tool/event
2. Verify JSON syntax in settings file
3. Run `claude --debug` to see matching details
4. Ensure script is executable (`chmod +x`)

### JSON Parsing Fails

1. Ensure stdout contains only JSON (no shell profile output)
2. Check for proper escaping in jq commands
3. Verify exit code is 0 for JSON processing

### Infinite Stop Hook Loop

1. Check `stop_hook_active` field in input
2. Add logic to allow stopping after verification passes
3. Use `once: true` in skill frontmatter if appropriate

### Hook Changes Not Taking Effect

Hooks are captured at startup. Use `/hooks` menu to review changes, or restart the session.

---

## Related Documentation

- **[Hooks Guide](https://code.claude.com/docs/en/hooks-guide)**: Setup walkthrough and examples
- **[Skills](https://code.claude.com/docs/en/skills)**: Define reusable skill workflows
- **[Subagents](https://code.claude.com/docs/en/sub-agents)**: Delegate tasks to specialized agents
- **[Plugins](https://code.claude.com/docs/en/plugins)**: Package hooks with other extensions
- **[Settings](https://code.claude.com/docs/en/settings)**: Configuration file details
- **[Permissions](https://code.claude.com/docs/en/permissions)**: Permission modes and rules
