# Metaskills

A Claude Code plugin with skills for productivity, TDD, task management, and workflow automation.

## Installation

### From GitHub

```bash
/plugin install https://github.com/mikeyanderson/metaskills
```

### Local Development

```bash
claude --plugin-dir /path/to/metaskills
```

## Skills

All skills are namespaced with `metaskills:` when installed as a plugin.

| Skill | Description |
|-------|-------------|
| `using-skills` | How to find and use skills - establishes skill-first workflow |
| `using-tasks` | Task management for multi-step work using Claude Code's Task tools |
| `tdd` | Test-Driven Development - write tests first, then implementation |
| `creating-skills` | Create new skills using TDD principles |
| `creating-hooks` | Create hooks to automate workflows around Claude Code events |
| `distill` | Reflect on conversation and create a distilled summary for new sessions |
| `writing-tasks` | Multi-model council workflow with Codex and Gemini for writing tasks |

## Commands

| Command | Description |
|---------|-------------|
| `/metaskills:commit` | Create git commits with Codex review |
| `/metaskills:create-reference` | Create reference documentation for skills |

## Hooks

The plugin includes a session-start hook that injects context at the beginning of each session.

## Usage

After installing the plugin, skills are available with the `metaskills:` prefix:

```
/metaskills:tdd
/metaskills:using-tasks
/metaskills:commit
```

Or Claude will automatically invoke relevant skills based on context.

## Structure

```
metaskills/
├── .claude-plugin/
│   └── plugin.json      # Plugin manifest
├── skills/              # Agent skills
│   ├── using-skills/
│   ├── using-tasks/
│   ├── tdd/
│   ├── creating-skills/
│   ├── creating-hooks/
│   ├── distill/
│   └── writing-tasks/
├── commands/            # Slash commands
│   ├── commit.md
│   └── create-reference.md
└── hooks/               # Automation hooks
    ├── hooks.json
    └── session-start.sh
```

## License

MIT
