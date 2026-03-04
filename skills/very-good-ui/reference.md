# Very Good UI — Reference

Complete code examples for the Very Good UI skill: theming, widgets, testing, and Widgetbook catalog setup.

---

## ThemeExtension: AppColors

Custom color tokens for values beyond Material's `ColorScheme`:

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

---

## ThemeExtension: AppSpacing

Spacing scale with consistent token names:

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

---

## BuildContext Extensions

Shorthand access for custom tokens:

```dart
extension AppThemeBuildContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>()!;

  AppSpacing get appSpacing =>
      Theme.of(this).extension<AppSpacing>()!;
}
```

---

## AppTheme Class

Composes Material's `ThemeData` with custom extensions for light and dark variants:

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

---

## Example Widget: AppButton

A styled button composing Material's `FilledButton` and `OutlinedButton`:

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

---

## Widget Test Example

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

---

## Widgetbook Catalog

### pubspec.yaml

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

### UseCaseDecorator

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

### Use-Case Example

Each widget gets a dedicated file in `use_cases/` with one or more `@widgetbook.UseCase` annotations:

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
