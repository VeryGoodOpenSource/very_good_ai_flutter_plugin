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
| **Very Good CLI** | Project scaffolding with `very_good_cli` — templates, flavors, architecture patterns, 100% coverage targets, and `very_good_analysis` linting |
| **Testing** | Unit, widget, and golden testing — `mocktail` mocking, `pumpApp` helpers, test structure & naming, coverage patterns, and `dart_test.yaml` configuration |
| **Navigation** | GoRouter routing — `@TypedGoRoute` type-safe routes, deep linking, redirects, shell routes, and widget testing with `MockGoRouter` |
| **Internationalization** | i18n/l10n — ARB files, `context.l10n` patterns, pluralization, RTL/LTR support with directional widgets, and backend localization strategies |
| **Material Theming** | Material 3 theming — `ColorScheme`, `TextTheme`, component themes, spacing systems, and light/dark mode support |
| **Bloc** | State management with Bloc/Cubit — sealed events & states, `BlocProvider`/`BlocBuilder` widgets, event transformers, and testing with `blocTest()` & `mocktail` |
| **Riverpod** | Reactive state management & DI — `@riverpod` code-gen providers, `AsyncValue` handling, `Notifier`/`AsyncNotifier`, family providers, and `ProviderContainer` testing |

## Usage

Skills activate automatically when Claude detects relevant context in your conversation. Simply ask Claude to help with a Flutter or Dart task, and the appropriate skill's guidance will be applied.

For example:

> **You:** Create a new Bloc for user authentication with login and logout events.
>
> **Claude:** _(applies the Bloc skill — uses sealed classes for events and states, follows the Page/View separation pattern, generates `blocTest()` tests with `mocktail` mocks, and follows VGV naming conventions)_

You can also invoke skills directly as slash commands:

```bash
/bloc
/riverpod
/testing
/navigation
/internationalization
/material-theming
/very-good-cli
```

## What Each Skill Provides

Every skill includes:

- **Non-negotiable standards** — enforced conventions (e.g., `mocktail` over `mockito`, sealed classes for Bloc events)
- **Architecture patterns** — folder structures and layered architecture guidance
- **Code examples** — ready-to-adapt snippets following best practices
- **Testing strategies** — unit, widget, and integration testing patterns
- **Common workflows** — step-by-step guides for tasks like "adding a new feature" or "adding a new route"
- **Anti-patterns** — what to avoid and why

[claude_code_link]: https://claude.ai/code
[vgv_link]: https://verygood.ventures
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only