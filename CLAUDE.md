# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Very Good AI Flutter Plugin is a Claude Code plugin that provides best-practices skills for Flutter and Dart development. It is a **documentation-only repository** — there is no Dart/Flutter source code, no `pubspec.yaml`, and no tests. All value lives in the markdown skill files.

## Repository Structure

```
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, tags)
hooks/
  hooks.json           # PostToolUse hook definitions (analyze, format)
  scripts/
    analyze.sh         # Runs dart analyze on modified .dart files
    format.sh          # Runs dart format on modified .dart files
skills/
  bloc/SKILL.md
  bloc/reference.md
  internationalization/SKILL.md
  material-theming/SKILL.md
  navigation/SKILL.md
  riverpod/SKILL.md
  riverpod/reference.md
  testing/SKILL.md
  testing/reference.md
  very-good-cli/SKILL.md
```

## Skill File Format

Every `SKILL.md` follows this structure:

1. **YAML frontmatter** — `name` (lowercase letters, numbers, and hyphens only) and `description` fields
2. **H1 title** — human-readable skill name
3. **Standards (Non-Negotiable)** — enforced constraints, always first
4. **Content sections** — architecture, code examples, workflows, anti-patterns

## Writing Conventions

- Frame standards as non-negotiable — no soft language ("consider", "prefer")
- Use fenced code blocks with language identifiers for all examples
- Provide complete, copy-pasteable snippets, not fragments
- Reference packages by full name (e.g., `package:mocktail`)
- Include anti-patterns alongside correct patterns when helpful

## Adding a New Skill

1. Create `skills/<skill_name>/SKILL.md` following the format above
2. Update tags in `.claude-plugin/plugin.json`
3. Update the skills table in `README.md`

## Hooks

The `hooks/` directory contains PostToolUse hooks that run automatically after `Edit` or `Write` tool calls:

- `hooks.json` declares the hook definitions with an `Edit|Write` matcher
- `analyze.sh` — runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix the issue)
- `format.sh` — runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking)

Both scripts require **jq** to parse the hook payload (they skip gracefully if `jq` is not installed).

## Commits

Use conventional commits: `type(scope): description`

Examples: `feat: add bloc skill`, `chore: add logo to README`
