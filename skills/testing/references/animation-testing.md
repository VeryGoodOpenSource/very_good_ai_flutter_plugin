# Animation Testing

Testing patterns specific to Flutter animations. See the [Animations skill](../../animations/SKILL.md) for core animation standards and the decision tree.

## Testing Implicit Animations

Use `pump` with specific durations to verify intermediate and final states:

```dart
testWidgets('card fades in when visible', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: FadingCard(isVisible: false),
    ),
  );

  // Verify initial state
  final opacity = tester.widget<AnimatedOpacity>(
    find.byType(AnimatedOpacity),
  );
  expect(opacity.opacity, 0.0);

  // Trigger animation
  await tester.pumpWidget(
    const MaterialApp(
      home: FadingCard(isVisible: true),
    ),
  );

  // Verify target is set
  final updatedOpacity = tester.widget<AnimatedOpacity>(
    find.byType(AnimatedOpacity),
  );
  expect(updatedOpacity.opacity, 1.0);

  // Let animation complete
  await tester.pumpAndSettle();

  // Verify final rendered state
  final renderOpacity = tester.renderObject<RenderAnimatedOpacity>(
    find.byType(AnimatedOpacity),
  );
  expect(renderOpacity.opacity.value, 1.0);
});
```

## Testing Explicit Animations

Use `pump` with frame durations to verify animation progress:

```dart
testWidgets('spinner rotates continuously', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Spinner()),
  );

  // Capture initial transform
  final initialTransform = tester.widget<Transform>(
    find.byType(Transform),
  );

  // Advance one frame
  await tester.pump(const Duration(milliseconds: 16));

  // Verify rotation has progressed
  final updatedTransform = tester.widget<Transform>(
    find.byType(Transform),
  );
  expect(updatedTransform.transform, isNot(initialTransform.transform));
});
```

## Testing AnimatedSwitcher

```dart
testWidgets('content cross-fades on state change', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: CounterDisplay(count: 0),
    ),
  );

  expect(find.text('0'), findsOneWidget);

  await tester.pumpWidget(
    const MaterialApp(
      home: CounterDisplay(count: 1),
    ),
  );

  // During cross-fade, both widgets exist
  await tester.pump(Durations.medium2 ~/ 2);
  expect(find.text('0'), findsOneWidget);
  expect(find.text('1'), findsOneWidget);

  // After animation completes, only new widget remains
  await tester.pumpAndSettle();
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
});
```

## Testing Page Transitions

```dart
testWidgets('details page slides in from right', (tester) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/details',
        pageBuilder: (context, state) => AppPageTransitions.slideFade(
          key: state.pageKey,
          child: const DetailsPage(),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );

  router.go('/details');
  await tester.pump();
  await tester.pump(Durations.medium4 ~/ 2);

  // Verify transition is in progress — details page exists but not settled
  expect(find.byType(DetailsPage), findsOneWidget);

  await tester.pumpAndSettle();
  expect(find.byType(DetailsPage), findsOneWidget);
  expect(find.byType(HomePage), findsNothing);
});
```

## Animation Testing Tips

- **Use `pumpAndSettle()`** to let all animations complete — but set a timeout for infinite animations: `await tester.pumpAndSettle(const Duration(seconds: 5))`
- **Use `pump(duration)`** to advance to a specific point in an animation for intermediate state verification
- **Never test exact pixel values for transforms** — test direction and completion instead
- **For repeating animations, do not use `pumpAndSettle()`** — it will time out. Use `pump` with explicit durations instead
