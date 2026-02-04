#!/usr/bin/env bash
# SessionStart hook - injects skills + tasks guidance at session start

set -euo pipefail

# ANSI colors for status output
ORANGE='\033[38;5;208m'
RESET='\033[0m'
STATUS_MSG='✻ metaskills loaded...'

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

using_skills_file="${PLUGIN_ROOT}/skills/using-skills/SKILL.md"
using_tasks_file="${PLUGIN_ROOT}/skills/using-tasks/SKILL.md"

# compact|full (set GUIDANCE_MODE=full if you want full SKILL.md bodies)
GUIDANCE_MODE="${GUIDANCE_MODE:-compact}"

read_guidance() {
    local file="$1"
    local label="$2"

    if [[ ! -f "$file" ]]; then
        printf 'Error reading %s skill: %s\n' "$label" "$file"
        return 0
    fi

    if [[ "$GUIDANCE_MODE" == "full" ]]; then
        cat "$file"
        return 0
    fi

    # Compact mode: include high-priority block + "The Rule" section only.
    awk '
        /^<EXTREMELY-IMPORTANT>/, /^<\/EXTREMELY-IMPORTANT>/ { print; next }
        /^## The Rule$/ { in_rule=1; print; next }
        in_rule && /^## / { exit }
        in_rule { print }
    ' "$file"
}

# Escape outputs for JSON using pure bash
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            $'\\') output+='\\\\' ;;
            '"') output+='\"' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *) output+="$char" ;;
        esac
    done
    printf '%s' "$output"
}

using_skills_content="$(read_guidance "$using_skills_file" "using-skills")"
using_tasks_content="$(read_guidance "$using_tasks_file" "using-tasks")"

using_skills_escaped="$(escape_for_json "$using_skills_content")"
using_tasks_escaped="$(escape_for_json "$using_tasks_content")"

custom_message="✻ You have enhanced capabilities in this workspace.

Operational order (follow strictly):
1) Skills workflow first (determine HOW to do the task)
2) Tasks workflow second (track execution for multi-step work)

If both apply, use both."

custom_escaped="$(escape_for_json "$custom_message")"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\n${custom_escaped}\n\n## USING-SKILLS GUIDANCE\n${using_skills_escaped}\n\n## USING-TASKS GUIDANCE\n${using_tasks_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

# Create marker file for statusline to detect
touch "$HOME/.claude/.metaskills_loaded"

# Print status to stderr (visible to user, doesn't break JSON on stdout)
printf '%b%s%b\n' "$ORANGE" "$STATUS_MSG" "$RESET" >&2

exit 0
