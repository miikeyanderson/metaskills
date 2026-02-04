# Claude Code SKILL.md Complete Reference

This document provides a comprehensive reference for all available options, fields, and features when creating SKILL.md files in Claude Code.

---

## File Structure

Every skill requires a `SKILL.md` file with two parts:

1. **YAML frontmatter** (between `---` markers) - Configures skill behavior
2. **Markdown content** - Instructions Claude follows when the skill is invoked

```markdown
***
name: my-skill
description: What this skill does
***

Your skill instructions here...
```

---

## Frontmatter Fields Reference

All frontmatter fields are **optional** unless marked as recommended. Fields should be placed between `---` markers at the top of your SKILL.md file.

### `name`

- **Type**: String
- **Required**: No
- **Description**: Display name for the skill. If omitted, uses the directory name. This becomes the `/slash-command` users can invoke.
- **Constraints**: Lowercase letters, numbers, and hyphens only (max 64 characters)
- **Example**: `name: explain-code`

### `description`

- **Type**: String
- **Required**: **Recommended** (critical for automatic invocation)
- **Description**: When to use this skill. Claude uses this to decide when to apply the skill automatically. If omitted, uses the first paragraph of markdown content.
- **Best Practice**: Start with "Use when..." and include triggering conditions. Do NOT summarize workflow—Claude may follow the description instead of reading the full skill.
- **Example**: `description: Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?"`

### `argument-hint`

- **Type**: String
- **Required**: No
- **Description**: Hint shown during autocomplete to indicate expected arguments
- **Example**: `argument-hint: "[issue-number]"` or `argument-hint: "[filename] [format]"`

### `disable-model-invocation`

- **Type**: Boolean
- **Required**: No
- **Default**: `false`
- **Description**: Set to `true` to prevent Claude from automatically loading this skill. Use for workflows you want to trigger manually with `/name`. When set to `true`, the skill description is NOT loaded into context.
- **Use Cases**: Skills with side effects (deploy, commit, send messages) or time-sensitive operations
- **Example**: `disable-model-invocation: true`

### `user-invocable`

- **Type**: Boolean
- **Required**: No
- **Default**: `true`
- **Description**: Set to `false` to hide from the `/` menu. Use for background knowledge users shouldn't invoke directly. The skill description remains in context for Claude to use.
- **Use Cases**: Background knowledge, conventions, or context that isn't actionable as a command
- **Example**: `user-invocable: false`
- **Note**: This only controls menu visibility, not Skill tool access

### `allowed-tools`

- **Type**: String (comma-separated list)
- **Required**: No
- **Description**: Tools Claude can use without asking permission when this skill is active. Your permission settings still govern baseline approval behavior for all other tools.
- **Example**: `allowed-tools: Read, Grep, Glob`
- **Use Cases**: Creating read-only modes, restricting modifications, or pre-approving specific tools for a workflow

### `model`

- **Type**: String
- **Required**: No
- **Description**: Model to use when this skill is active. Overrides the default model setting.
- **Example**: `model: claude-3.7-sonnet`

### `context`

- **Type**: String (enum)
- **Required**: No
- **Values**: `inline` (default) or `fork`
- **Description**: Set to `fork` to run in a forked subagent context. The skill content becomes the prompt that drives the subagent without access to conversation history.
- **Example**: `context: fork`
- **Warning**: Only use `fork` for skills with explicit instructions. Skills with just guidelines need a task to be actionable.

### `agent`

- **Type**: String
- **Required**: No (only relevant when `context: fork` is set)
- **Default**: `general-purpose`
- **Description**: Which subagent type to use when `context: fork` is set
- **Available Options**: 
  - Built-in agents: `Explore`, `Plan`, `general-purpose`
  - Custom subagents from `.claude/agents/`
- **Example**: `agent: Explore`

### `hooks`

- **Type**: Object
- **Required**: No
- **Description**: Hooks scoped to this skill's lifecycle. Allows automation workflows around skill execution.
- **Available Hooks**: `before-run`, `after-run`
- **Reference**: See [Hooks in skills and agents documentation](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents) for complete configuration format
- **Example**:
  ```yaml
  hooks:
    before-run: ...
    after-run: ...
  ```

---

## Invocation Control Matrix

How the `disable-model-invocation` and `user-invocable` fields affect skill behavior:

| Frontmatter | You can invoke | Claude can invoke | When loaded into context |
|-------------|----------------|-------------------|--------------------------|
| (default) | ✅ Yes | ✅ Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | ✅ Yes | ❌ No | Description NOT in context, full skill loads when you invoke |
| `user-invocable: false` | ❌ No | ✅ Yes | Description always in context, full skill loads when invoked |

**Note**: In regular sessions, skill descriptions are loaded into context so Claude knows what's available, but full skill content only loads when invoked. Subagents with preloaded skills work differently: the full skill content is injected at startup.

---

## String Substitutions

Skills support dynamic string substitution in the markdown content. These variables are replaced with actual values when the skill is invoked.

### `$ARGUMENTS`

- **Description**: All arguments passed when invoking the skill as a single string
- **Behavior**: If `$ARGUMENTS` is not present in the content, arguments are automatically appended as `ARGUMENTS: <args>`
- **Example**: `/fix-issue 123` → `$ARGUMENTS` becomes `123`

### `$ARGUMENTS[N]`

- **Description**: Access a specific argument by 0-based index
- **Examples**: 
  - `$ARGUMENTS[0]` - First argument
  - `$ARGUMENTS[1]` - Second argument
  - `$ARGUMENTS[2]` - Third argument

### `$N`

- **Description**: Shorthand for `$ARGUMENTS[N]`
- **Examples**:
  - `$0` - First argument
  - `$1` - Second argument
  - `$2` - Third argument

### `${CLAUDE_SESSION_ID}`

- **Description**: The current session ID
- **Use Cases**: Logging, creating session-specific files, or correlating skill output with sessions
- **Example**: `logs/${CLAUDE_SESSION_ID}.log`

---

## Dynamic Context Injection

### Command Execution Syntax

Use backticks with `!` prefix to run shell commands before the skill content is sent to Claude:

```markdown
!`command here`
```

**How it works**:
1. Each `!`command"` executes immediately (before Claude sees anything)
2. The command output replaces the placeholder in the skill content
3. Claude receives the fully-rendered prompt with actual data

**This is preprocessing, not something Claude executes. Claude only sees the final result.**

### Example: Pull Request Summary

```markdown
***
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
***

## Pull request context

- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task

Summarize this pull request and highlight the most important changes.
```

---

## Skill Content Patterns

### Reference Content

**Purpose**: Adds knowledge Claude applies to your current work

**Characteristics**:
- Conventions, patterns, style guides, domain knowledge
- Runs inline so Claude can use it alongside conversation context
- Usually has default invocation settings (both user and Claude can invoke)

**Example**:
```markdown
***
name: api-conventions
description: API design patterns for this codebase
***

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

### Task Content

**Purpose**: Step-by-step instructions for a specific action

**Characteristics**:
- Actions like deployments, commits, code generation
- Often invoked directly with `/skill-name`
- Usually has `disable-model-invocation: true` to prevent automatic triggering

**Example**:
```markdown
***
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
***

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
4. Verify the deployment succeeded
```

---

## Supporting Files

Skills can include multiple files in their directory to keep `SKILL.md` focused:

```
my-skill/
├── SKILL.md          # Required: Main instructions & navigation
├── reference.md      # Optional: Detailed API docs - loaded when needed
├── examples.md       # Optional: Usage examples - loaded when needed
└── scripts/
    └── helper.py     # Optional: Utility script - executed, not loaded
```

### Best Practices

- Keep `SKILL.md` under 500 lines
- Move detailed reference material to separate files
- Reference supporting files from `SKILL.md` so Claude knows what they contain

### Linking to Supporting Files

```markdown
## Additional resources

- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

---

## Skill Location & Priority

Where you store a skill determines who can use it:

| Location | Path | Applies to | Priority |
|----------|------|------------|----------|
| Enterprise | See managed settings | All users in organization | Highest |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects | High |
| Project | `.claude/skills/<name>/SKILL.md` | This project only | Medium |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin is enabled | N/A (namespaced) |

**Priority Rules**:
- When skills share the same name: enterprise > personal > project
- Plugin skills use `plugin-name:skill-name` namespace and cannot conflict
- Skills take precedence over `.claude/commands/` files with the same name

### Automatic Discovery

Claude Code automatically discovers skills from nested `.claude/skills/` directories. For example, if you're editing `packages/frontend/file.ts`, Claude also looks for skills in `packages/frontend/.claude/skills/`. This supports monorepo setups where packages have their own skills.

---

## Special Features

### Extended Thinking Mode

To enable extended thinking in a skill, include the word `ultrathink` anywhere in your skill content.

**Example**:
```markdown
***
name: deep-analysis
description: Perform deep analysis with extended thinking
***

Use ultrathink to analyze this thoroughly...
```

### Subagent Execution

When using `context: fork`, skills and subagents work together in two directions:

| Approach | System prompt | Task | Also loads |
|----------|---------------|------|------------|
| Skill with `context: fork` | From agent type (`Explore`, `Plan`, etc.) | SKILL.md content | CLAUDE.md |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md |

---

## Permission Control

### Restricting Claude's Skill Access

By default, Claude can invoke any skill without `disable-model-invocation: true`. You can control this through permission rules:

**Disable all skills**:
```
# In /permissions deny rules:
Skill
```

**Allow or deny specific skills**:
```
# Allow only specific skills
Skill(commit)
Skill(review-pr *)

# Deny specific skills
Skill(deploy *)
```

**Permission Syntax**:
- `Skill(name)` - Exact match
- `Skill(name *)` - Prefix match with any arguments

**Note**: Built-in commands like `/compact` and `/init` are not available through the Skill tool.

---

## Complete Example Templates

### Reference Skill Template

```markdown
***
name: coding-standards
description: Team coding standards and conventions. Use when writing or reviewing code.
user-invocable: true
***

# Coding Standards

## Code Style
- Use consistent formatting
- Follow naming conventions
- Add comments for complex logic

## Testing
- Write unit tests for all functions
- Aim for 80%+ coverage
- Use descriptive test names
```

### Task Skill Template

```markdown
***
name: deploy
description: Deploy application to production
disable-model-invocation: true
context: fork
agent: general-purpose
allowed-tools: Bash(*)
argument-hint: "[environment]"
***

# Deployment Process

Deploy to $ARGUMENTS environment:

1. Run test suite
2. Build application
3. Push to server
4. Verify deployment
```

### Research Skill Template

```markdown
***
name: deep-research
description: Research a topic thoroughly across the codebase
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
argument-hint: "[topic]"
***

# Research Task

Research $ARGUMENTS thoroughly:

1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

### Dynamic Context Skill Template

```markdown
***
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
***

## Pull request context

- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task

Summarize this pull request and highlight:
- Most important changes
- Potential risks
- Files requiring careful review
```

---

## Troubleshooting

### Skill Not Triggering

If Claude doesn't use your skill when expected:

1. Check the description includes keywords users would naturally say
2. Verify the skill appears in "What skills are available?"
3. Try rephrasing your request to match the description more closely
4. Invoke it directly with `/skill-name` if the skill is user-invocable

### Skill Triggers Too Often

If Claude uses your skill when you don't want it:

1. Make the description more specific
2. Add `disable-model-invocation: true` if you only want manual invocation

### Claude Doesn't See All Skills

Skill descriptions are loaded into context with a default character budget of 15,000 characters. If you have many skills, they may exceed this limit.

**Check**: Run `/context` to check for a warning about excluded skills

**Solution**: Set the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable to increase the limit

---

## Related Documentation

- **[Subagents](https://code.claude.com/docs/en/sub-agents)**: Delegate tasks to specialized agents
- **[Plugins](https://code.claude.com/docs/en/plugins)**: Package and distribute skills with other extensions
- **[Hooks](https://code.claude.com/docs/en/hooks)**: Automate workflows around tool events
- **[Memory](https://code.claude.com/docs/en/memory)**: Manage CLAUDE.md files for persistent context
- **[Interactive mode](https://code.claude.com/docs/en/interactive-mode)**: Built-in commands and shortcuts
- **[Permissions](https://code.claude.com/docs/en/permissions)**: Control tool and skill access