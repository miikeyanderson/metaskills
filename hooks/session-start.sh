#!/usr/bin/env bash
# SessionStart hook for metaskills plugin
# Injects mandatory protocol at session start

set -euo pipefail

# ANSI colors for status output
ORANGE='\033[38;5;208m'
RESET='\033[0m'
STATUS_MSG='✻ metaskills loaded...'

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

# SHORT VARIANT - Tight protocol for session start (~1.5k chars)
protocol="SESSION START PROTOCOL (MANDATORY)

You MUST execute this sequence on every substantive request. No shortcuts.

1) GATE A — TASK PLAN (BLOCKING)
- Decompose the user request into atomic tasks.
- Create each task with TaskCreate (subject, description, activeForm).
- Set exactly one task to in_progress via TaskUpdate.
- All other not-started tasks remain pending.
- SKIP ONLY IF: Request is trivially atomic (single action, no follow-up).

2) GATE B — SKILL TRIGGER CHECK (BLOCKING)
- Evaluate request against skill triggers BEFORE execution:
  • production code → metaskills:tdd
  • create/edit skills → metaskills:creating-skills
  • create/edit hooks → metaskills:creating-hooks
  • git commit → metaskills:commit
  • session handoff/summary → metaskills:distill
  • high-stakes decision, architecture, second opinion → codex-mcp / gemini-mcp
- If a trigger matches, invoke Skill tool first, then execute.
- If a matched skill is NOT used, you MUST state: \"Skill skip reason: [skill] not invoked because [reason].\"

EXECUTION RULES
- Start task: TaskUpdate → in_progress
- Finish task: TaskUpdate → completed (only after verification)
- Keep exactly ONE in_progress task at a time
- Use TaskList after each completion to select next task
- Use TaskGet when details are ambiguous; do not assume

FALLBACK (NO BYPASS)
- If blocked, create a blocker task describing the dependency.
- Do not bypass protocol. Do not silently skip tools/skills.
- No \"best effort\" language. No rationalization.

PROHIBITED THOUGHTS
- \"I can do this quickly without tasks.\"
- \"This is obvious, no need to call the skill.\"
- \"I'll update tasks at the end.\"
- \"I skipped the skill to save time.\"

For detailed guidance, invoke: Skill(metaskills:using-tasks) or Skill(metaskills:using-skills)"

protocol_escaped=$(escape_for_json "$protocol")

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\n${protocol_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

# Create marker file for statusline to detect
touch "$HOME/.claude/.metaskills_loaded"

# Print status to stderr (visible to user, doesn't break JSON on stdout)
printf '%b%s%b\n' "$ORANGE" "$STATUS_MSG" "$RESET" >&2

exit 0
