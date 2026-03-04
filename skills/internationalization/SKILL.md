---
name: internationalization
description: Best practices for internationalization (i18n) and localization (l10n) in Flutter. Use when adding, modifying, or reviewing ARB translations, locale setup, BuildContext l10n extensions, or RTL/directional layout support.
---

# Internationalization

Internationalization (i18n) and localization (l10n) best practices for Flutter applications using Flutter's built-in localization system with ARB files as the single source of truth.

## Core Standards

Apply these standards to ALL internationalization work:

- **Never hardcode user-facing strings** — all text must go through the l10n system
- **Use Flutter's built-in localization system** — `flutter_localizations` + `intl`, never third-party i18n libraries
- **ARB files are the single source of truth** for all translations
- **`BuildContext` extension for cleaner l10n access** — use `context.l10n` instead of `AppLocalizations.of(context)`
- **Pass localized strings as parameters to reusable widgets** — never couple shared widgets directly to `AppLocalizations`
- **Use `EdgeInsetsDirectional` (start/end) instead of `EdgeInsets` (left/right)** — ensures correct layout in RTL languages
- **Handle RTL layout properly** — use directional widgets for padding, positioning, and alignment
- **Implement i18n early** — even if only one language is planned initially, the overhead is small and the long-term benefit is significant

## Key Definitions

| Term                          | Definition                                                                                  |
| ----------------------------- | ------------------------------------------------------------------------------------------- |
| **Locale**                    | Set of properties defining user region, language, and preferences (currency, time, numbers)  |
| **Localization (l10n)**       | Process of adapting software for a specific language by translating text and adding regional layouts |
| **Internationalization (i18n)** | Process of designing software so it can be adapted to different languages without engineering changes |

## Setup Pipeline

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

### 2. Configure `l10n.yaml`

Create `l10n.yaml` in the project root:

```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
preferred-supported-locales: [en]
```

Set `preferred-supported-locales` explicitly to avoid alphabetical ordering of locales.

### 3. Create ARB Files

Store translation files in `lib/l10n/arb/`:

**`app_en.arb`** (template — this is the source of truth):

```json
{
  "@@locale": "en",
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "Greeting shown on the home page"
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Label showing the number of items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "welcomeUser": "Welcome, {name}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

**`app_es.arb`**:

```json
{
  "@@locale": "es",
  "helloWorld": "¡Hola Mundo!",
  "itemCount": "{count, plural, =0{Sin elementos} =1{1 elemento} other{{count} elementos}}",
  "welcomeUser": "¡Bienvenido, {name}!"
}
```

### 4. Generate Localization Code

```bash
flutter gen-l10n
```

### 5. Integrate with `MaterialApp`

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

const MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
```

## ARB File Format

### Simple Strings

```json
{
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "Greeting shown on the home page"
  }
}
```

### Placeholders

```json
{
  "welcomeUser": "Welcome, {name}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

### Plurals

```json
{
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Label showing the number of items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

## BuildContext Extension

Create an extension for ergonomic l10n access throughout the codebase:

```dart
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

Usage:

```dart
// Preferred
Text(context.l10n.helloWorld);

// Avoid
Text(AppLocalizations.of(context).helloWorld);
```

## Reusable Widget Strategy

Shared widgets that live in separate packages should not depend on `AppLocalizations` directly. Instead, pass localized strings as constructor parameters:

```dart
// Shared widget — no l10n dependency
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(cancelLabel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
      ],
    );
  }
}

// App-level usage — passes localized strings
showDialog<bool>(
  context: context,
  builder: (_) => ConfirmDialog(
    title: context.l10n.deleteTitle,
    message: context.l10n.deleteMessage,
    confirmLabel: context.l10n.confirm,
    cancelLabel: context.l10n.cancel,
  ),
);
```


## Text Directionality

### The `Directionality` Widget

Flutter provides a global `Directionality` widget determined by the user's locale. You can override it explicitly:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: Row(
    children: [
      // Children laid out right-to-left
    ],
  ),
)
```

Retrieve the current direction: `Directionality.of(context)`

### Visual vs Directional Widgets

| Widget Type     | Direction Terms       | Use Case                                    |
| --------------- | --------------------- | ------------------------------------------- |
| **Visual**      | top, left, right, bottom | Absolute positioning that never changes    |
| **Directional** | top, start, end, bottom  | Relative to text direction (respects RTL)  |

### `EdgeInsetsDirectional` vs `EdgeInsets`

Always use `EdgeInsetsDirectional` for padding and margins that should respect text direction:

```dart
// Preferred — respects RTL
Padding(
  padding: EdgeInsetsDirectional.only(start: 12),
  child: Text('Padding at text start regardless of direction'),
)

// Only for absolute positioning that must not change
Padding(
  padding: EdgeInsets.only(left: 10),
  child: Text('Always 10px from left edge'),
)
```

Many widgets offer `Directional` variants: `PositionedDirectional`, `AlignDirectional`, `BorderDirectional`, etc.

### Icon and Image Mirroring

- **Icons** mirror automatically in RTL contexts by default. To prevent mirroring, set the `Icon`'s `textDirection` property explicitly.
- **Images** do not mirror by default. Set `matchTextDirection: true` to mirror images in RTL.

### Material Design Bidirectionality Standards

Follow Material Design conventions:

- **Mirror**: Forward/future directional indicators (arrows, chevrons)
- **Do not mirror**: Media progress indicators, negation symbols, physical objects (clocks, tools)

## Backend Considerations

### Multi-Language Content Storage

When the backend serves user-facing content:

1. Store database entries with translations for each supported language
2. Require clients to transmit the user's locale with each request or during session initialization
3. Return content in the requested locale

### Error Message Localization

Two approaches for localizing error messages from the backend:

**HTTP Status Code Mapping**: The frontend maps standard HTTP status codes to l10n keys.

**Custom Error Constants**: The backend returns error constants that the app maps to localized strings:

```dart
// Backend returns: { "error": "expired_code" }
// Frontend maps to l10n key:
final message = switch (error) {
  'invalid_code' => context.l10n.errorInvalidCode,
  'expired_code' => context.l10n.errorExpiredCode,
  'limit_reached' => context.l10n.errorLimitReached,
  _ => context.l10n.errorGeneric,
};
```

## Common Patterns

### Adding a New Locale

1. Create `app_<locale>.arb` in `lib/l10n/arb/` (e.g., `app_fr.arb`)
2. Add translations for all keys from the template ARB file
3. Run `flutter gen-l10n`
4. The new locale is automatically available through `AppLocalizations.supportedLocales`

### Adding a New String

1. Add the key-value pair to the template ARB file (`app_en.arb`)
2. Add the `@key` metadata with description and placeholders if needed
3. Add translations in all other ARB files
4. Run `flutter gen-l10n`
5. Use via `context.l10n.newKey`

### Pluralization

1. Define the plural string in the template ARB file using ICU message syntax
2. Provide placeholder metadata with `"type": "int"`
3. Add plural forms in all locale ARB files
4. Use via `context.l10n.itemCount(items.length)`

## Quick Reference

| Package                    | Purpose                                |
| -------------------------- | -------------------------------------- |
| `flutter_localizations`    | Flutter's built-in localization support |
| `intl`                     | Internationalization utilities          |

| Command              | Purpose                                     |
| -------------------- | ------------------------------------------- |
| `flutter gen-l10n`   | Generate localization classes from ARB files |

| File               | Purpose                                          |
| ------------------ | ------------------------------------------------ |
| `l10n.yaml`        | Localization configuration (ARB dir, output, etc.) |
| `app_en.arb`       | Template ARB file (source of truth)              |
| `app_<locale>.arb` | Translated ARB file for each locale              |
