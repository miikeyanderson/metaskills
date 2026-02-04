---
name: distill
description: Reflect on conversation and create a distilled summary for starting a new session with context
user-invocable: true
---

# Distill Conversation

Reflect on the current conversation at a high level and create a distilled summary that can be used to start a new Claude Code session with essential context.

## Instructions

1. **Reflect on the conversation:**
   - What was the main goal/task?
   - What key decisions were made?
   - What was built/changed?
   - What's the current state?
   - What follow-ups or next steps exist?

2. **Create a distilled summary** with these sections:
   - **Context:** 1-2 sentences on what we were working on
   - **What We Did:** Bullet points of key accomplishments
   - **Key Decisions:** Important choices made and why
   - **Current State:** Where things stand now
   - **Follow-ups:** Any known issues or next steps

3. **Copy to clipboard** using `pbcopy` (macOS) with a header explaining this is a distilled context for a new session.

## Output Format

The clipboard content should be formatted as:

```
[DISTILLED CONTEXT FROM PREVIOUS SESSION]

<distilled summary here>

---
Use this context to continue where we left off.
```
