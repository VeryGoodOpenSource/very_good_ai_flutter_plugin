---
name: material_theming
description: Best practices for Flutter theming using Material 3, including ColorScheme, TextTheme, component themes, spacing systems, and light/dark theme support.
---

# Theming

Material 3 theming best practices for Flutter applications using `ThemeData` as the single source of truth for colors, typography, component styles, and spacing.

## Standards (Non-Negotiable)

These constraints apply to ALL theming work — no exceptions:

- **Use `ThemeData` as the single source of truth** — never inline colors or text styles in widgets
- **Reference colors via `Theme.of(context).colorScheme`** — never `Colors.blue`, `Colors.red`, or any hardcoded `Color` values
- **Reference text styles via `Theme.of(context).textTheme`** — never inline `TextStyle(...)` in widget code
- **Use `ColorScheme` for all color definitions** — Material 3's structured color system
- **Centralize component themes in `ThemeData`** — define `FilledButtonThemeData`, `InputDecorationTheme`, etc. in the theme, not per-widget
- **Define a spacing system with a base unit** — no arbitrary pixel values for padding, margins, or gaps
- **Support light and dark themes from the start** — use `ThemeData` so theme switching requires zero conditional logic in widgets
- **Avoid conditional logic for theming in UI** — never check brightness in widget code; let `ThemeData` handle it
- **Prefer `EdgeInsets.only` and `EdgeInsets.symmetric`** — never `EdgeInsets.fromLTRB` (positional arguments are error-prone)

## Color System

### Custom Colors Class

Centralize all color definitions in a dedicated class:

```dart
abstract class AppColors {
  static const primaryColor = Color(0xFF4F46E5);
  static const secondaryColor = Color(0xFF9C27B0);
  static const errorColor = Color(0xFFDC2626);
  static const surfaceColor = Color(0xFFFAFAFA);
}
```

### `ColorScheme` Configuration

The `ColorScheme` class includes 45 colors based on Material 3 specifications. Configure it within `ThemeData`:

```dart
ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryColor,
    secondary: AppColors.secondaryColor,
    error: AppColors.errorColor,
    surface: AppColors.surfaceColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onError: Colors.white,
    onSurface: Colors.black,
  ),
)
```

For quick prototyping, use `ColorScheme.fromSeed()`:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
  ),
)
```

### Light and Dark Theme Variants

```dart
class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryColor,
      surface: AppColors.surfaceColor,
      // ... remaining color roles
    ),
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryColorDark,
      surface: AppColors.surfaceColorDark,
      // ... remaining color roles
    ),
  );
}
```

### Accessing Colors

```dart
@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return ColoredBox(
    color: colorScheme.surface,
    child: Text(
      'Hello',
      style: TextStyle(color: colorScheme.onSurface),
    ),
  );
}
```

## Typography

### Font Asset Organization

Store fonts in `assets/fonts/` and declare them in `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

Use `flutter_gen` to generate type-safe font family constants:

```dart
class FontFamily {
  static const String inter = 'Inter';
}
```

### Custom Text Styles Class

Centralize text style definitions for consistent updates:

```dart
abstract class AppTextStyle {
  static const _baseStyle = TextStyle(
    fontFamily: FontFamily.inter,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle displayLarge = _baseStyle.copyWith(
    fontSize: 57,
    height: 1.12,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle headlineMedium = _baseStyle.copyWith(
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle titleLarge = _baseStyle.copyWith(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle bodyLarge = _baseStyle.copyWith(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle labelLarge = _baseStyle.copyWith(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
  );
}
```

### `TextTheme` Integration

Integrate custom styles into `ThemeData.textTheme`:

```dart
ThemeData(
  textTheme: TextTheme(
    displayLarge: AppTextStyle.displayLarge,
    headlineMedium: AppTextStyle.headlineMedium,
    titleLarge: AppTextStyle.titleLarge,
    bodyLarge: AppTextStyle.bodyLarge,
    labelLarge: AppTextStyle.labelLarge,
  ),
)
```

### Accessing Text Styles

```dart
@override
Widget build(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

  return Text(
    'Hello',
    style: textTheme.headlineMedium,
  );
}
```

## Component Themes

Material components use `colorScheme` and `textTheme` by default, but each widget has a customizable theme. Define component themes centrally in `ThemeData` instead of styling individual widget instances.

### FilledButton

```dart
ThemeData(
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(72, 48),
      textStyle: AppTextStyle.labelLarge,
    ),
  ),
)
```

### InputDecoration

```dart
ThemeData(
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  ),
)
```

### AppBar

```dart
ThemeData(
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    titleTextStyle: AppTextStyle.titleLarge,
  ),
)
```

## Spacing System

Define a spacing system using a base unit to ensure consistency and avoid hardcoded values:

```dart
abstract class AppSpacing {
  static const double spaceUnit = 16;

  /// 4px
  static const double xxs = 0.25 * spaceUnit;

  /// 6px
  static const double xs = 0.375 * spaceUnit;

  /// 8px
  static const double sm = 0.5 * spaceUnit;

  /// 12px
  static const double md = 0.75 * spaceUnit;

  /// 16px
  static const double lg = spaceUnit;

  /// 24px
  static const double xlg = 1.5 * spaceUnit;

  /// 32px
  static const double xxlg = 2 * spaceUnit;
}
```

### Applying Spacing

```dart
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  ),
  child: Column(
    spacing: AppSpacing.sm,
    children: [
      // widgets
    ],
  ),
)
```

## EdgeInsets Preferences

### Prefer `EdgeInsets.only` (Named Parameters)

```dart
// Preferred — clear which side each value applies to
EdgeInsets.only(top: 16, bottom: 8)
```

### Prefer `EdgeInsets.symmetric`

```dart
// Preferred — concise when horizontal or vertical values match
EdgeInsets.symmetric(horizontal: 16, vertical: 8)
```

### Avoid `EdgeInsets.fromLTRB`

```dart
// Avoid — positional arguments make it easy to mix up sides
EdgeInsets.fromLTRB(16, 8, 16, 8)
```

## Complete Theme Example

```dart
class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      error: AppColors.errorColor,
      surface: AppColors.surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: Colors.black,
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: AppTextStyle.displayLarge,
        headlineMedium: AppTextStyle.headlineMedium,
        titleLarge: AppTextStyle.titleLarge,
        bodyLarge: AppTextStyle.bodyLarge,
        labelLarge: AppTextStyle.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, 48),
          textStyle: AppTextStyle.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        titleTextStyle: AppTextStyle.titleLarge,
      ),
    );
  }
}
```

### Using the Theme

```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: const HomePage(),
)
```

### Accessing Theme Properties in Widgets

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return ColoredBox(
    color: colorScheme.surface,
    child: Text('Good', style: textTheme.bodyLarge),
  );
}
```

## Common Patterns

### Creating a Theme

1. Define `AppColors` with all color constants
2. Define `AppTextStyle` with all text style constants
3. Define `AppSpacing` with spacing scale based on a base unit
4. Create `AppTheme` class with `light` and `dark` getters
5. Configure `ColorScheme`, `TextTheme`, and component themes in each `ThemeData`
6. Pass `AppTheme.light` and `AppTheme.dark` to `MaterialApp`

### Adding a New Color Token

1. Add the color constant to `AppColors`
2. Map it to the appropriate `ColorScheme` role (or create a theme extension for custom tokens)
3. Reference it via `Theme.of(context).colorScheme.<role>` in widgets

### Dark Mode Support

1. Create separate `ColorScheme` instances for light and dark
2. Use the same `TextTheme` and component themes (they adapt automatically via `colorScheme`)
3. Pass both themes to `MaterialApp` via `theme` and `darkTheme`
4. Never check `Brightness` in widget code — let `ThemeData` handle the switch

## Quick Reference

| ThemeData Property        | Purpose                                      |
| ------------------------- | -------------------------------------------- |
| `colorScheme`             | Material 3 color system (45 color roles)     |
| `textTheme`               | Typography scale (display, headline, body…)  |
| `filledButtonTheme`       | FilledButton default style                   |
| `inputDecorationTheme`    | TextField/TextFormField decoration defaults  |
| `appBarTheme`             | AppBar default styling                       |
| `cardTheme`               | Card default styling                         |
| `dialogTheme`             | Dialog default styling                       |

| Material 3 Color Role | Typical Use                          |
| ---------------------- | ------------------------------------ |
| `primary`              | Key UI elements, FAB, active states  |
| `onPrimary`            | Text/icons on primary color          |
| `secondary`            | Less prominent UI elements           |
| `surface`              | Card, sheet, dialog backgrounds      |
| `onSurface`            | Text/icons on surface color          |
| `error`                | Error indicators, destructive actions |
| `outline`              | Borders, dividers                    |
