# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Very Good Skills is a Claude Code plugin that provides best-practices skills for Flutter and Dart development. It is a **documentation-only repository** — there is no Dart/Flutter source code, no `pubspec.yaml`, and no tests. All value lives in the markdown skill files.

## Repository Structure

```
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, tags)
  marketplace.json     # Marketplace registry entry
plugins/very_good_skills/
  bloc/SKILL.md
  internationalization/SKILL.md
  material_theming/SKILL.md
  navigation/SKILL.md
  riverpod/SKILL.md
  testing/SKILL.md
  very_good_cli/SKILL.md
```

## Skill File Format

Every `SKILL.md` follows this structure:

1. **YAML frontmatter** — `name` (lowercase_snake) and `description` fields
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

1. Create `plugins/very_good_skills/<skill_name>/SKILL.md` following the format above
2. Update tags in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
3. Update the skills table in `README.md`

## Commits

Use conventional commits: `type(scope): description`

Examples: `feat: add bloc skill`, `chore: add logo to README`
