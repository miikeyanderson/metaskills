# metaskills

metaskills is a Claude Code plugin that upgrades how Claude *thinks* and *works* in your workspace, without forcing any particular framework or methodology. Instead of just adding more tools, it gives Claude higher-order "meta skills" for planning, execution, and feedback, so it behaves more like a focused coding CLI than a chatty assistant.

## What metaskills does

metaskills is not a software development methodology, opinionated framework, or stack. It is a thin layer that:

- Improves how Claude plans before it writes or edits code
- Tightens how it uses tools (files, terminals, skills) as a coherent CLI-like harness
- Encourages deliberate, verifiable execution instead of random guesses
- Works on top of whatever languages, frameworks, or workflows you already use

Think of it as a set of "meta skills" that amplify all of Claude's existing capabilities, rather than a new set of domain-specific rules.

## Key behaviors

Out of the box, metaskills teaches Claude to:

- Propose a lightweight plan before large changes, then execute against that plan step by step
- Prefer file-oriented edits and terminal commands over dumping giant code blobs into chat
- Reflect briefly on risky actions (migrations, refactors, deletes) and surface sanity checks
- Use your existing tools and skills more systematically instead of ad-hoc

There is no enforced TDD, framework choice, or architectural pattern. You keep your style; Claude just becomes more disciplined.

## Installation

> Requires Claude Code with plugin support.

### From GitHub

```bash
cd ~/.claude/plugins  # or your Claude Code plugins directory
git clone https://github.com/miikeyanderson/metaskills.git
```

Restart your Claude Code session so the SessionStart hook can run.

## How it works (high level)

metaskills uses:

- A `SessionStart` hook to inject a small amount of additional context whenever a session is started, resumed, or reset
- A small set of skills and prompts that shape Claude's behavior around:
  - planning and scoping
  - safe execution
  - concise status and diff reporting

It does *not* ship a giant library of framework-specific skills. You can add your own skills on top, and metaskills will help Claude use them more intelligently.

## When to use metaskills

metaskills is for you if:

- You like Claude Code as a coding CLI, but want more consistent planning and execution
- You already have your own workflows and stacks, and don't want to adopt someone else's methodology
- You want a small, composable layer that makes Claude "feel senior" without taking over your setup

## Status

This project is experimental. Expect rough edges and be ready to read the hooks and skills if something looks off.

Bug reports and PRs are welcome.

## License

MIT
