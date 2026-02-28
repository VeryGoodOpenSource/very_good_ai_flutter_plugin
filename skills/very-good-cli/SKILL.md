---
name: very-good-cli
description: Best practices for using the Very Good CLI. Use when scaffolding projects with very_good_cli, working with VGV templates, configuring very_good_analysis, or running very_good test commands.
---

# Very Good CLI

Command-line tool for VGV-standard Flutter/Dart projects. Install: `dart pub global activate very_good_cli`

---

## Standards (Non-Negotiable)

These constraints apply to ALL work — no exceptions:

- **100% test coverage** — always use `--min-coverage 100`
- **Very Good Analysis** — add `very_good_analysis` to `dev_dependencies` and include in `analysis_options.yaml`
- **Zero analysis issues** — `dart analyze --fatal-infos --fatal-warnings` must pass
- **Formatted code** — `dart format --set-exit-if-changed .` must pass
- **Conventional Commits** — `type(scope): description` (e.g., `feat(auth): add login page`)
- **Null safety** — always enabled
- **Dart SDK** — `^3.11.0`

---

## Template Selection

**Choose the right template:**

| Building…                       | Template           | Command                                          |
| ------------------------------- | ------------------ | ------------------------------------------------ |
| Full Flutter application        | `flutter_app`      | `very_good create flutter_app my_app`            |
| Dart command-line tool           | `dart_cli`         | `very_good create dart_cli my_cli`               |
| Pure Dart library                | `dart_package`     | `very_good create dart_package my_package`        |
| Flutter widget/theme library     | `flutter_package`  | `very_good create flutter_package my_package`     |
| Flutter federated plugin         | `flutter_plugin`   | `very_good create flutter_plugin my_plugin`       |
| Game with Flame engine           | `flame_game`       | `very_good create flame_game my_game`             |
| Documentation website            | `docs_site`        | `very_good create docs_site my_docs`              |

**Common `create` flags:**

| Flag                  | Purpose                                      |
| --------------------- | -------------------------------------------- |
| `--org-name`          | Reverse-domain org (e.g., `com.example`)     |
| `--description`       | Package/project description                  |
| `--publishable`       | Include publishing config in `pubspec.yaml`  |
| `--application-id`    | Custom app ID (Flutter apps)                 |

---

## Template Deep Dives

### flutter_app

**Architecture:** Flavored, feature-first Flutter app with Bloc/Cubit state management.

**Flavors:** Three environments with separate entrypoints:

| Flavor        | Entrypoint                        | Run command                                              |
| ------------- | --------------------------------- | -------------------------------------------------------- |
| development   | `lib/main_development.dart`       | `flutter run --flavor development -t lib/main_development.dart` |
| staging       | `lib/main_staging.dart`           | `flutter run --flavor staging -t lib/main_staging.dart`         |
| production    | `lib/main_production.dart`        | `flutter run --flavor production -t lib/main_production.dart`   |

**Structure — folder-by-feature:**

```
lib/
├── app/
│   ├── app.dart                  # App widget, router, theme
│   └── view/
│       └── app.dart
├── counter/                      # Feature folder
│   ├── counter.dart              # Barrel file
│   ├── cubit/
│   │   ├── counter_cubit.dart
│   │   └── counter_state.dart
│   └── view/
│       ├── counter_page.dart     # Page (provides cubit)
│       └── counter_view.dart     # View (reads cubit, builds UI)
├── l10n/
│   ├── arb/
│   │   ├── app_en.arb
│   │   └── app_es.arb
│   └── l10n.dart
├── main_development.dart
├── main_staging.dart
└── main_production.dart
```

**Key patterns:**

- **Page/View split:** Page creates/provides the Cubit via `BlocProvider`. View consumes it via `BlocBuilder`/`BlocListener`. Never create a Cubit inside a View.
- **State management:** Use `Cubit` for simple state, `Bloc` for event-driven logic. Business logic lives in cubits/blocs, never in widgets.
- **Barrel exports:** Each feature has a barrel file (`counter.dart`) exporting its public API.
- **Localization:** ARB-based. Add strings to `app_en.arb`, run `flutter gen-l10n`. Access via `context.l10n.stringKey`.

### dart_cli

**Architecture:** Command-runner pattern for structured CLI tools.

**Structure:**

```
bin/
└── my_cli.dart                   # Executable entrypoint
lib/
├── src/
│   ├── commands/
│   │   ├── sample_command.dart   # Individual commands
│   │   └── update_command.dart
│   └── command_runner.dart       # CommandRunner subclass
└── my_cli.dart                   # Barrel export
```

**Key patterns:**

- Entrypoint in `bin/` calls `CommandRunner.run(args)`
  - Keep the contents of your entrypoint (e.g. `bin/my_cli.dart`) minimal to improve testability and reduce amount of logic here.
- Each command extends `Command` from `package:args`
- `CommandRunner` registers all commands and handles global flags
- Use `package:mason_logger` for styled output (progress, prompts, alerts)

### dart_package

**Architecture:** Pure Dart library with clean public API.

**Structure:**

```
lib/
├── src/
│   ├── models/
│   │   └── my_model.dart         # Implementation details
│   └── my_package.dart           # Internal classes
└── my_package.dart               # Barrel export — only public API
test/
└── src/
    ├── models/
    │   └── my_model_test.dart
    └── my_package_test.dart
```

**Key patterns:**

- `lib/src/` contains all implementation — never import `src/` directly from outside the package
- `lib/my_package.dart` barrel file exports only the public API
- Use `--publishable` flag when creating packages intended for pub.dev
- Mirror `lib/` structure under `test/` exactly

### flutter_package

**Architecture:** Reusable Flutter widget/theme library.

**Structure:**

```
lib/
├── src/
│   ├── widgets/
│   │   └── my_widget.dart
│   └── theme/
│       └── my_theme.dart
└── my_package.dart               # Barrel export
test/
└── src/
    └── widgets/
        └── my_widget_test.dart
```

**Key patterns:**

- Organize by widget category (buttons, inputs, layouts) or by theme
- Barrel file exports only public widgets and theme data
- Every widget must have corresponding widget tests
- Use `--publishable` for pub.dev distribution

### flutter_plugin

**Architecture:** Federated plugin with platform interface and platform-specific implementations.

**Structure:**

```
my_plugin/                        # App-facing package
├── lib/
│   └── my_plugin.dart
my_plugin_platform_interface/     # Platform interface (abstract)
├── lib/
│   ├── src/
│   │   └── method_channel_my_plugin.dart
│   └── my_plugin_platform_interface.dart
my_plugin_android/                # Android implementation
my_plugin_ios/                    # iOS implementation
my_plugin_linux/                  # Linux implementation
my_plugin_macos/                  # macOS implementation
my_plugin_web/                    # Web implementation
my_plugin_windows/                # Windows implementation
```

**Key patterns:**

- Federated architecture: platform interface defines the contract, each platform implements it
- App-facing package delegates to platform interface
- Use method channels or FFI for platform communication
- Specify platforms at creation: `very_good create flutter_plugin my_plugin --platforms android,ios,web`

### flame_game

**Architecture:** Flame engine game with component hierarchy.

**Structure:**

```
lib/
├── game/
│   ├── game.dart                 # FlameGame subclass
│   ├── components/
│   │   ├── player.dart
│   │   └── enemy.dart
│   └── view/
│       └── game_page.dart        # GameWidget wrapper
├── main_development.dart
├── main_staging.dart
└── main_production.dart
assets/
└── images/
```

**Key patterns:**

- Extends `FlameGame` — game loop managed by Flame
- Components extend `Component` or `PositionComponent`
- Uses same flavor system as `flutter_app` (development/staging/production)
- Assets go in `assets/` directory, registered in `pubspec.yaml`

### docs_site

**Architecture:** Docusaurus-powered documentation site.

**Structure:**

```
docs/
├── intro.md
├── getting-started.md
└── api/
src/
├── components/
└── pages/
docusaurus.config.js
sidebars.js
package.json
```

**Key patterns:**

- Markdown files in `docs/` for content
- `docusaurus.config.js` for site configuration (title, URL, navbar, footer)
- `sidebars.js` controls navigation structure
- Run locally: `npm start` | Build: `npm run build`

---

## Testing

**Commands:**

```bash
# Single package
very_good test --coverage --min-coverage 100

# Monorepo — all packages recursively
very_good test -r --coverage --min-coverage 100

# Fail fast (stop on first failure)
very_good test -r --coverage --min-coverage 100 --fail-fast

# Platform-specific tests
flutter test --platform chrome    # Web
flutter test --platform windows   # Windows
```

**Key flags:**

| Flag                       | Purpose                                    |
| -------------------------- | ------------------------------------------ |
| `--coverage`               | Generate coverage data                     |
| `--min-coverage 100`       | Enforce 100% line coverage                 |
| `-r` / `--recursive`      | Test all packages in monorepo              |
| `--fail-fast`              | Stop at first failure                      |
| `--test-randomize-ordering-seed random` | Randomize test order          |
| `--update-goldens`         | Update golden image files                  |

**Testing rules:**

- Use `blocTest` from `package:bloc_test` for testing Cubits and Blocs
- Use `package:mocktail` for mocking — never `package:mockito`
- Mirror `lib/` directory structure exactly under `test/`
- Every public method, widget, and state transition must be tested
- Group related tests with `group()`, use descriptive test names
- Use `setUp` and `tearDown` for shared fixtures
- Widget tests: use `pumpApp` helper to wrap with required providers

---

## Packages

```bash
# Get dependencies for a single package
very_good packages get

# Get dependencies recursively (monorepo)
very_good packages get -r
```

**License auditing:**

```bash
# Check licenses against allowed list
very_good packages check licenses --allowed=MIT,BSD-3-Clause,BSD-2-Clause,Apache-2.0
```

Always audit licenses before adding new dependencies. Allowed licenses: **MIT**, **BSD-3-Clause**, **BSD-2-Clause**, **Apache-2.0**.

---

## Code Quality Checklist

Run these in order before declaring any task complete:

1. **Format** — `dart format --set-exit-if-changed .`
2. **Analyze** — `dart analyze --fatal-infos --fatal-warnings`
3. **Test** — `very_good test --coverage --min-coverage 100`
4. **No unjustified ignores** — every `// ignore:` must have a comment explaining why
5. **Public API docs** — all public classes, methods, and properties have `///` dartdoc comments
6. **Conventional Commits** — `type(scope): description`

---

## Configuration Reference

### analysis_options.yaml

```yaml
include: package:very_good_analysis/analysis_options.yaml
```

Add project-specific rules only when necessary. Very Good Analysis provides the full rule set.

### dart_test.yaml

```yaml
tags:
  presubmit:
  ci:
```

### pubspec.yaml (minimum expected fields)

```yaml
name: my_package
description: A Very Good package.
version: 0.1.0+1
publish_to: none                  # Remove for publishable packages

environment:
  sdk: ^3.11.0

dev_dependencies:
  very_good_analysis: ^7.0.0
```

---

## Common Workflows

### Adding a new feature to a flutter_app

1. Create feature directory: `lib/<feature_name>/`
2. Add barrel file: `lib/<feature_name>/<feature_name>.dart`
3. Create cubit: `lib/<feature_name>/cubit/<feature_name>_cubit.dart` and state file
4. Create page: `lib/<feature_name>/view/<feature_name>_page.dart` — provides cubit via `BlocProvider`
5. Create view: `lib/<feature_name>/view/<feature_name>_view.dart` — builds UI from cubit state
6. Add localization strings to `app_en.arb`, run `flutter gen-l10n`
7. Wire page into the app's router
8. Create matching test structure under `test/<feature_name>/`
9. Run quality checklist

### Creating a new package in a monorepo

1. `very_good create dart_package packages/<package_name>` (or `flutter_package`)
2. Add `very_good_analysis` to `dev_dependencies`
3. Set `analysis_options.yaml` to include Very Good Analysis
4. Implement feature in `lib/src/`, export via barrel file
5. Write tests mirroring `lib/` structure
6. Run `very_good packages get -r` from monorepo root
7. Run quality checklist

### Adding a dependency

1. `dart pub add <package>` (or `flutter pub add <package>`)
2. Run license check: `very_good packages check licenses --allowed=MIT,BSD-3-Clause,BSD-2-Clause,Apache-2.0`
3. If license is not in the allowed list, find an alternative or get explicit approval
4. Run `very_good test --coverage --min-coverage 100` to verify nothing breaks
