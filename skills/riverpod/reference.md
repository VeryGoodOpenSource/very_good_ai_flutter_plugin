# Riverpod — Reference

Extended examples, testing patterns, and common workflows for the Riverpod skill.

---

## Testing

### ProviderContainer Setup

Create a `ProviderContainer` with overrides for every unit test. Always dispose in `tearDown`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import 'package:my_app/todos/todos.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  group('TodosNotifier', () {
    late TodoRepository todoRepository;
    late ProviderContainer container;

    setUp(() {
      todoRepository = _MockTodoRepository();
      container = ProviderContainer(
        overrides: [
          todoRepositoryProvider.overrideWithValue(todoRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });
  });
}
```

### Testing AsyncNotifier build()

```dart
test('build returns list of todos', () async {
  when(() => todoRepository.getTodos())
      .thenAnswer((_) async => [Todo(id: '1', title: 'Test')]);

  // Trigger the build
  final future = container.read(todosNotifierProvider.future);

  final result = await future;

  expect(result, hasLength(1));
  expect(result.first.title, equals('Test'));
  verify(() => todoRepository.getTodos()).called(1);
});
```

### Testing Notifier Mutation Methods

```dart
test('addTodo calls repository and refreshes state', () async {
  when(() => todoRepository.getTodos())
      .thenAnswer((_) async => <Todo>[]);
  when(() => todoRepository.addTodo(any()))
      .thenAnswer((_) async {});

  // Wait for initial build
  await container.read(todosNotifierProvider.future);

  // Stub updated response
  when(() => todoRepository.getTodos())
      .thenAnswer((_) async => [Todo(id: '1', title: 'New')]);

  // Act
  await container
      .read(todosNotifierProvider.notifier)
      .addTodo(Todo(id: '1', title: 'New'));

  // Assert
  final state = container.read(todosNotifierProvider);
  expect(
    state,
    isA<AsyncData<List<Todo>>>()
        .having((s) => s.value, 'value', hasLength(1)),
  );
  verify(() => todoRepository.addTodo(any())).called(1);
});
```

### Testing Error States

```dart
test('build returns error when repository throws', () async {
  when(() => todoRepository.getTodos())
      .thenThrow(Exception('connection failed'));

  // Trigger the build
  await expectLater(
    container.read(todosNotifierProvider.future),
    throwsA(isA<Exception>()),
  );

  final state = container.read(todosNotifierProvider);
  expect(state, isA<AsyncError<List<Todo>>>());
});
```

### Widget Testing with ProviderScope Overrides

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_app/todos/todos.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late TodoRepository todoRepository;

  setUp(() {
    todoRepository = _MockTodoRepository();
  });

  group('TodosView', () {
    testWidgets('renders loading indicator initially', (tester) async {
      when(() => todoRepository.getTodos())
          .thenAnswer((_) async => <Todo>[]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todoRepositoryProvider.overrideWithValue(todoRepository),
          ],
          child: const MaterialApp(home: TodosView()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders todos when data is loaded', (tester) async {
      when(() => todoRepository.getTodos())
          .thenAnswer((_) async => [Todo(id: '1', title: 'Test Todo')]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todoRepositoryProvider.overrideWithValue(todoRepository),
          ],
          child: const MaterialApp(home: TodosView()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Todo'), findsOneWidget);
    });

    testWidgets('renders error message when loading fails', (tester) async {
      when(() => todoRepository.getTodos())
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todoRepositoryProvider.overrideWithValue(todoRepository),
          ],
          child: const MaterialApp(home: TodosView()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    });
  });
}
```

### Key Testing Rules

- **Always dispose `ProviderContainer`** in `tearDown` to prevent state leaks between tests
- **Override at the lowest dependency** — override the repository provider, not the notifier itself, to test real notifier logic
- **Use `.future`** to await `AsyncNotifier` build completion before asserting
- **Use `container.read(provider.notifier)`** to call mutation methods in tests
- **Private mocks per file** — declare `class _MockX extends Mock implements X {}` at file scope
- **Register fallback values** in `setUpAll` for custom types used with `any()`
- **One test per behavior** — test initial build, each mutation method, and each error path separately

---

## Common Patterns

### Adding a New Feature with Riverpod

1. Create feature directory: `lib/<feature>/`
2. Add barrel file: `lib/<feature>/<feature>.dart`
3. Define models: `lib/<feature>/models/` — plain Dart classes
4. Create repository: `lib/<feature>/data/<feature>_repository.dart` — plain Dart class, no `ref`
5. Create repository provider: `@riverpod` function that returns the repository instance
6. Implement notifier: `lib/<feature>/providers/<feature>_notifier.dart` — `@riverpod` `AsyncNotifier` with `build` + mutation methods
7. Create view: `lib/<feature>/view/<feature>_view.dart` — `ConsumerWidget` with `ref.watch`
8. Create page: `lib/<feature>/view/<feature>_page.dart` — navigation entry point
9. Run code generation: `dart run build_runner build --delete-conflicting-outputs`
10. Create test structure: mirror under `test/<feature>/`
11. Write provider tests with `ProviderContainer` overrides for every notifier method

### Combining Providers (Derived Data)

```dart
@riverpod
int completedTodoCount(Ref ref) {
  final todos = ref.watch(todosNotifierProvider).valueOrNull ?? [];
  return todos.where((t) => t.isCompleted).length;
}
```

### Error Handling with AsyncValue.guard

Standardize error handling in notifier methods — never use raw `try`/`catch`:

```dart
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<Profile> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    return repository.getProfile();
  }

  Future<void> updateName(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateName(name);
      return repository.getProfile();
    });
  }
}
```
