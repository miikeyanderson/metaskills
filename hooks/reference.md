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

### Personal

- **Path**: `~/.claude/settings.json`
- **Applies to**: All your projects
- **Shareable**: No

### Project

- **Path**: `.claude/settings.json`
- **Applies to**: Single project
- **Shareable**: Yes, commit to repo

### Local

- **Path**: `.claude/settings.local.json`
- **Applies to**: Single project
- **Shareable**: No, gitignored

### Plugin

- **Path**: `<plugin>/hooks/hooks.json`
- **Applies to**: When plugin enabled
- **Shareable**: Yes

### Skill/Agent

- **Path**: YAML frontmatter
- **Applies to**: While component active
- **Shareable**: Yes

**Priority**: Hooks from all locations merge and run in parallel.

---

## Hook Events Reference

All available hook events and when they fire:

### SessionStart

- **When**: Session begins or resumes
- **Can block**: No

### UserPromptSubmit

- **When**: User submits prompt, before processing
- **Can block**: Yes

### PreToolUse

- **When**: Before a tool call executes
- **Can block**: Yes

### PermissionRequest

- **When**: Permission dialog appears
- **Can block**: Yes

### PostToolUse

- **When**: After a tool call succeeds
- **Can block**: No

### PostToolUseFailure

- **When**: After a tool call fails
- **Can block**: No

### Notification

- **When**: Claude Code sends a notification
- **Can block**: No

### SubagentStart

- **When**: Subagent is spawned
- **Can block**: No

### SubagentStop

- **When**: Subagent finishes
- **Can block**: Yes

### Stop

- **When**: Claude finishes responding
- **Can block**: Yes

### PreCompact

- **When**: Before context compaction
- **Can block**: No

### SessionEnd

- **When**: Session terminates
- **Can block**: No

---

## Matcher Patterns Reference

The `matcher` field is a regex that filters when hooks fire. Omit or use `"*"` to match all.

### PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest

Matches on **tool name**:
- `Bash` - shell commands
- `Edit` - file edits
- `Write` - file creation
- `Read` - file reading
- `Glob` - file pattern matching
- `Grep` - content search
- `Task` - subagent spawning
- `WebFetch` - URL fetching
- `WebSearch` - web search
- `mcp__<server>__<tool>` - MCP tools (e.g., `mcp__memory__.*`)
- `Edit|Write` - regex to match multiple tools

### SessionStart

Matches on **how session started**:
- `startup` - new session
- `resume` - `--resume`, `--continue`, or `/resume`
- `clear` - `/clear` command
- `compact` - auto or manual compaction

### SessionEnd

Matches on **why session ended**:
- `clear` - session cleared with `/clear`
- `logout` - user logged out
- `prompt_input_exit` - user exited while prompt visible
- `bypass_permissions_disabled` - bypass permissions mode disabled
- `other` - other exit reasons

### Notification

Matches on **notification type**:
- `permission_prompt` - permission dialog shown
- `idle_prompt` - idle notification
- `auth_success` - authentication succeeded
- `elicitation_dialog` - elicitation dialog shown

### SubagentStart, SubagentStop

Matches on **agent type**:
- `Bash` - bash agent
- `Explore` - exploration agent
- `Plan` - planning agent
- Custom agent names from `.claude/agents/`

### PreCompact

Matches on **compaction trigger**:
- `manual` - `/compact` command
- `auto` - automatic context compaction

### UserPromptSubmit, Stop

**No matcher support** - always fires on every occurrence.

---

## Hook Handler Fields Reference

### Common Fields (All Types)

#### `type`

- **Type**: String
- **Required**: Yes
- **Values**: `"command"`, `"prompt"`, or `"agent"`

#### `timeout`

- **Type**: Number
- **Required**: No
- **Default**: 600 (command), 30 (prompt), 60 (agent)
- **Description**: Seconds before canceling

#### `statusMessage`

- **Type**: String
- **Required**: No
- **Description**: Custom spinner message while running

#### `once`

- **Type**: Boolean
- **Required**: No
- **Default**: `false`
- **Description**: Run only once per session (skills only)

### Command Hook Fields

#### `command`

- **Type**: String
- **Required**: Yes
- **Description**: Shell command to execute

#### `async`

- **Type**: Boolean
- **Required**: No
- **Default**: `false`
- **Description**: Run in background without blocking

### Prompt/Agent Hook Fields

#### `prompt`

- **Type**: String
- **Required**: Yes
- **Description**: Prompt text. Use `$ARGUMENTS` for hook input JSON

#### `model`

- **Type**: String
- **Required**: No
- **Default**: haiku
- **Description**: Model to use for evaluation

---

## Environment Variables

Available in hook commands:

### `$CLAUDE_PROJECT_DIR`

- **Description**: Project root directory
- **Available in**: All hooks

### `${CLAUDE_PLUGIN_ROOT}`

- **Description**: Plugin's root directory
- **Available in**: Plugin hooks

### `$CLAUDE_ENV_FILE`

- **Description**: Path to persist environment variables
- **Available in**: SessionStart only

### `$CLAUDE_CODE_REMOTE`

- **Description**: Set to `"true"` in remote web environments
- **Available in**: All hooks

---

## Hook Input Reference (stdin JSON)

### Common Input Fields

All hooks receive these fields via stdin:

#### `session_id`

- **Type**: String
- **Description**: Current session identifier

#### `transcript_path`

- **Type**: String
- **Description**: Path to conversation JSON

#### `cwd`

- **Type**: String
- **Description**: Current working directory

#### `permission_mode`

- **Type**: String
- **Description**: `"default"`, `"plan"`, `"acceptEdits"`, `"dontAsk"`, or `"bypassPermissions"`

#### `hook_event_name`

- **Type**: String
- **Description**: Name of the event that fired

### SessionStart Input

#### `source`

- **Type**: String
- **Description**: `"startup"`, `"resume"`, `"clear"`, or `"compact"`

#### `model`

- **Type**: String
- **Description**: Model identifier

#### `agent_type`

- **Type**: String
- **Description**: Agent name if started with `claude --agent <name>`

### UserPromptSubmit Input

#### `prompt`

- **Type**: String
- **Description**: Text the user submitted

### PreToolUse Input

#### `tool_name`

- **Type**: String
- **Description**: Name of the tool

#### `tool_input`

- **Type**: Object
- **Description**: Tool-specific input parameters

#### `tool_use_id`

- **Type**: String
- **Description**: Unique identifier for this tool call

### PermissionRequest Input

#### `tool_name`

- **Type**: String
- **Description**: Name of the tool

#### `tool_input`

- **Type**: Object
- **Description**: Tool-specific input parameters

#### `permission_suggestions`

- **Type**: Array
- **Description**: "Always allow" options user would see

### PostToolUse Input

#### `tool_name`

- **Type**: String
- **Description**: Name of the tool

#### `tool_input`

- **Type**: Object
- **Description**: Tool-specific input parameters

#### `tool_response`

- **Type**: Object
- **Description**: Result returned by the tool

#### `tool_use_id`

- **Type**: String
- **Description**: Unique identifier for this tool call

### PostToolUseFailure Input

#### `tool_name`

- **Type**: String
- **Description**: Name of the tool

#### `tool_input`

- **Type**: Object
- **Description**: Tool-specific input parameters

#### `tool_use_id`

- **Type**: String
- **Description**: Unique identifier for this tool call

#### `error`

- **Type**: String
- **Description**: Error description

#### `is_interrupt`

- **Type**: Boolean
- **Description**: Whether caused by user interruption

### Notification Input

#### `message`

- **Type**: String
- **Description**: Notification text

#### `title`

- **Type**: String
- **Description**: Optional notification title

#### `notification_type`

- **Type**: String
- **Description**: Type that triggered the hook

### SubagentStart Input

#### `agent_id`

- **Type**: String
- **Description**: Unique identifier for the subagent

#### `agent_type`

- **Type**: String
- **Description**: Agent type name

### SubagentStop Input

#### `stop_hook_active`

- **Type**: Boolean
- **Description**: Whether already continuing from a stop hook

#### `agent_id`

- **Type**: String
- **Description**: Unique identifier for the subagent

#### `agent_type`

- **Type**: String
- **Description**: Agent type name

#### `agent_transcript_path`

- **Type**: String
- **Description**: Path to subagent's transcript

### Stop Input

#### `stop_hook_active`

- **Type**: Boolean
- **Description**: Whether already continuing from a stop hook

### PreCompact Input

#### `trigger`

- **Type**: String
- **Description**: `"manual"` or `"auto"`

#### `custom_instructions`

- **Type**: String
- **Description**: User input from `/compact` (empty for auto)

### SessionEnd Input

#### `reason`

- **Type**: String
- **Description**: Why the session ended

---

## Tool Input Schemas

### Bash

#### `command`

- **Type**: String
- **Description**: Shell command to execute

#### `description`

- **Type**: String
- **Description**: Optional description

#### `timeout`

- **Type**: Number
- **Description**: Optional timeout in milliseconds

#### `run_in_background`

- **Type**: Boolean
- **Description**: Whether to run in background

### Write

#### `file_path`

- **Type**: String
- **Description**: Absolute path to file

#### `content`

- **Type**: String
- **Description**: Content to write

### Edit

#### `file_path`

- **Type**: String
- **Description**: Absolute path to file

#### `old_string`

- **Type**: String
- **Description**: Text to find and replace

#### `new_string`

- **Type**: String
- **Description**: Replacement text

#### `replace_all`

- **Type**: Boolean
- **Description**: Whether to replace all occurrences

### Read

#### `file_path`

- **Type**: String
- **Description**: Absolute path to file

#### `offset`

- **Type**: Number
- **Description**: Optional line number to start from

#### `limit`

- **Type**: Number
- **Description**: Optional number of lines to read

### Glob

#### `pattern`

- **Type**: String
- **Description**: Glob pattern to match

#### `path`

- **Type**: String
- **Description**: Optional directory to search

### Grep

#### `pattern`

- **Type**: String
- **Description**: Regex pattern to search

#### `path`

- **Type**: String
- **Description**: Optional file or directory

#### `glob`

- **Type**: String
- **Description**: Optional glob filter

#### `output_mode`

- **Type**: String
- **Description**: `"content"`, `"files_with_matches"`, or `"count"`

#### `-i`

- **Type**: Boolean
- **Description**: Case insensitive search

#### `multiline`

- **Type**: Boolean
- **Description**: Enable multiline matching

### WebFetch

#### `url`

- **Type**: String
- **Description**: URL to fetch

#### `prompt`

- **Type**: String
- **Description**: Prompt to run on fetched content

### WebSearch

#### `query`

- **Type**: String
- **Description**: Search query

#### `allowed_domains`

- **Type**: Array
- **Description**: Optional: only include these domains

#### `blocked_domains`

- **Type**: Array
- **Description**: Optional: exclude these domains

### Task

#### `prompt`

- **Type**: String
- **Description**: Task for the agent

#### `description`

- **Type**: String
- **Description**: Short description

#### `subagent_type`

- **Type**: String
- **Description**: Type of agent to use

#### `model`

- **Type**: String
- **Description**: Optional model override

---

## Exit Code Behavior

### Exit Code 0

- **Meaning**: Success
- **Effect**: Proceed; parse stdout for JSON

### Exit Code 2

- **Meaning**: Blocking error
- **Effect**: Block action; stderr shown as error

### Other Exit Codes

- **Meaning**: Non-blocking error
- **Effect**: Continue; stderr shown in verbose mode

### Exit Code 2 Behavior by Event

#### Events that CAN block

- `PreToolUse` - Blocks the tool call
- `PermissionRequest` - Denies the permission
- `UserPromptSubmit` - Blocks and erases prompt
- `Stop` - Prevents stopping, continues conversation
- `SubagentStop` - Prevents subagent from stopping

#### Events that CANNOT block

- `PostToolUse` - Shows stderr to Claude (tool already ran)
- `PostToolUseFailure` - Shows stderr to Claude
- `Notification` - Shows stderr to user only
- `SubagentStart` - Shows stderr to user only
- `SessionStart` - Shows stderr to user only
- `SessionEnd` - Shows stderr to user only
- `PreCompact` - Shows stderr to user only

---

## JSON Output Reference (stdout)

### Universal Fields

Available to all hooks:

#### `continue`

- **Type**: Boolean
- **Default**: `true`
- **Description**: If `false`, Claude stops entirely

#### `stopReason`

- **Type**: String
- **Description**: Message shown to user when `continue` is `false`

#### `suppressOutput`

- **Type**: Boolean
- **Default**: `false`
- **Description**: Hide stdout from verbose mode

#### `systemMessage`

- **Type**: String
- **Description**: Warning message shown to user

### Decision Control by Event

#### Top-level `decision` pattern

Used by: `UserPromptSubmit`, `PostToolUse`, `PostToolUseFailure`, `Stop`, `SubagentStop`

- Key fields: `decision: "block"`, `reason`

#### `hookSpecificOutput` pattern for PreToolUse

- Key fields: `permissionDecision`, `permissionDecisionReason`, `updatedInput`

#### `hookSpecificOutput` pattern for PermissionRequest

- Key fields: `decision.behavior`, `decision.updatedInput`

### SessionStart Output

#### `additionalContext`

- **Type**: String
- **Description**: Context added for Claude

### UserPromptSubmit Output

#### `decision`

- **Type**: String
- **Description**: `"block"` to prevent processing

#### `reason`

- **Type**: String
- **Description**: Shown to user when blocked

#### `additionalContext`

- **Type**: String
- **Description**: Context added for Claude

### PreToolUse Output

#### `permissionDecision`

- **Type**: String
- **Description**: `"allow"`, `"deny"`, or `"ask"`

#### `permissionDecisionReason`

- **Type**: String
- **Description**: Reason shown to user/Claude

#### `updatedInput`

- **Type**: Object
- **Description**: Modified tool input parameters

#### `additionalContext`

- **Type**: String
- **Description**: Context added for Claude

### PermissionRequest Output

#### `decision.behavior`

- **Type**: String
- **Description**: `"allow"` or `"deny"`

#### `decision.updatedInput`

- **Type**: Object
- **Description**: Modified tool input (allow only)

#### `decision.updatedPermissions`

- **Type**: Array
- **Description**: Permission rules to apply (allow only)

#### `decision.message`

- **Type**: String
- **Description**: Reason for deny

#### `decision.interrupt`

- **Type**: Boolean
- **Description**: Stop Claude on deny

### PostToolUse Output

#### `decision`

- **Type**: String
- **Description**: `"block"` to prompt Claude with reason

#### `reason`

- **Type**: String
- **Description**: Explanation for Claude

#### `additionalContext`

- **Type**: String
- **Description**: Additional context for Claude

#### `updatedMCPToolOutput`

- **Type**: Any
- **Description**: Replace MCP tool output

### PostToolUseFailure Output

#### `additionalContext`

- **Type**: String
- **Description**: Context about the failure

### SubagentStart Output

#### `additionalContext`

- **Type**: String
- **Description**: Context for the subagent

### Stop / SubagentStop Output

#### `decision`

- **Type**: String
- **Description**: `"block"` to prevent stopping

#### `reason`

- **Type**: String
- **Description**: Required when blocking; tells Claude why to continue

### Prompt/Agent Hook Response

Must return:

#### `ok`

- **Type**: Boolean
- **Description**: `true` to allow, `false` to block

#### `reason`

- **Type**: String
- **Description**: Required when `ok` is `false`

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
