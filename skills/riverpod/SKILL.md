---
name: riverpod
description: Best practices for Riverpod state management and dependency injection in Flutter/Dart. Use when writing, modifying, or reviewing code that uses package:riverpod, package:flutter_riverpod, or package:riverpod_annotation.
---

# Riverpod

Reactive caching and data-binding framework providing compile-safe state management and dependency injection for Dart and Flutter applications.

## Standards (Non-Negotiable)

These constraints apply to ALL Riverpod work — no exceptions:

- **Use `@riverpod` code generation** — never manually declare providers with `Provider`, `StateProvider`, or `StateNotifierProvider`
- **Use `package:mocktail` for mocking** — never `package:mockito`
- **Use `ProviderContainer` with overrides** for all provider unit tests — never instantiate notifiers directly
- **No `ref` in repositories or data layer classes** — pass dependencies as constructor parameters; only provider functions receive `ref`
- **Feature-based folder organization** — providers live alongside their feature, not in a global `providers/` directory
- **Use `Notifier`/`AsyncNotifier`** — never `StateNotifier` or `ChangeNotifier` (legacy)
- **One provider per concern** — single responsibility; do not bundle unrelated state into one notifier
- **Always handle `AsyncValue` exhaustively** — pattern match with `when` or Dart 3 `switch` covering `AsyncData`, `AsyncLoading`, `AsyncError`
- **Use `ConsumerWidget`/`ConsumerStatefulWidget`** — never wrap the entire app in a `Consumer` builder

## Provider Types

### Code Generation Reference

| Annotation | Return type | Generated provider type | Stateful? |
| --- | --- | --- | --- |
| `@riverpod` on a function | `T` | Computed / auto-dispose provider | No |
| `@riverpod` on a function | `Future<T>` | `FutureProvider` (auto-dispose) | No |
| `@riverpod` on a function | `Stream<T>` | `StreamProvider` (auto-dispose) | No |
| `@riverpod` on a `Notifier` class | `T` | `NotifierProvider` (auto-dispose) | Yes |
| `@riverpod` on an `AsyncNotifier` class | `Future<T>` | `AsyncNotifierProvider` (auto-dispose) | Yes |

### Computed Value (Function Provider)

Use for derived or computed values with no mutable state.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filtered_todos.g.dart';

@riverpod
List<Todo> filteredTodos(Ref ref) {
  final todos = ref.watch(todosProvider);
  final filter = ref.watch(filterProvider);

  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.completed => todos.where((t) => t.isCompleted).toList(),
    TodoFilter.active => todos.where((t) => !t.isCompleted).toList(),
  };
}
```

### Future Provider

Use for asynchronous data that does not require mutation methods.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user.g.dart';

@riverpod
Future<User> currentUser(Ref ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUser();
}
```

### Stream Provider

Use for reactive streams from databases, web sockets, or repositories.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messages.g.dart';

@riverpod
Stream<List<Message>> messages(Ref ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchMessages();
}
```

### Notifier (Synchronous Stateful)

Use when you need mutable state with synchronous initialization.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
}
```

### AsyncNotifier (Asynchronous Stateful)

Use when you need mutable state with asynchronous initialization or mutation.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todos_notifier.g.dart';

@riverpod
class TodosNotifier extends _$TodosNotifier {
  @override
  Future<List<Todo>> build() async {
    final repository = ref.watch(todoRepositoryProvider);
    return repository.getTodos();
  }

  Future<void> addTodo(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.addTodo(todo);
      return repository.getTodos();
    });
  }

  Future<void> removeTodo(String id) async {
    final repository = ref.read(todoRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTodo(id);
      return repository.getTodos();
    });
  }
}
```

### Family Providers (Parameterized)

Add parameters to the `build` method for parameterized providers. Code generation handles family creation automatically.

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_detail.g.dart';

@riverpod
Future<User> userDetail(Ref ref, {required String userId}) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(userId);
}
```

Usage in widgets:

```dart
final user = ref.watch(userDetailProvider(userId: '123'));
```

## Naming Conventions

| Element | Convention | Example |
| --- | --- | --- |
| Provider function | camelCase, describes the data | `filteredTodos`, `currentUser` |
| Notifier class | PascalCase, `{Feature}{Purpose}` | `TodosNotifier`, `AuthController` |
| Generated provider variable | function/class name + `Provider` suffix | `filteredTodosProvider`, `todosNotifierProvider` |
| Notifier methods | verb-based, describes the action | `addTodo`, `removeTodo`, `signIn` |
| File name | snake_case, matches the provider/notifier | `filtered_todos.dart`, `todos_notifier.dart` |
| Generated file | same name with `.g.dart` suffix | `todos_notifier.g.dart` |

## Architecture

| Layer | Contains | Riverpod Role | Depends on |
| --- | --- | --- | --- |
| **Presentation** | Pages, Views, Widgets | `ConsumerWidget` reads providers via `ref` | Application |
| **Application** | Notifiers, Provider functions | `@riverpod` notifiers orchestrate use cases | Domain, Data |
| **Domain** | Models, Entities | Plain Dart classes — no Riverpod dependency | Nothing |
| **Data** | Repositories, API Clients | Plain Dart classes exposed via `@riverpod` functions | External sources |

### Data Layer

Repositories are plain Dart classes. Expose them to the provider graph via a function provider:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_repository.g.dart';

class TodoRepository {
  const TodoRepository({required TodoApiClient apiClient})
      : _apiClient = apiClient;

  final TodoApiClient _apiClient;

  Future<List<Todo>> getTodos() => _apiClient.fetchTodos();

  Future<void> addTodo(Todo todo) => _apiClient.createTodo(todo);

  Future<void> deleteTodo(String id) => _apiClient.deleteTodo(id);
}

@riverpod
TodoRepository todoRepository(Ref ref) {
  final apiClient = ref.watch(todoApiClientProvider);
  return TodoRepository(apiClient: apiClient);
}
```

### Feature Folder Structure

```
lib/
├── todos/
│   ├── todos.dart                    # Barrel file
│   ├── providers/
│   │   ├── todos_notifier.dart       # @riverpod AsyncNotifier
│   │   ├── todos_notifier.g.dart     # Generated
│   │   ├── filtered_todos.dart       # @riverpod computed provider
│   │   └── filtered_todos.g.dart     # Generated
│   ├── view/
│   │   ├── todos_page.dart           # ProviderScope / navigation entry
│   │   └── todos_view.dart           # ConsumerWidget with ref.watch
│   └── widgets/
│       └── todo_list_tile.dart
test/
├── todos/
│   ├── providers/
│   │   ├── todos_notifier_test.dart
│   │   └── filtered_todos_test.dart
│   ├── view/
│   │   ├── todos_page_test.dart
│   │   └── todos_view_test.dart
│   └── widgets/
│       └── todo_list_tile_test.dart
```

## Flutter Widgets & ref Usage

### Widget Types

| Widget | Purpose |
| --- | --- |
| `ConsumerWidget` | Stateless widget with access to `ref` |
| `ConsumerStatefulWidget` | Stateful widget with access to `ref` in `State` |
| `Consumer` | Builder widget for scoped `ref` access within a subtree |
| `ProviderScope` | Root widget that stores provider state — required at app root |

### ref Methods

| Method | Purpose | Rebuilds widget? |
| --- | --- | --- |
| `ref.watch(provider)` | Read value and rebuild when it changes | Yes |
| `ref.read(provider)` | One-time read without subscribing | No |
| `ref.listen(provider, callback)` | Execute side effects on change | No |
| `ref.watch(provider.select((s) => s.field))` | Rebuild only when selected field changes | Yes (selective) |

### Usage Rules

- Use `ref.watch` in `build` methods — this is the primary way to consume providers
- Use `ref.read` in callbacks (`onPressed`, `onTap`) — never in `build`
- Use `ref.listen` for side effects (navigation, snackbar) — call in `build` but does not trigger rebuilds
- Never store `ref` in a variable outside of `build` or `State` lifecycle

### ConsumerWidget Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodosView extends ConsumerWidget {
  const TodosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosNotifierProvider);

    ref.listen(todosNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: switch (todosAsync) {
        AsyncData(:final value) => ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) =>
                TodoListTile(todo: value[index]),
          ),
        AsyncError(:final error) =>
          Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(todosNotifierProvider.notifier).addTodo(
              Todo(id: UniqueKey().toString(), title: 'New Todo'),
            ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## AsyncValue Handling

### State Table

| Variant | Meaning | Properties |
| --- | --- | --- |
| `AsyncData<T>` | Data available | `value` |
| `AsyncLoading<T>` | Loading in progress | `value` (previous data, if any) |
| `AsyncError<T>` | Error occurred | `error`, `stackTrace`, `value` (previous data, if any) |

### Pattern Matching with Dart 3 switch

Always handle all three states exhaustively:

```dart
return switch (asyncValue) {
  AsyncData(:final value) => Text('Data: $value'),
  AsyncError(:final error) => Text('Error: $error'),
  _ => const CircularProgressIndicator(),
};
```

Or use the `when` method:

```dart
return asyncValue.when(
  data: (value) => Text('Data: $value'),
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => Text('Error: $error'),
);
```

### AsyncValue.guard

Use `AsyncValue.guard` in notifier methods to safely wrap async operations:

```dart
Future<void> refresh() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final repository = ref.read(todoRepositoryProvider);
    return repository.getTodos();
  });
}
```

`AsyncValue.guard` catches all exceptions and converts them to `AsyncError`, eliminating the need for manual `try`/`catch` in notifier methods.

## Lifecycle and Caching

### Auto-Dispose (Default)

Providers created with `@riverpod` are auto-disposed by default. When no widget watches a provider, its state is destroyed.

### Keep Alive

Use `@Riverpod(keepAlive: true)` for providers that must persist for the app's lifetime (e.g., authentication state, shared preferences):

```dart
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<AuthState> build() async {
    final token = await ref.watch(tokenStorageProvider).read();
    return token != null ? AuthState.authenticated(token) : const AuthState.unauthenticated();
  }
}
```

### Lifecycle Callbacks

| Callback | Fires when |
| --- | --- |
| `ref.onDispose(callback)` | Provider is about to be destroyed |
| `ref.onCancel(callback)` | Last listener unsubscribes (before auto-dispose timer) |
| `ref.onResume(callback)` | New listener subscribes after cancellation |

```dart
@riverpod
Stream<Position> location(Ref ref) {
  final controller = StreamController<Position>();

  ref.onDispose(controller.close);

  return controller.stream;
}
```

### Cache Invalidation

| Method | Behavior |
| --- | --- |
| `ref.invalidate(provider)` | Marks provider for rebuild on next read; does not return a value |
| `ref.refresh(provider)` | Invalidates and immediately rebuilds; returns the new value |

## Code Generation

### Commands

| Command | Purpose |
| --- | --- |
| `dart run build_runner build --delete-conflicting-outputs` | One-time generation |
| `dart run build_runner watch --delete-conflicting-outputs` | Watch mode — regenerates on file changes |

### Rules

- **Commit generated `*.g.dart` files** to version control — CI and teammates should not need to run `build_runner`
- **Add the `part` directive** at the top of every file that uses `@riverpod`: `part '<file_name>.g.dart';`
- **Run code generation after any provider change** — adding, removing, or modifying `@riverpod` annotations
- **Use `--delete-conflicting-outputs`** to prevent stale generated files from causing build errors

## Quick Reference

| Package | Purpose | Dev dependency? |
| --- | --- | --- |
| `flutter_riverpod` | Flutter widgets (`ProviderScope`, `ConsumerWidget`, etc.) | No |
| `riverpod_annotation` | `@riverpod` annotation and base classes | No |
| `riverpod` | Core Riverpod library (for non-Flutter Dart) | No |
| `riverpod_generator` | Code generator for `@riverpod` | Yes |
| `build_runner` | Runs code generators | Yes |
| `mocktail` | Mocking library for tests | Yes |

## Additional Resources

See [reference.md](reference.md) for detailed testing examples (ProviderContainer setup, AsyncNotifier tests, mutation method tests, error state tests, widget testing with ProviderScope overrides), common patterns (adding features, combining providers, error handling with AsyncValue.guard), and key testing rules.
