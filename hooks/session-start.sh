#!/usr/bin/env bash
# SessionStart hook for metaskills
set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Escape for JSON
escape_for_json() {
  local input="$1"
  local output=""
  local i char
  for (( i=0; i<${#input}; i++ )); do
    char="${input:$i:1}"
    case "$char" in
      $'\\') output+='\\' ;;
      '"')   output+='\"' ;;
      $'\n') output+='\n' ;;
      $'\r') output+='\r' ;;
      $'\t') output+='\t' ;;
      *)     output+=" $char" ;;
    esac
  done
  printf '%s' "$output"
}

# Custom startup message
custom_message="$(cat <<'EOF'
<EXTREMELY_IMPORTANT>
You have metaskills in this workspace.

metaskills are higher-order skills that enhance how you plan, execute, and use tools:

- Always propose a lightweight plan before making significant changes
- Prefer file-oriented edits and terminal commands over inline code dumps
- Execute deliberately and verify your actions
- Use available skills and tools systematically, not ad-hoc
- Reflect briefly on risky operations before executing

metaskills does not enforce any specific framework, methodology, or tech stack.
You work with whatever the user already has, making their existing setup more reliable.
</EXTREMELY_IMPORTANT>
EOF
)"

custom_escaped=$(escape_for_json "$custom_message")

# Output hook JSON for Claude Code
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${custom_escaped}"
  }
}
EOF

exit 0
