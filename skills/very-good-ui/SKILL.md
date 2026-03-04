---
name: very-good-ui
description: Best practices for building a Flutter UI package on top of Material — custom components, ThemeExtension-based theming, consistent APIs, and widget tests.
---

# Very Good UI

Best practices for creating a Flutter UI package — a reusable widget library that builds on top of `package:flutter/material.dart`, extending it with app-specific components, custom design tokens via `ThemeExtension`, and a consistent API surface.

## Core Standards

Apply these standards to ALL UI package work:

- **Build on Material** — depend on `flutter/material.dart` and compose Material widgets; do not rebuild primitives that Material already provides
- **One widget per file** — each public widget lives in its own file named after the widget in snake_case (e.g., `app_button.dart`)
- **Barrel file for public API** — expose all public widgets and theme classes through a single barrel file (e.g., `lib/my_ui.dart`) that also re-exports `material.dart`
- **Extend theming with `ThemeExtension`** — use Material's `ThemeData`, `ColorScheme`, and `TextTheme` as the base; add app-specific tokens (spacing, custom colors) via `ThemeExtension<T>`
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

## Theming System

### Custom Color Tokens via ThemeExtension

Use `ThemeExtension` for colors that go beyond Material's `ColorScheme`:

```dart
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}
```

### Spacing Tokens via ThemeExtension

```dart
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xxs = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 24,
    this.xlg = 32,
    this.xxlg = 48,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xlg;
  final double xxlg;

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xlg,
    double? xxlg,
  }) {
    return AppSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xlg: xlg ?? this.xlg,
      xxlg: xxlg ?? this.xxlg,
    );
  }

  @override
  AppSpacing lerp(AppSpacing? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xxs: lerpDouble(xxs, other.xxs, t)!,
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xlg: lerpDouble(xlg, other.xlg, t)!,
      xxlg: lerpDouble(xxlg, other.xxlg, t)!,
    );
  }
}
```

### BuildContext Extensions

Provide shorthand access for custom tokens:

```dart
extension AppThemeBuildContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>()!;

  AppSpacing get appSpacing =>
      Theme.of(this).extension<AppSpacing>()!;
}
```

### AppTheme Class

Compose Material's `ThemeData` with custom extensions:

```dart
class AppTheme {
  static ThemeData get light {
    const appColors = AppColors(
      success: Color(0xFF16A34A),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFCA8A04),
      onWarning: Color(0xFFFFFFFF),
      info: Color(0xFF2563EB),
      onInfo: Color(0xFFFFFFFF),
    );

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
      ),
      extensions: const [
        appColors,
        AppSpacing(),
      ],
    );
  }

  static ThemeData get dark {
    const appColors = AppColors(
      success: Color(0xFF4ADE80),
      onSuccess: Color(0xFF1C1B1F),
      warning: Color(0xFFFACC15),
      onWarning: Color(0xFF1C1B1F),
      info: Color(0xFF60A5FA),
      onInfo: Color(0xFF1C1B1F),
    );

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.dark,
      ),
      extensions: const [
        appColors,
        AppSpacing(),
      ],
    );
  }
}
```

## Building Widgets

### Widget API Guidelines

- Compose Material widgets — use `FilledButton`, `OutlinedButton`, `TextField`, `Card`, etc. as building blocks
- Accept only the minimum required parameters — avoid "kitchen sink" constructors
- Use named parameters for everything except `key` and `child`/`children`
- Provide sensible defaults derived from the theme when a parameter is not supplied
- Expose callbacks with `ValueChanged<T>` or `VoidCallback` — do not use raw `Function`
- Use `Widget?` for optional slot-based composition (leading, trailing icons, etc.)

### Example Widget

```dart
/// A styled button from the UI package.
///
/// Wraps Material's [FilledButton] and [OutlinedButton] with app-specific
/// sizing and theming.
class AppButton extends StatelessWidget {
  /// Creates an [AppButton].
  const AppButton({
    required this.onPressed,
    required this.child,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    super.key,
  });

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The button's content, typically a [Text] widget.
  final Widget child;

  /// The visual variant of the button.
  final AppButtonVariant variant;

  /// The size of the button.
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    final padding = switch (size) {
      AppButtonSize.small => EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xxs,
        ),
      AppButtonSize.medium => EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.xs,
        ),
      AppButtonSize.large => EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.sm,
        ),
    };

    final style = ButtonStyle(
      padding: WidgetStatePropertyAll(padding),
    );

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
    };
  }
}

/// Visual variants for [AppButton].
enum AppButtonVariant { primary, secondary, outline }

/// Size variants for [AppButton].
enum AppButtonSize { small, medium, large }
```

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

### Widget Test

```dart
void main() {
  group('AppButton', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpApp(
        AppButton(
          onPressed: () {},
          child: const Text('Tap me'),
        ),
      );

      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        AppButton(
          onPressed: () => tapped = true,
          child: const Text('Tap me'),
        ),
      );

      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        AppButton(
          onPressed: null,
          child: const Text('Disabled'),
        ),
      );

      await tester.tap(find.byType(AppButton));
      expect(tapped, isFalse);
    });
  });
}
```

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

The UI package includes a `widgetbook/` submodule — a standalone Flutter app powered by [Widgetbook](https://pub.dev/packages/widgetbook) that serves as both a **developer sandbox** for building widgets in isolation and a **showcase** for browsing every widget in the package.

### Catalog Structure

```
my_ui/
├── lib/
│   └── ...                          # UI package source
├── widgetbook/                      # Catalog submodule
│   ├── lib/
│   │   ├── main.dart                # Entry point — runs WidgetbookApp
│   │   └── widgetbook/
│   │       ├── widgetbook.dart      # WidgetbookApp widget with addons
│   │       ├── widgetbook.directories.g.dart  # Generated — do not edit
│   │       ├── use_cases/
│   │       │   ├── app_button.dart  # Use cases for AppButton
│   │       │   ├── app_card.dart
│   │       │   └── ...              # One file per widget
│   │       └── widgets/
│   │           ├── widgets.dart     # Barrel file for catalog helpers
│   │           └── use_case_decorator.dart  # Wrapper for consistent presentation
│   ├── pubspec.yaml                 # Package name: widgetbook_catalog
│   ├── analysis_options.yaml
│   └── .gitignore
└── pubspec.yaml
```

### pubspec.yaml

The catalog depends on the UI package via a path reference and uses Widgetbook's annotation + code generation approach:

```yaml
name: widgetbook_catalog
description: "Widgetbook catalog for My UI"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.3 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  my_ui:
    path: ..
  widgetbook: ^3.7.0
  widgetbook_annotation: ^3.1.0

dev_dependencies:
  build_runner: ^2.4.7
  flutter_test:
    sdk: flutter
  very_good_analysis: ^7.0.0
  widgetbook_generator: ^3.7.0

flutter:
  uses-material-design: true
```

### Entry Point

```dart
import 'package:flutter/material.dart';
import 'package:widgetbook_catalog/widgetbook/widgetbook.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WidgetbookApp());
}
```

### WidgetbookApp

The root widget configures Widgetbook with theme addons and a use-case decorator:

```dart
import 'package:flutter/material.dart';
import 'package:my_ui/my_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_catalog/widgetbook/widgetbook.directories.g.dart';
import 'package:widgetbook_catalog/widgetbook/widgets/widgets.dart';

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      addons: [
        BuilderAddon(
          name: 'Decorator',
          builder: (context, child) {
            return UseCaseDecorator(child: child);
          },
        ),
        ThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: AppTheme.light),
            WidgetbookTheme(name: 'Dark', data: AppTheme.dark),
          ],
          themeBuilder: (context, theme, child) {
            return Theme(
              data: theme,
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium ?? const TextStyle(),
                child: child,
              ),
            );
          },
        ),
      ],
    );
  }
}
```

### Use-Case Decorator

A wrapper widget that provides a consistent background for all use cases:

```dart
class UseCaseDecorator extends StatelessWidget {
  const UseCaseDecorator({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: SizedBox.expand(child: Material(child: child)),
    );
  }
}
```

### Writing Use Cases

Each widget gets a dedicated file in `use_cases/` with one or more `@widgetbook.UseCase` annotations. Each use case is a top-level function that returns a `Widget`:

```dart
import 'package:flutter/material.dart';
import 'package:my_ui/my_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'primary', type: AppButton)
Widget primary(BuildContext context) => Center(
      child: AppButton(
        onPressed: () {},
        child: const Text('Primary'),
      ),
    );

@widgetbook.UseCase(name: 'secondary', type: AppButton)
Widget secondary(BuildContext context) => Center(
      child: AppButton(
        onPressed: () {},
        variant: AppButtonVariant.secondary,
        child: const Text('Secondary'),
      ),
    );

@widgetbook.UseCase(name: 'outline', type: AppButton)
Widget outline(BuildContext context) => Center(
      child: AppButton(
        onPressed: () {},
        variant: AppButtonVariant.outline,
        child: const Text('Outline'),
      ),
    );

@widgetbook.UseCase(name: 'disabled', type: AppButton)
Widget disabled(BuildContext context) => const Center(
      child: AppButton(
        onPressed: null,
        child: Text('Disabled'),
      ),
    );

@widgetbook.UseCase(name: 'all sizes', type: AppButton)
Widget allSizes(BuildContext context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final size in AppButtonSize.values)
            AppButton(
              onPressed: () {},
              size: size,
              child: Text(size.name),
            ),
        ],
      ),
    );
```

### Code Generation

Widgetbook uses `build_runner` to scan `@widgetbook.UseCase` annotations and generate the `widgetbook.directories.g.dart` file. Run the generator after adding or modifying use cases:

```bash
cd widgetbook && dart run build_runner build --delete-conflicting-outputs
```

### Running the Catalog

```bash
cd widgetbook && flutter run -d chrome
```

## Anti-Patterns

| Anti-Pattern | Correct Approach |
| ------------ | ---------------- |
| Rebuilding widgets Material already provides (e.g., custom button from `GestureDetector` + `DecoratedBox`) | Compose Material widgets (`FilledButton`, `OutlinedButton`) and style them |
| Creating a parallel theme system with custom `InheritedWidget` | Use Material's `ThemeData` as the base and `ThemeExtension` for custom tokens |
| Hardcoding `Color(0xFF...)` in widget code | Use `Theme.of(context).colorScheme` for standard colors and `context.appColors` for custom tokens |
| Duplicating Material's `ColorScheme` roles in a custom class | Only create `ThemeExtension` tokens for values Material doesn't cover (e.g., success, warning, info) |
| Using `dynamic` or `Object` for callback types | Use `VoidCallback`, `ValueChanged<T>`, or specific function typedefs |
| Exposing internal implementation files directly | Use a barrel file; keep all files under `src/` private |

## Common Workflows

### Adding a New Widget

1. Create `lib/src/widgets/app_<name>.dart` with a `const` constructor and dartdoc
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

Use Very Good CLI to scaffold the package:

```bash
very_good create flutter_package my_ui --description "A custom Flutter UI package"
```
