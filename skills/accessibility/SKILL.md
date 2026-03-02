---
name: accessibility
description: Best practices for Flutter accessibility and WCAG 2.1 AA compliance. Use when building, auditing, or reviewing widgets for screen reader support, touch targets, focus management, color contrast, text scaling, or motion sensitivity.
---

# Accessibility

Flutter accessibility fundamentals for WCAG 2.1 AA compliance — semantics, touch targets, focus management, color contrast, text scaling, and motion sensitivity.

---

## Standards (Non-Negotiable)

These constraints apply to ALL accessibility work — no exceptions:

- **Every `Image` must have `semanticLabel` or be wrapped in `Semantics(label:)`** — decorative images use `excludeFromSemantics: true`
- **Never use `GestureDetector` for tap targets** — use `InkWell`, `ElevatedButton`, `TextButton`, or `IconButton`; `GestureDetector` is pointer-only and unreachable via keyboard or switch access
- **All interactive elements: 48x48 dp minimum touch target** — enforce with `SizedBox`, `ConstrainedBox`, or `padding`
- **Never use color as the sole differentiator** — always pair color with a label, icon, or shape
- **All animations must respect `MediaQuery.disableAnimations`** — gate every `AnimationController`, `AnimatedContainer`, and `Hero` transition on this flag
- **Icon-only buttons must have `Tooltip` or `Semantics(label:)`** — screen readers have no other way to convey purpose
- **Never use `ExcludeSemantics` on non-decorative content** — doing so hides meaningful information from assistive technology
- **Fixed-height containers must not wrap `Text`** — use `minHeight` constraints; fixed heights clip text at 1.5-2x font scale
- **Normal text contrast ratio must be at least 4.5:1; large text at least 3:1; UI components at least 3:1** — measure against WCAG 1.4.3 and 1.4.11

---

## Semantics & Screen Reader

Flutter's `Semantics` widget is the primary mechanism for communicating widget purpose to screen readers (TalkBack, VoiceOver).

### Semantic Labels

Every meaningful visual element must have a semantic label. A wrong label is worse than no label — labels must accurately describe the element's purpose.

```dart
// CORRECT — Image with semantic label
Image.asset(
  'assets/profile_photo.png',
  semanticLabel: 'Profile photo of the current user',
)

// CORRECT — Decorative image excluded from semantics
Image.asset(
  'assets/decorative_divider.png',
  excludeFromSemantics: true,
)

// CORRECT — Icon button with tooltip (provides semantic label automatically)
IconButton(
  icon: const Icon(Icons.delete),
  tooltip: 'Delete item',
  onPressed: _onDelete,
)
```

**Anti-pattern — empty or missing semantic label:**

```dart
// WRONG — Empty semanticLabel on meaningful content
Image.asset(
  'assets/warning_icon.png',
  semanticLabel: '', // Screen reader announces nothing
)

// WRONG — No semanticLabel on informative image
Image.asset('assets/chart.png') // Screen reader skips or announces filename
```

### ExcludeSemantics and MergeSemantics

Use `ExcludeSemantics` only for purely decorative content. Use `MergeSemantics` to combine related elements into a single screen reader announcement.

```dart
// CORRECT — Merge list tile content into one announcement
MergeSemantics(
  child: ListTile(
    leading: const Icon(Icons.email),
    title: const Text('inbox@example.com'),
    subtitle: const Text('3 unread messages'),
    onTap: _openInbox,
  ),
)

// CORRECT — Exclude decorative background
ExcludeSemantics(
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
    ),
  ),
)
```

**Anti-pattern — excluding meaningful content:**

```dart
// WRONG — Hides actionable content from assistive technology
ExcludeSemantics(
  child: ElevatedButton(
    onPressed: _submit,
    child: const Text('Submit'),
  ),
)
```

### Live Regions

Dynamic content that updates without user interaction (loading states, error messages, live counters) must announce changes to screen readers.

```dart
// CORRECT — Live region for dynamic status
Semantics(
  liveRegion: true,
  child: Text('$itemCount items in cart'),
)

// CORRECT — Programmatic announcement
SemanticsService.announce('Upload complete', TextDirection.ltr);
```

---

## Touch Target Sizes

All interactive elements must have a minimum touch target of 48x48 dp (WCAG 2.5.5).

```dart
// CORRECT — IconButton already defaults to 48dp
IconButton(
  icon: const Icon(Icons.favorite),
  tooltip: 'Add to favorites',
  onPressed: _onFavorite,
)

// CORRECT — Ensure small custom widget meets minimum size
SizedBox(
  width: 48,
  height: 48,
  child: InkWell(
    onTap: _onTap,
    child: const Icon(Icons.close, size: 16),
  ),
)

// CORRECT — Padding to expand touch target
Padding(
  padding: const EdgeInsets.all(12),
  child: InkWell(
    onTap: _onTap,
    child: const Icon(Icons.info, size: 24),
  ),
)
```

**Anti-pattern — touch target too small:**

```dart
// WRONG — Touch target is 24x24, below 48dp minimum
SizedBox(
  width: 24,
  height: 24,
  child: GestureDetector(
    onTap: _onTap,
    child: const Icon(Icons.close, size: 24),
  ),
)
```

---

## Focus & Keyboard Navigation

Every interactive widget must be reachable and operable via keyboard and switch access (WCAG 2.1.1, 2.1.2).

### Focus Traversal Order

Use `FocusTraversalGroup` when the default tab order does not match the visual reading order.

```dart
// CORRECT — Explicit traversal group for a multi-column layout
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Row(
    children: [
      FocusTraversalOrder(
        order: const NumericFocusOrder(1),
        child: TextField(decoration: const InputDecoration(labelText: 'First name')),
      ),
      FocusTraversalOrder(
        order: const NumericFocusOrder(2),
        child: TextField(decoration: const InputDecoration(labelText: 'Last name')),
      ),
    ],
  ),
)
```

### Dialog Focus Management

Dialogs and overlays must request focus on open and restore focus on dismiss (WCAG 2.4.3).

```dart
// CORRECT — showDialog handles focus automatically
showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Confirm deletion'),
    content: const Text('This action cannot be undone.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          _delete();
          Navigator.of(context).pop();
        },
        child: const Text('Delete'),
      ),
    ],
  ),
);
```

### Custom Focus Indicators

Custom focus indicators must meet 3:1 contrast ratio against the background (WCAG 2.4.11).

```dart
// CORRECT — High-contrast focus indicator
Focus(
  child: Builder(
    builder: (context) {
      final isFocused = Focus.of(context).hasFocus;
      return Container(
        decoration: BoxDecoration(
          border: isFocused
              ? Border.all(color: Colors.blue.shade900, width: 3)
              : null,
        ),
        child: const Text('Focusable item'),
      );
    },
  ),
)
```

**Anti-pattern — keyboard-inaccessible tap handler:**

```dart
// WRONG — GestureDetector is not keyboard-accessible
GestureDetector(
  onTap: _onTap,
  child: const Text('Click me'),
)

// CORRECT — InkWell is focusable and keyboard-accessible
InkWell(
  onTap: _onTap,
  child: const Text('Click me'),
)
```

---

## Color Contrast

All text and UI components must meet WCAG contrast ratios against their background.

| Element | Minimum ratio | WCAG criterion |
| --- | --- | --- |
| Normal text (< 18pt / < 14pt bold) | 4.5:1 | 1.4.3 |
| Large text (>= 18pt / >= 14pt bold) | 3:1 | 1.4.3 |
| UI components and focus indicators | 3:1 | 1.4.11 |

### Theme-Based Approach

Define all colors through the theme's `ColorScheme` to ensure consistent contrast:

```dart
// CORRECT — Use ColorScheme tokens
Theme.of(context).colorScheme.onSurface   // text on surface
Theme.of(context).colorScheme.onPrimary   // text on primary
Theme.of(context).colorScheme.error       // error text/icon
```

**Anti-pattern — hardcoded low-contrast colors:**

```dart
// WRONG — Light gray on white fails 4.5:1
Text(
  'Status: Active',
  style: TextStyle(color: Colors.grey.shade300),
)

// WRONG — Color as sole differentiator
Container(
  color: isValid ? Colors.green : Colors.red, // No label or icon
)

// CORRECT — Color paired with icon and label
Row(
  children: [
    Icon(
      isValid ? Icons.check_circle : Icons.error,
      color: isValid ? Colors.green : Colors.red,
    ),
    const SizedBox(width: 8),
    Text(isValid ? 'Valid' : 'Invalid'),
  ],
)
```

---

## Text Scaling

Widgets must accommodate user font-size preferences up to 2x scale without clipping or overflow (WCAG 1.4.4).

### Flexible Containers

Use `minHeight` constraints instead of fixed heights around text:

```dart
// CORRECT — Minimum height allows text to expand
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48),
  child: const Padding(
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: Text('This text can grow with user font settings'),
  ),
)
```

**Anti-pattern — fixed height around text:**

```dart
// WRONG — Fixed height clips text at large scale
SizedBox(
  height: 48,
  child: Text('This text will be clipped at 1.5x font scale'),
)
```

**Anti-pattern — clamping text scale:**

```dart
// WRONG — Overrides user accessibility preferences
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.noScaling,
  ),
  child: const Text('Ignoring user font preferences'),
)
```

### Overflow Handling

Use `TextOverflow.ellipsis` with `maxLines` and a `Semantics` wrapper so the full text is still available to screen readers:

```dart
// CORRECT — Ellipsis with full semantic label
Semantics(
  label: longDescription,
  child: Text(
    longDescription,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
)
```

---

## Animation & Motion

All animations must respect the user's reduced-motion preference (WCAG 2.3.3). Flashing content must never exceed 3 flashes per second (WCAG 2.3.1).

### Gating Animations

```dart
// CORRECT — Respect disableAnimations
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = _controller.upperBound;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Text('Animated content'),
    );
  }
}
```

**Anti-pattern — ignoring reduced-motion preference:**

```dart
// WRONG — Animation always plays regardless of user preference
AnimatedContainer(
  duration: const Duration(milliseconds: 500),
  color: _isActive ? Colors.blue : Colors.grey,
  child: child,
)

// CORRECT — Gate on disableAnimations
AnimatedContainer(
  duration: MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 500),
  color: _isActive ? Colors.blue : Colors.grey,
  child: child,
)
```

---

## Accessibility Audit Workflow

When auditing a screen or widget for accessibility, check all six categories in order and produce a structured report:

```text
# Flutter Accessibility Audit

Files audited: [list]

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL |  X    |
| MAJOR    |  X    |
| MINOR    |  X    |

## Findings

### 1. [Title]
- File: path/to/file.dart ~L42
- WCAG: 1.4.3
- Severity: CRITICAL
- Issue: [description]
- Fix:
  // Before
  [code]
  // After
  [code]

## Passed Checks
[List passed checks to confirm audit completeness]
```

Severity definitions:

| Severity | Meaning |
| --- | --- |
| **CRITICAL** | Blocks assistive technology users entirely — fix before merging |
| **MAJOR** | Significant barrier — fix in current sprint |
| **MINOR** | Degraded experience — schedule for next sprint |

---

## Testing

Write accessibility-focused widget tests using `tester.ensureSemantics()` to enable the semantics tree during testing.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileImage accessibility', () {
    testWidgets('has semantic label for screen readers', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Image(
              image: AssetImage('assets/profile.png'),
              semanticLabel: 'Profile photo',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(Image));
      expect(semantics.label, 'Profile photo');

      handle.dispose();
    });
  });

  group('ActionButton accessibility', () {
    testWidgets('icon button has tooltip for screen readers', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete item',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Delete item'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('interactive element meets minimum touch target',
        (tester) async {
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
  });
}
```

---

## Additional Resources

See [reference.md](reference.md) for extended code examples for each category, a comprehensive WCAG 2.1 AA checklist with Flutter solutions, a complete audit output format template, a full accessibility test suite example, and a widget-to-accessibility requirements mapping table.
