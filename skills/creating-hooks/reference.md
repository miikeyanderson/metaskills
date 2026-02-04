# Creating Hooks Complete Reference

This document provides a comprehensive reference for creating hooks that automate workflows in Claude Code. Hooks are shell commands that execute at specific lifecycle points.

---

## Hook Types

### Command Hooks

- **Type**: `"command"`
- **Description**: Run a shell command when the event fires
- **Use case**: Deterministic rules, formatting, notifications, validation

### Prompt Hooks

- **Type**: `"prompt"`
- **Description**: Send a prompt to a Claude model for single-turn evaluation
- **Use case**: Decisions requiring judgment rather than rules
- **Response format**: `{"ok": true}` or `{"ok": false, "reason": "..."}`

### Agent Hooks

- **Type**: `"agent"`
- **Description**: Spawn a subagent with tool access for multi-turn verification
- **Use case**: Verification requiring file inspection or command execution
- **Response format**: Same as prompt hooks
- **Max turns**: 50

---

## Hook Events

### SessionStart

- **When**: Session begins or resumes
- **Matcher values**: `startup`, `resume`, `clear`, `compact`
- **Can block**: No
- **Stdout behavior**: Added to Claude's context

### UserPromptSubmit

- **When**: User submits a prompt, before Claude processes it
- **Matcher**: No matcher support, always fires
- **Can block**: Yes (exit 2)
- **Stdout behavior**: Added to Claude's context

### PreToolUse

- **When**: Before a tool call executes
- **Matcher values**: Tool names (`Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Task`, `WebFetch`, `WebSearch`, `mcp__*`)
- **Can block**: Yes (exit 2 or JSON decision)

### PermissionRequest

- **When**: Permission dialog appears
- **Matcher values**: Tool names (same as PreToolUse)
- **Can block**: Yes
- **Note**: Does not fire in non-interactive mode (`-p`)

### PostToolUse

- **When**: After a tool call succeeds
- **Matcher values**: Tool names
- **Can block**: No (tool already ran)

### PostToolUseFailure

- **When**: After a tool call fails
- **Matcher values**: Tool names
- **Can block**: No

### Notification

- **When**: Claude Code sends a notification
- **Matcher values**: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`
- **Can block**: No

### SubagentStart

- **When**: Subagent is spawned
- **Matcher values**: Agent types (`Bash`, `Explore`, `Plan`, custom names)
- **Can block**: No

### SubagentStop

- **When**: Subagent finishes
- **Matcher values**: Agent types
- **Can block**: Yes

### Stop

- **When**: Claude finishes responding
- **Matcher**: No matcher support, always fires
- **Can block**: Yes
- **Note**: Does not fire on user interrupts

### PreCompact

- **When**: Before context compaction
- **Matcher values**: `manual`, `auto`
- **Can block**: No

### SessionEnd

- **When**: Session terminates
- **Matcher values**: `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`
- **Can block**: No

---

## Hook Configuration

### Basic Structure

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

### Configuration Fields

#### `matcher`

- **Type**: String (regex)
- **Required**: No
- **Default**: Matches all (same as `"*"` or `""`)
- **Description**: Regex pattern to filter when the hook fires

#### `type`

- **Type**: String
- **Required**: Yes
- **Values**: `"command"`, `"prompt"`, `"agent"`

#### `command`

- **Type**: String
- **Required**: Yes (for command hooks)
- **Description**: Shell command to execute

#### `prompt`

- **Type**: String
- **Required**: Yes (for prompt/agent hooks)
- **Description**: Prompt text sent to Claude model

#### `timeout`

- **Type**: Number (seconds)
- **Required**: No
- **Default**: 600 (command), 30 (prompt), 60 (agent)

#### `model`

- **Type**: String
- **Required**: No
- **Default**: Haiku
- **Description**: Model for prompt/agent hooks

---

## Hook Input (stdin JSON)

### Common Fields

All hooks receive these fields:

#### `session_id`

- **Type**: String
- **Description**: Unique ID for this session

#### `cwd`

- **Type**: String
- **Description**: Working directory when the event fired

#### `hook_event_name`

- **Type**: String
- **Description**: Which event triggered this hook

### Tool Event Fields

For PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest:

#### `tool_name`

- **Type**: String
- **Description**: The tool being used

#### `tool_input`

- **Type**: Object
- **Description**: Arguments passed to the tool

### Stop Event Fields

#### `stop_hook_active`

- **Type**: Boolean
- **Description**: Whether already continuing from a stop hook
- **Important**: Check this to prevent infinite loops

---

## Hook Output

### Exit Codes

#### Exit 0

- **Meaning**: Success, action proceeds
- **Stdout**: Parsed for JSON; for SessionStart/UserPromptSubmit, added to context

#### Exit 2

- **Meaning**: Block the action
- **Stderr**: Fed back to Claude as feedback

#### Other Exit Codes

- **Meaning**: Non-blocking error
- **Stderr**: Logged in verbose mode only

### JSON Output (stdout on exit 0)

#### PreToolUse Decision

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Reason shown to Claude"
  }
}
```

**permissionDecision values**:
- `"allow"` - proceed without permission prompt
- `"deny"` - cancel and send reason to Claude
- `"ask"` - show permission prompt to user

#### Stop/PostToolUse Decision

```json
{
  "decision": "block",
  "reason": "Explanation for Claude"
}
```

#### Prompt/Agent Hook Response

```json
{
  "ok": true
}
```

or

```json
{
  "ok": false,
  "reason": "What remains to be done"
}
```

---

## Hook Locations

### User Settings

- **Path**: `~/.claude/settings.json`
- **Scope**: All your projects
- **Shareable**: No

### Project Settings

- **Path**: `.claude/settings.json`
- **Scope**: Single project
- **Shareable**: Yes, commit to repo

### Local Settings

- **Path**: `.claude/settings.local.json`
- **Scope**: Single project
- **Shareable**: No, gitignored

### Plugin

- **Path**: `<plugin>/hooks/hooks.json`
- **Scope**: When plugin enabled
- **Shareable**: Yes

### Skill/Agent Frontmatter

- **Scope**: While component active
- **Shareable**: Yes

---

## Environment Variables

#### `$CLAUDE_PROJECT_DIR`

- **Description**: Project root directory
- **Available in**: All hooks

#### `${CLAUDE_PLUGIN_ROOT}`

- **Description**: Plugin's root directory
- **Available in**: Plugin hooks

#### `$CLAUDE_ENV_FILE`

- **Description**: Path to persist environment variables
- **Available in**: SessionStart only

---

## Example Configurations

### Desktop Notification (macOS)

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### Auto-format with Prettier

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

Script (`.claude/hooks/protect-files.sh`):
```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

Configuration:
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

### Re-inject Context After Compaction

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing.'"
          }
        ]
      }
    ]
  }
}
```

### Prompt-based Stop Verification

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains\"}."
          }
        ]
      }
    ]
  }
}
```

### Agent-based Test Verification

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

### Prevent Stop Hook Infinite Loop

```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... rest of your hook logic
```

---

## Troubleshooting

### Hook Not Firing

1. Run `/hooks` and confirm the hook appears under correct event
2. Check matcher pattern matches tool name exactly (case-sensitive)
3. Verify correct event type (PreToolUse = before, PostToolUse = after)
4. For PermissionRequest in non-interactive mode, use PreToolUse instead

### Hook Error in Output

1. Test script manually: `echo '{"tool_name":"Bash"}' | ./my-hook.sh`
2. Check exit code: `echo $?`
3. Use absolute paths or `$CLAUDE_PROJECT_DIR`
4. Install `jq` if needed: `brew install jq`
5. Make script executable: `chmod +x ./my-hook.sh`

### JSON Validation Failed

Shell profile echo statements interfere with JSON output. Wrap them:
```bash
# In ~/.zshrc or ~/.bashrc
if [[ $- == *i* ]]; then
  echo "Shell ready"
fi
```

### Stop Hook Runs Forever

Check `stop_hook_active` field and exit early if true.

### /hooks Shows No Hooks

1. Restart session or open `/hooks` to reload
2. Verify JSON is valid (no trailing commas or comments)
3. Confirm settings file location

### Debug Techniques

- Toggle verbose mode: `Ctrl+O`
- Run with debug: `claude --debug`

---

## Related resources

- Skills: define reusable skill workflows
- Subagents: delegate tasks to specialized agents
- Plugins: package hooks with other extensions
- Memory: manage CLAUDE.md files for persistent context

Skills:
@~/metaskills/.claude/skills

Commands:
@~/metaskills/.claude/commands

Hooks:
@~/metaskills/.claude/hooks
