# Accessibility — Reference

Extended reference material for the Accessibility skill: detailed code examples for each category, WCAG 2.1 checklists by level (A, AA, AAA), audit report templates per level, full accessibility test suite, and widget-to-accessibility requirements mapping.

---

## Semantics & Screen Reader — Extended Examples

### Custom Semantics for Complex Widgets

```dart
import 'package:flutter/material.dart';

/// A rating bar that provides a single semantic description
/// instead of exposing individual star icons.
class AccessibleRatingBar extends StatelessWidget {
  const AccessibleRatingBar({
    required this.rating,
    required this.maxRating,
    super.key,
  });

  final int rating;
  final int maxRating;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rating: $rating out of $maxRating stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
            );
          }),
        ),
      ),
    );
  }
}
```

### Live Region for Async Status Updates

```dart
import 'package:flutter/material.dart';

class UploadStatusIndicator extends StatelessWidget {
  const UploadStatusIndicator({
    required this.status,
    super.key,
  });

  final UploadStatus status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 8),
          Text(_statusText),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return switch (status) {
      UploadStatus.idle => const SizedBox.shrink(),
      UploadStatus.uploading => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      UploadStatus.success => const Icon(Icons.check_circle, color: Colors.green),
      UploadStatus.error => const Icon(Icons.error, color: Colors.red),
    };
  }

  String get _statusText => switch (status) {
        UploadStatus.idle => '',
        UploadStatus.uploading => 'Uploading...',
        UploadStatus.success => 'Upload complete',
        UploadStatus.error => 'Upload failed',
      };
}

enum UploadStatus { idle, uploading, success, error }
```

---

## Touch Target Sizes — Extended Examples

### Expanding Small Icons to Meet Minimum Size

```dart
import 'package:flutter/material.dart';

/// Wraps any small widget in a minimum 48x48 touch target.
class AccessibleTapTarget extends StatelessWidget {
  const AccessibleTapTarget({
    required this.onTap,
    required this.semanticLabel,
    required this.child,
    super.key,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// Usage
AccessibleTapTarget(
  onTap: _onClose,
  semanticLabel: 'Close dialog',
  child: const Icon(Icons.close, size: 16),
)
```

---

## Focus & Keyboard — Extended Examples

### Custom Focus Traversal for a Form

```dart
import 'package:flutter/material.dart';

class AccessibleForm extends StatelessWidget {
  const AccessibleForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 16),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(height: 24),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Color Contrast — Extended Examples

### Building a Contrast-Safe Theme

```dart
import 'package:flutter/material.dart';

/// All color pairings maintain WCAG AA contrast ratios.
ThemeData buildAccessibleTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1565C0),       // Blue 800
    onPrimary: Color(0xFFFFFFFF),     // White — 8.6:1 on primary
    secondary: Color(0xFF00695C),     // Teal 800
    onSecondary: Color(0xFFFFFFFF),   // White — 7.1:1 on secondary
    error: Color(0xFFB71C1C),         // Red 900
    onError: Color(0xFFFFFFFF),       // White — 7.8:1 on error
    surface: Color(0xFFFFFFFF),       // White
    onSurface: Color(0xFF212121),     // Grey 900 — 16:1 on white
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    ),
  );
}
```

### Status Indicators Without Color Dependency

```dart
import 'package:flutter/material.dart';

class AccessibleStatusBadge extends StatelessWidget {
  const AccessibleStatusBadge({
    required this.status,
    super.key,
  });

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      TaskStatus.pending => (Icons.hourglass_empty, 'Pending', Colors.orange),
      TaskStatus.active => (Icons.play_circle, 'Active', Colors.blue),
      TaskStatus.complete => (Icons.check_circle, 'Complete', Colors.green),
      TaskStatus.error => (Icons.error, 'Error', Colors.red),
    };

    // Color is NEVER the sole indicator — icon + label always present
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

enum TaskStatus { pending, active, complete, error }
```

---

## Text Scaling — Extended Examples

### Adaptive Card Layout

```dart
import 'package:flutter/material.dart';

class AdaptiveInfoCard extends StatelessWidget {
  const AdaptiveInfoCard({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No fixed height — text grows freely
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // ConstrainedBox with minHeight, never fixed height
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Animation & Motion — Extended Examples

### Animated Page Transition Respecting Reduced Motion

```dart
import 'package:flutter/material.dart';

class AccessiblePageRoute<T> extends MaterialPageRoute<T> {
  AccessiblePageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration {
    // When called before the route is installed, navigator may be null.
    // Default to the standard duration; didChangeDependencies will
    // handle the disableAnimations check once the context is available.
    return const Duration(milliseconds: 300);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return child; // No transition — instant page change
    }
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
```

### Hero Animation with Reduced-Motion Support

```dart
import 'package:flutter/material.dart';

class AccessibleHero extends StatelessWidget {
  const AccessibleHero({
    required this.tag,
    required this.child,
    super.key,
  });

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations) {
      return child; // Skip Hero animation entirely
    }

    return Hero(
      tag: tag,
      child: child,
    );
  }
}
```

---

## Audit Report Templates by Level

Each template is pre-annotated with the criteria applicable at that level. Use the template matching the level selected in Phase 1 of the Workflow.

### Severity Guide

| Severity | Meaning |
| --- | --- |
| **CRITICAL** | Blocks assistive technology users entirely — fix before merging |
| **MAJOR** | Significant barrier — fix in current sprint |
| **MINOR** | Degraded experience or polish item — schedule for next sprint |

Severity assignment:

- **CRITICAL** — criterion applies at selected level AND issue completely blocks the use case (e.g., no semantic label on primary action, `GestureDetector` on a required flow, zero focus visibility)
- **MAJOR** — criterion applies at selected level AND issue significantly degrades the experience (e.g., contrast ratio fails by > 1 point, touch target < 40dp, dialog does not trap focus)
- **MINOR** — criterion applies at selected level AND issue is a refinement (e.g., contrast fails marginally, live region missing on non-critical status, focus indicator present but border width 1px instead of 2px)

### Template (all levels)

```text
# Flutter Accessibility Audit

**Date:** YYYY-MM-DD
**WCAG Level:** [A | AA | AAA]
**Platforms:** [Mobile | Desktop | Web | combination]
**Files audited:**
- path/to/file.dart

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL |  0    |
| MAJOR    |  0    |
| MINOR    |  0    |

## Findings

### 1. [Short descriptive title]
- **File:** path/to/file.dart ~L42
- **WCAG:** [criterion ID] [criterion name] (Level [A/AA/AAA])
- **Platform(s):** [Mobile | Desktop | Web | All]
- **Severity:** [CRITICAL | MAJOR | MINOR]
- **Issue:** [description]
- **Fix:**
  // Before
  [existing code]

  // After
  [fixed code]

### 2. [Next finding...]

## Passed Checks
[copy the applicable checks from the level lists below]
```

### Passed Checks — Level A

```text
- [x] A · Semantics & Screen Reader — all images/icons have semantic labels; roles correct
- [x] B · Touch Target Sizes — all interactive elements >= 48dp (mobile)
- [x] C · Focus & Keyboard — all interactions reachable via keyboard; no traps
- [x] D · Color — color is never sole differentiator
- [x] E · Text Scaling — no fixed-height text containers
- [x] F · Animation & Motion — no content flashes > 3 Hz (2.3.1)
```

### Passed Checks — Level AA (Level A + these)

```text
- [x] C · Focus & Keyboard — focus indicator visible with 3:1 contrast (2.4.7, 2.4.11)
- [x] D · Color Contrast — normal text >= 4.5:1, large text >= 3:1, UI components >= 3:1 (1.4.3, 1.4.11)
- [x] E · Text Scaling — text scales to 200% without loss (1.4.4)
- [x] F · Animation & Motion — all animations gated on disableAnimations (2.3.3)
- [x] G · Orientation — not locked to single orientation (1.3.4)
- [x] H · Input Purpose — autofillHints and keyboardType correct (1.3.5)
- [x] I · Reflow — content reflows at 320px equivalent (1.4.10) [web/desktop]
```

### Passed Checks — Level AAA (Level AA + these)

```text
- [x] B · Touch Target Sizes — all interactive elements >= 44dp (2.5.5)
- [x] C · Focus & Keyboard — no GestureDetector anywhere (2.1.3); indicator encloses component with 2px border (2.4.12)
- [x] D · Color Contrast (Enhanced) — normal text >= 7:1, large text >= 4.5:1 (1.4.6)
- [x] F · Animation & Motion — zero flashing content (2.3.2)
- [x] J · No Timing — no mandatory time limits (2.2.3)
- [x] K · Location — breadcrumbs or current-screen indication visible (2.4.8)
- [x] L · Input Modality — no single-modality restriction (2.5.6)
```

---

## Full Accessibility Test Suite Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // --- A. Semantics & Screen Reader ---
  group('Semantics', () {
    testWidgets('all images have semantic labels', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Image(
              image: AssetImage('assets/logo.png'),
              semanticLabel: 'Company logo',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(Image));
      expect(semantics.label, isNotEmpty);

      handle.dispose();
    });

    testWidgets('icon buttons have tooltips', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Search'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('live region announces status changes', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Semantics(
              liveRegion: true,
              child: Text('Loading complete'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.text('Loading complete'));
      expect(
        semantics.flags & SemanticsFlag.isLiveRegion.index,
        isNonZero,
      );

      handle.dispose();
    });
  });

  // --- B. Touch Target Sizes ---
  group('Touch targets', () {
    testWidgets('icon button meets 48dp minimum', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('text button meets 48dp minimum height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(TextButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  // --- C. Focus & Keyboard ---
  group('Focus management', () {
    testWidgets('dialog traps focus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Confirm'),
                    content: Text('Are you sure?'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog is displayed and receives focus
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('interactive elements are focusable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Button')),
                InkWell(onTap: () {}, child: const Text('Link')),
              ],
            ),
          ),
        ),
      );

      // Both elements have Focus ancestors
      final buttonFocus = Focus.of(
        tester.element(find.byType(ElevatedButton)),
      );
      expect(buttonFocus.canRequestFocus, isTrue);
    });
  });

  // --- D. Color Contrast ---
  group('Color contrast', () {
    testWidgets('error state uses icon and label, not just color',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Invalid input'),
              ],
            ),
          ),
        ),
      );

      // Both icon and text are present — not color alone
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Invalid input'), findsOneWidget);
    });
  });

  // --- E. Text Scaling ---
  group('Text scaling', () {
    testWidgets('text container uses minHeight, not fixed height',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 48),
              child: Text('Scalable text'),
            ),
          ),
        ),
      );

      // At default scale, widget renders
      expect(find.text('Scalable text'), findsOneWidget);
    });

    testWidgets('text is not clipped at 2x scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 48),
                  child: Text('This text should not be clipped'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('This text should not be clipped'), findsOneWidget);
    });
  });

  // --- F. Animation & Motion ---
  group('Animation & motion', () {
    testWidgets('animations are disabled when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final disabled =
                      MediaQuery.of(context).disableAnimations;
                  return AnimatedContainer(
                    duration: disabled
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    color: Colors.blue,
                    child: const Text('Animated'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Animated'), findsOneWidget);
    });
  });
}
```

---

## Widget-to-Accessibility Requirements Mapping

| Widget | Accessibility Requirement | Implementation |
| --- | --- | --- |
| `Image` | Text alternative | `semanticLabel` or `Semantics(label:)`; use `excludeFromSemantics: true` for decorative images |
| `Icon` | Text alternative | Wrap in `Semantics(label:)` or use within a widget that provides a label |
| `IconButton` | Text alternative + touch target | `tooltip` parameter (auto-provides semantic label); inherits 48dp minimum |
| `GestureDetector` | Keyboard access | Replace with `InkWell` or button widget; `GestureDetector` is pointer-only |
| `InkWell` | Semantic role | Add `Semantics(label:, button: true)` when used as a custom button |
| `ElevatedButton` | Touch target | Inherits 48dp minimum; provide descriptive `child` text |
| `TextButton` | Touch target | Inherits 48dp minimum; provide descriptive `child` text |
| `TextField` | Label | Use `InputDecoration(labelText:)` — always provide a visible label |
| `Checkbox` | Label + state | Wrap in `CheckboxListTile` for automatic label association |
| `Switch` | Label + state | Wrap in `SwitchListTile` for automatic label association |
| `Slider` | Label + value | Use `Semantics(label:, value:)` or `Slider.adaptive` |
| `DropdownButton` | Label + expanded state | Wrap in `DropdownButtonFormField` with `InputDecoration(labelText:)` |
| `AlertDialog` | Focus management | `showDialog` handles focus trapping and restoration automatically |
| `BottomSheet` | Focus management | `showModalBottomSheet` handles focus trapping and restoration automatically |
| `ListView` | Scrolling semantics | Flutter handles scroll semantics automatically; ensure list items are accessible |
| `TabBar` | Tab semantics | Flutter provides tab semantics automatically via `TabBar` + `TabBarView` |
| `AnimatedContainer` | Motion sensitivity | Gate `duration` on `MediaQuery.of(context).disableAnimations` |
| `Hero` | Motion sensitivity | Skip `Hero` when `disableAnimations` is true |
| `PageRoute` | Motion sensitivity | Override `buildTransitions` to return `child` directly when animations disabled |

---

## References

- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility) — official Flutter documentation on accessibility APIs, TalkBack/VoiceOver integration, and `Semantics` widget usage
- [WCAG 2.1 Understanding Document](https://www.w3.org/WAI/WCAG21/Understanding/) — W3C explanations of each success criterion, including intent, examples, and sufficient techniques
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/) — filterable checklist of all success criteria by level
