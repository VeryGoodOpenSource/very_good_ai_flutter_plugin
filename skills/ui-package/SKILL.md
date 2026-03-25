---
name: vgv-ui-package
description: Best practices for building a Flutter UI package on top of Material — custom components, ThemeExtension-based theming, consistent APIs, and widget tests. Use when user says "create a ui package". Supports app_ui_package template.
allowed-tools: Edit,mcp__very-good-cli__create
---

# UI Package

Best practices for creating a Flutter UI package — a reusable widget library that builds on top of `package:flutter/material.dart`, extending it with app-specific components, custom design tokens via `ThemeExtension`, and a consistent API surface.

> **Theming foundation:** This skill focuses on UI package structure, widget APIs, and testing. For foundational Material 3 theming (`ColorScheme`, `TextTheme`, component themes, spacing constants, light/dark mode), see the **Material Theming** skill (`/vgv-material-theming`). The two skills are complementary — Material Theming covers how to set up and use `ThemeData`; this skill covers how to extend it with `ThemeExtension` tokens and package reusable widgets around it.

## Core Standards

Apply these standards to ALL UI package work:

- **Build on Material** — depend on `flutter/material.dart` and compose Material widgets; do not rebuild primitives that Material already provides
- **One widget per file** — each public widget lives in its own file named after the widget in snake_case (e.g., `app_button.dart`)
- **Barrel file for public API** — expose all public widgets and theme classes through a single barrel file (e.g., `lib/my_ui.dart`) that also re-exports `material.dart`
- **Extend theming with `ThemeExtension`** — use Material's `ThemeData`, `ColorScheme`, and `TextTheme` as the base (see Material Theming skill); add app-specific tokens (spacing, custom colors) via `ThemeExtension<T>`
- **Every widget has a corresponding widget test** — behavioral tests verify interactions, callbacks, and state changes
- **Prefix all public classes** — use a consistent prefix (e.g., `App`, `Vg`) to avoid naming collisions with Material widgets
- **Use `const` constructors everywhere possible** — all widget constructors must be `const` when feasible
- **Document every public member** — every public class, constructor parameter, and method has a dartdoc comment

## Package Structure

```
my_ui/
├── lib/
│   ├── my_ui.dart              # Barrel file — re-exports material.dart + all public API
│   └── src/
│       ├── theme/
│       │   ├── app_theme.dart        # AppTheme class with light/dark ThemeData builders
│       │   ├── app_colors.dart       # AppColors ThemeExtension for custom color tokens
│       │   ├── app_spacing.dart      # AppSpacing ThemeExtension for spacing tokens
│       │   └── app_text_styles.dart  # Optional: extra text styles beyond Material's TextTheme
│       ├── widgets/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── app_card.dart
│       │   └── ...
│       └── extensions/
│           └── build_context_extensions.dart  # context.appColors, context.appSpacing shortcuts
├── test/
│   ├── src/
│   │   ├── theme/
│   │   │   └── app_theme_test.dart
│   │   └── widgets/
│   │       ├── app_button_test.dart
│   │       └── ...
│   └── helpers/
│       └── pump_app.dart         # Test helper wrapping widgets in MaterialApp + theme
├── widgetbook/                   # Widgetbook catalog submodule (sandbox + showcase)
│   └── ...
└── pubspec.yaml
```

## ThemeExtension Tokens

The base theme setup (`ThemeData`, `ColorScheme`, `TextTheme`, component themes, spacing constants) is covered by the **Material Theming** skill. This section covers the `ThemeExtension` layer unique to UI packages — custom tokens for values Material does not provide (e.g., success/warning/info colors, spacing scale as animatable values).

### Key Classes

| Class | Purpose |
| ----- | ------- |
| `AppColors extends ThemeExtension<AppColors>` | Custom color tokens beyond `ColorScheme` (success, warning, info + on-variants) |
| `AppSpacing extends ThemeExtension<AppSpacing>` | Spacing scale (xxs through xxlg) with `copyWith` and `lerp` |
| `AppTheme` | Composes `ThemeData` with `ColorScheme.fromSeed` + custom extensions, for light and dark variants |
| `AppThemeBuildContext` extension | Shorthand `context.appColors` and `context.appSpacing` |

Every `ThemeExtension` must implement `copyWith` and `lerp` for theme animation support.

## Building Widgets

### Widget API Guidelines

- Compose Material widgets — use `FilledButton`, `OutlinedButton`, `TextField`, `Card`, etc. as building blocks
- Accept only the minimum required parameters — avoid "kitchen sink" constructors
- Use named parameters for everything except `key` and `child`/`children`
- Provide sensible defaults derived from the theme when a parameter is not supplied
- Expose callbacks with `ValueChanged<T>` or `VoidCallback` — do not use raw `Function`
- Use `Widget?` for optional slot-based composition (leading, trailing icons, etc.)

## Testing

### Test Helper

Create a `pumpApp` helper that wraps widgets in a `MaterialApp` with the full theme:

```dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
  }) {
    return pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: widget),
      ),
    );
  }
}
```

### Test Patterns

- Test rendering: verify the widget shows the expected content
- Test interactions: verify callbacks fire on tap/input
- Test disabled state: verify callbacks do not fire when `onPressed` is `null`
- Test all variants: cover each enum value (variant, size, etc.)

## Barrel File

Re-export Material and the full public API through a single barrel file:

```dart
/// My UI — a custom Flutter widget library built on Material.
library;

export 'package:flutter/material.dart';

export 'src/extensions/build_context_extensions.dart';
export 'src/theme/app_colors.dart';
export 'src/theme/app_spacing.dart';
export 'src/theme/app_theme.dart';
export 'src/widgets/app_button.dart';
export 'src/widgets/app_card.dart';
export 'src/widgets/app_text_field.dart';
```

## Widgetbook Catalog

The UI package includes a `widgetbook/` submodule — a standalone Flutter app powered by Widgetbook that serves as both a **developer sandbox** for building widgets in isolation and a **showcase** for browsing every widget in the package. The submodule package name in `pubspec.yaml` is `widgetbook_catalog`.

### Catalog Structure

```
widgetbook/
├── lib/
│   ├── main.dart                # Entry point — runs WidgetbookApp
│   └── widgetbook/
│       ├── widgetbook.dart      # WidgetbookApp widget with addons
│       ├── widgetbook.directories.g.dart  # Generated — do not edit
│       ├── use_cases/
│       │   ├── app_button.dart  # Use cases for AppButton
│       │   ├── app_card.dart
│       │   └── ...              # One file per widget
│       └── widgets/
│           ├── widgets.dart     # Barrel file for catalog helpers
│           └── use_case_decorator.dart  # Wrapper for consistent presentation
├── pubspec.yaml                 # Package name: widgetbook_catalog
├── analysis_options.yaml
└── .gitignore
```

### Key Concepts

- **Use cases**: top-level functions annotated with `@widgetbook.UseCase(name:, type:)`, one file per widget in `use_cases/`
- **Use-case decorator**: a `UseCaseDecorator` widget that wraps every use case with a consistent background
- **Theme addon**: `ThemeAddon` wired to `AppTheme.light` and `AppTheme.dark` for switching themes in the catalog
- **Code generation**: Widgetbook uses `build_runner` to scan annotations and generate `widgetbook.directories.g.dart`

### Commands

| Command | Purpose |
| ------- | ------- |
| `cd widgetbook && dart run build_runner build --delete-conflicting-outputs` | Regenerate use-case directories after adding/modifying use cases |
| `cd widgetbook && flutter run -d chrome` | Run the catalog locally |

## Anti-Patterns

| Anti-Pattern | Correct Approach |
| ------------ | ---------------- |
| Rebuilding widgets Material already provides (e.g., custom button from `GestureDetector` + `DecoratedBox`) | Compose Material widgets (`FilledButton`, `OutlinedButton`) and style them |
| Creating a parallel theme system with custom `InheritedWidget` | Use Material's `ThemeData` as the base and `ThemeExtension` for custom tokens |
| Hardcoding `Color(0xFF...)` in widget code | Use `Theme.of(context).colorScheme` for standard colors and `context.appColors` for custom tokens |
| Duplicating Material's `ColorScheme` roles in a custom class | Only create `ThemeExtension` tokens for values Material does not cover (e.g., success, warning, info) |
| Using `dynamic` or `Object` for callback types | Use `VoidCallback`, `ValueChanged<T>`, or specific function typedefs |
| Exposing internal implementation files directly | Use a barrel file; keep all files under `src/` private |

## Common Workflows

### Adding a New Widget

1. Create `lib/src/widgets/app_<name>.dart` with a `const` constructor and documentation
2. Compose Material widgets internally; read custom tokens via `context.appColors` / `context.appSpacing`
3. Export the file from the barrel file (`lib/my_ui.dart`)
4. Create `test/src/widgets/app_<name>_test.dart` with widget tests
5. Add use cases in `widgetbook/lib/widgetbook/use_cases/app_<name>.dart` covering all variants
6. Re-run `dart run build_runner build --delete-conflicting-outputs` in `widgetbook/`

### Adding a New Custom Token

1. Add the token to the appropriate `ThemeExtension` class (`AppColors` or `AppSpacing`)
2. Update `copyWith` and `lerp` methods
3. Update `AppTheme.light` and `AppTheme.dark` to include the new token value
4. Update existing tests that construct the extension directly
5. Use the new token in widgets via the `BuildContext` extension

### Creating the Package

Use the Very Good CLI MCP tool to scaffold the package:

```
mcp__very-good-cli__create(template: "app_ui_package", name: "my_ui", description: "A custom Flutter UI package")
```
