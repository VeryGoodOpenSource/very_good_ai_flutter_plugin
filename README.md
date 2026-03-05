# Very Good AI Flutter Plugin

[![Very Good Ventures][logo_white]][very_good_ventures_link_dark]
[![Very Good Ventures][logo_black]][very_good_ventures_link_light]

A [Claude Code][claude_code_link] plugin that accelerates Flutter & Dart development with best-practices skills from [Very Good Ventures][vgv_link].

Developed with 💙 by [Very Good Ventures][vgv_link] 🦄

## Overview

Very Good AI Flutter Plugin is a collection of contextual best-practices skills that Claude uses when helping you write Flutter and Dart code. Each skill provides opinionated, production-quality guidance covering architecture patterns, naming conventions, folder structures, code examples, testing strategies, and anti-patterns to avoid, so you get code that follows [VGV standards][vgv_link] out of the box.

## Skills

| Skill | Description |
| ----- | ----------- |
| **Accessibility** | WCAG 2.1 AA compliance — semantics, screen reader support, touch targets, focus management, color contrast, text scaling, and motion sensitivity |
| **Testing** | Unit, widget, and golden testing — `mocktail` mocking, `pumpApp` helpers, test structure & naming, coverage patterns, and `dart_test.yaml` configuration |
| **Navigation** | GoRouter routing — `@TypedGoRoute` type-safe routes, deep linking, redirects, shell routes, and widget testing with `MockGoRouter` |
| **Internationalization** | i18n/l10n — ARB files, `context.l10n` patterns, pluralization, RTL/LTR support with directional widgets, and backend localization strategies |
| **Material Theming** | Material 3 theming — `ColorScheme`, `TextTheme`, component themes, spacing systems, and light/dark mode support |
| **Bloc** | State management with Bloc/Cubit — sealed events & states, `BlocProvider`/`BlocBuilder` widgets, event transformers, and testing with `blocTest()` & `mocktail` |
| **Layered Architecture** | VGV layered architecture — four-layer package structure (Data, Repository, Business Logic, Presentation), dependency rules, data flow, and bootstrap wiring |
| **Security** | Flutter-specific static security review — secrets management, `flutter_secure_storage`, certificate pinning, `Random.secure()`, `formz` validation, dependency vulnerability scanning with `osv-scanner`, and OWASP Mobile Top 10 guidance |

## Hooks

This plugin includes PostToolUse hooks that automatically run Dart analysis and formatting on `.dart` files after every `Edit` or `Write` tool call.

| Hook | Behavior |
| ---- | -------- |
| **Analyze** | Runs `dart analyze` on the modified file; exits 2 on failure (blocking — Claude must fix issues before continuing) |
| **Format** | Runs `dart format` on the modified file; always exits 0 (non-blocking — formatting is applied silently) |

### Prerequisites

- **Dart SDK** — must be available on your `PATH`
- **jq** — used to parse the hook payload; hooks are skipped gracefully if `jq` is not installed

## Usage

Skills activate automatically when Claude detects relevant context in your conversation. Simply ask Claude to help with a Flutter or Dart task, and the appropriate skill's guidance will be applied.

For example:

> **You:** Create a new Bloc for user authentication with login and logout events.
>
> **Claude:** _(applies the Bloc skill — uses sealed classes for events and states, follows the Page/View separation pattern, generates `blocTest()` tests with `mocktail` mocks, and follows VGV naming conventions)_

You can also invoke skills directly as slash commands:

```bash
/vgv-accessibility
/vgv-bloc
/vgv-internationalization
/vgv-layered-architecture
/vgv-material-theming
/vgv-navigation
/vgv-static-security
/vgv-testing
```

## What Each Skill Provides

Every skill includes:

- **Core Standards** — recommended conventions (e.g., `mocktail` over `mockito`, sealed classes for Bloc events)
- **Architecture patterns** — folder structures and layered architecture guidance
- **Code examples** — ready-to-adapt snippets following best practices
- **Testing strategies** — unit, widget, and integration testing patterns
- **Common workflows** — step-by-step guides for tasks like "adding a new feature" or "adding a new route"
- **Anti-patterns** — what to avoid and why

## MCP Integration

This plugin includes a `.mcp.json` configuration that connects Claude Code to the Very Good CLI's built-in MCP server. This gives Claude the ability to execute CLI commands directly, complementing the skills which provide architectural guidance and best practices.

**Available MCP tools:**

| Tool | What it does |
| ---- | ------------ |
| `create` | Scaffold projects from templates (`flutter_app`, `dart_cli`, `dart_package`, `flutter_package`, `flutter_plugin`, `flame_game`, `docs_site`) |
| `tests` | Run tests with coverage enforcement |
| `packages_check_licenses` | Audit dependency licenses against an allowed list |
| `packages_get` | Get dependencies for a single package or recursively across a monorepo |

**Prerequisites:**

- Very Good CLI v1.0+ installed: `dart pub global activate very_good_cli`
- `very_good` must be on your PATH

**How it works:**

The `.mcp.json` file at the project root registers a `very-good-cli` MCP server using stdio transport. When Claude Code detects this configuration, it connects to the Very Good CLI MCP server and gains access to the tools above. The skills continue to provide knowledge and best practices while the MCP tools handle execution.

[claude_code_link]: https://claude.ai/code
[vgv_link]: https://verygood.ventures
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only