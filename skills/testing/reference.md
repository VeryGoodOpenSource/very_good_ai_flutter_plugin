# Dart & Flutter Testing — Reference

Extended reference material for the Testing skill: widget test examples, golden file testing, matchers, configuration, and coverage patterns.

---

## Widget Test Structure

Full example testing a page that uses a Bloc:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/home/home_page.dart';

import '../helpers/helpers.dart';

class _MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  group(HomePage, () {
    late HomeCubit homeCubit;

    setUp(() {
      homeCubit = _MockHomeCubit();
      when(() => homeCubit.state).thenReturn(const HomeState());
    });

    Widget buildSubject() {
      return BlocProvider<HomeCubit>.value(
        value: homeCubit,
        child: const HomePage(),
      );
    }

    group('renders', () {
      testWidgets('displays welcome text', (tester) async {
        await tester.pumpApp(buildSubject());

        expect(find.text('Welcome'), findsOneWidget);
      });

      testWidgets('displays loading indicator when status is loading',
          (tester) async {
        when(() => homeCubit.state).thenReturn(
          const HomeState(status: HomeStatus.loading),
        );

        await tester.pumpApp(buildSubject());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('navigates', () {
      testWidgets('to SettingsPage when settings icon is tapped',
          (tester) async {
        await tester.pumpApp(buildSubject());

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('calls', () {
      testWidgets('loadData when refresh button is tapped',
          (tester) async {
        when(() => homeCubit.loadData()).thenAnswer((_) async {});

        await tester.pumpApp(buildSubject());

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        verify(() => homeCubit.loadData()).called(1);
      });
    });
  });
}
```

### Testing Themes and Localization

Extend `pumpApp` to inject theme and localizations when needed:

```dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
  }) {
    return pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: widget,
      ),
    );
  }
}
```

---

## Golden File Testing

Golden tests capture a rendered widget as an image and compare it against a stored reference file (the "golden"). They validate visual appearance — layout, colors, typography, and spacing — without requiring behavioral assertions.

### When to Use Goldens vs Behavioral Tests

| Concern | Test type | Why |
| --- | --- | --- |
| Button triggers navigation | Widget test | Behavioral outcome |
| Page shows correct text for state | Widget test | Content based on logic |
| Widget matches design spec visually | Golden test | Pixel-level appearance |
| Layout does not regress after refactor | Golden test | Visual regression detection |
| Icon/color changes with theme | Golden test | Visual property |

### Setup and Configuration

1. Declare the `golden` tag in `dart_test.yaml`:

```yaml
tags:
  golden:
```

2. Define a `TestTag` constant (if not already present):

```dart
// test/helpers/test_tags.dart
abstract class TestTag {
  static const golden = 'golden';
}
```

### Writing a Golden Test

```dart
@Tags([TestTag.golden])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

void main() {
  group(ProfileCard, () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpApp(
        const ProfileCard(name: 'Dash', role: 'Mascot'),
      );

      await expectLater(
        find.byType(ProfileCard),
        matchesGoldenFile('goldens/profile_card.png'),
      );
    });
  });
}
```

### Tagging Golden Tests

Use the library-level `@Tags` annotation so that every test in the file is tagged:

```dart
@Tags([TestTag.golden])
library;
```

For files that mix golden and behavioral tests, tag individual tests:

```dart
testWidgets('matches golden', tags: TestTag.golden, (tester) async {
  // ...
});
```

### Running and Updating Goldens

| Command | Purpose |
| --- | --- |
| `flutter test --tags golden` | Run only golden tests |
| `flutter test --tags golden --update-goldens` | Regenerate golden reference files |
| `flutter test --exclude-tags golden` | Run all tests except goldens |
| `flutter test` | Run all tests including goldens |

After updating goldens, review and commit the new `.png` files — they are the source of truth.

### Golden Testing Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Untagged golden tests | Cannot run or update goldens independently | Always tag with `TestTag.golden` |
| Testing behavior with goldens | Goldens verify appearance, not logic | Use widget tests for behavioral assertions |
| Uncommitted golden files | CI fails because reference images are missing | Commit `.png` goldens alongside test code |
| Raw string tags (`tags: 'golden'`) | Fragile; typos silently create new tags | Use `TestTag.golden` constant |

---

## Matchers Quick Reference

| Matcher | Asserts |
| --- | --- |
| `equals(x)` | Deep equality |
| `isA<T>()` | Value is of type `T` |
| `isA<T>().having(fn, name, matcher)` | Type check + property assertion |
| `isNull` / `isNotNull` | Null checks |
| `isTrue` / `isFalse` | Boolean checks |
| `contains(x)` | Collection or string contains `x` |
| `hasLength(n)` | Collection has `n` elements |
| `isEmpty` / `isNotEmpty` | Collection emptiness |
| `predicate<T>(fn)` | Custom boolean function |
| `closeTo(value, delta)` | Numeric value within `delta` of `value` |
| `greaterThan(n)` / `lessThan(n)` | Numeric comparisons |
| `containsAll(list)` | Collection contains all elements |
| `containsAllInOrder(list)` | Collection contains all elements in order |
| `throwsA(matcher)` | Function throws matching exception |
| `throwsA(isA<T>())` | Function throws exception of type `T` |
| `emits(matcher)` | Stream emits a matching value |
| `emitsInOrder(list)` | Stream emits values in order |
| `emitsDone` | Stream closes |
| `emitsError(matcher)` | Stream emits an error |
| `neverEmits(matcher)` | Stream never emits a matching value |

---

## Configuration (dart_test.yaml)

### Full Reference

```yaml
# dart_test.yaml — place at the package root alongside pubspec.yaml

# Tags for categorizing tests
tags:
  unit:
  integration:
  golden:

# Default timeout for all tests
timeout: 2x

# Platforms to run tests on
platforms: [vm]

# Number of concurrent test suites
concurrency: 4

# Per-tag overrides
tag_overrides:
  integration:
    timeout: 4x
  golden:
    timeout: 3x

# File and folder-level overrides
override_platforms:
  chrome:
    settings:
      headless: true
```

### Using Tags

Define tag constants in a shared file:

```dart
// test/helpers/test_tags.dart
abstract class TestTag {
  static const unit = 'unit';
  static const integration = 'integration';
  static const golden = 'golden';
}
```

Apply tags to tests using the `@Tags` annotation:

```dart
@Tags([TestTag.integration])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connects to remote service', () async {
    // ...
  });
}
```

Or on individual tests:

```dart
test('renders correctly', tags: TestTag.golden, () {
  // ...
});
```

### Common Commands

| Command | Purpose |
| --- | --- |
| `dart test` | Run all Dart tests |
| `flutter test` | Run all Flutter tests |
| `dart test test/src/models/user_test.dart` | Run a specific test file |
| `dart test --name "returns"` | Filter tests by description substring |
| `dart test --tags unit` | Run only tests with the `unit` tag |
| `dart test --exclude-tags integration` | Skip integration-tagged tests |
| `flutter test --coverage` | Generate `coverage/lcov.info` |
| `dart test --test-randomize-ordering-seed random` | Randomize test execution order |
| `dart test --reporter expanded` | Verbose test output |

---

## Coverage

### Achieving Full Coverage

- Test **every public method** — including edge cases, error paths, and empty inputs
- Test **every branch** — `if`/`else`, `switch` cases, early returns, ternary operators
- Test **error paths** — `catch` blocks, `throwsA` assertions, error states
- Test **copyWith** — verify each field independently to cover every default branch
- Test **Equatable props** — ensure `==` and `hashCode` behave correctly (instances with same props are equal, different props are not)
- Test **toString** if overridden — assert the output string matches expectations

### Coverage-Driven Patterns

Testing `copyWith` for full branch coverage:

```dart
group('copyWith', () {
  test('returns same instance when no arguments are provided', () {
    const state = TodoListState(
      status: TodoListStatus.success,
      todos: [Todo(id: '1', title: 'Test')],
    );

    expect(state.copyWith(), equals(state));
  });

  test('returns updated status when status is provided', () {
    const state = TodoListState();

    final result = state.copyWith(status: TodoListStatus.loading);

    expect(result.status, equals(TodoListStatus.loading));
    expect(result.todos, equals(state.todos));
  });

  test('returns updated todos when todos is provided', () {
    const state = TodoListState();
    final todos = [Todo(id: '1', title: 'New')];

    final result = state.copyWith(todos: todos);

    expect(result.todos, equals(todos));
    expect(result.status, equals(state.status));
  });
});
```

---

## Quick Reference

### Packages

| Package | Purpose | Dev dependency? |
| --- | --- | --- |
| `test` | Core Dart test framework | Yes |
| `flutter_test` | Flutter test framework (includes `test`) | Yes (SDK) |
| `mocktail` | Mock creation and stubbing | Yes |
| `fake_async` | Control async execution (timers, microtasks) | Yes |
| `clock` | Injectable clock for time-dependent logic | No |
| `bloc_test` | Mock Blocs/Cubits for widget tests | Yes |

### Imports

| Import | When to use |
| --- | --- |
| `import 'package:test/test.dart';` | Pure Dart packages (no Flutter dependency) |
| `import 'package:flutter_test/flutter_test.dart';` | Flutter packages (re-exports `package:test`) |
| `import 'package:mocktail/mocktail.dart';` | Any test file that uses `Mock`, `Fake`, `when`, `verify` |
| `import '../helpers/helpers.dart';` | Every widget and golden test file — provides `pumpApp` and `TestTag` |
