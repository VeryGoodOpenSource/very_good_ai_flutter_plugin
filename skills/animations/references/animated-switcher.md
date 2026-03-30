# AnimatedSwitcher Patterns

`AnimatedSwitcher` cross-fades between children when the child's key or type changes.

## Basic Cross-Fade

```dart
AnimatedSwitcher(
  duration: Durations.medium2,
  switchInCurve: Easing.emphasizedDecelerate,
  switchOutCurve: Easing.emphasizedAccelerate,
  child: Text(
    '$count',
    key: ValueKey(count),
    style: Theme.of(context).textTheme.headlineMedium,
  ),
)
```

## Custom Transition (Slide + Fade)

```dart
AnimatedSwitcher(
  duration: Durations.medium2,
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  },
  child: _buildContent(state),
)
```

## Layout Builder for Size Changes

Wrap `AnimatedSwitcher` in `AnimatedSize` when children have different sizes:

```dart
AnimatedSize(
  duration: Durations.medium2,
  curve: Easing.emphasized,
  child: AnimatedSwitcher(
    duration: Durations.medium2,
    child: _buildContent(state),
  ),
)
```
