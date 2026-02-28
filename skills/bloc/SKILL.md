---
name: bloc
description: Best practices for Bloc state management in Flutter/Dart. Use when writing, modifying, or reviewing code that uses package:bloc, package:flutter_bloc, or package:bloc_test.
---

# Bloc

State management library for Dart and Flutter using the BLoC (Business Logic Component) pattern to separate business logic from the presentation layer.

---

## Standards (Non-Negotiable)

These constraints apply to ALL Bloc/Cubit work — no exceptions:

- **Use `blocTest()` from `package:bloc_test`** for all Bloc and Cubit tests — never raw `test()` with manual stream assertions
- **Use `package:mocktail` for mocking** — never `package:mockito`
- **No bloc-to-bloc direct dependencies** — blocs communicate through the UI or shared repositories
- **Page/View separation** — Page provides the Bloc/Cubit via `BlocProvider`, View consumes via `BlocBuilder`/`BlocListener`
- **Sealed classes for events and multi-state types** — enables exhaustive pattern matching with Dart 3 `switch`
- **Equatable for all states and events** — extend `Equatable` and override `props` for value equality
- **Business logic in Bloc/Cubit only** — never in widgets, pages, or views
- **Single responsibility** — one Bloc/Cubit per feature concern
- **Emit only after async checks** — use `emit` only inside the handler callback

---

## Cubit vs Bloc

| Aspect            | Cubit                          | Bloc                                    |
| ----------------- | ------------------------------ | --------------------------------------- |
| API               | Functions → `emit(state)`      | Events → `on<Event>` → `emit(state)`   |
| Complexity        | Low                            | Higher                                  |
| Traceability      | Less (no event log)            | Full (events + transitions)             |
| When to use       | Simple state, UI-driven logic  | Complex flows, event-driven, transforms |
| Testing           | Call methods, assert states    | Add events, assert states               |

### Cubit Example

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

### Bloc Example

```dart
sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object> get props => [];
}

final class CounterIncrementPressed extends CounterEvent {}
final class CounterDecrementPressed extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncrementPressed>((event, emit) => emit(state + 1));
    on<CounterDecrementPressed>((event, emit) => emit(state - 1));
  }
}
```

---

## Naming Conventions

### Events

**Pattern:** `BlocSubject` + `Noun` + `VerbPastTense`

| Event class name              | Meaning                          |
| ----------------------------- | -------------------------------- |
| `TodoListSubscriptionRequested` | Subscribing to todo list stream |
| `TodoListTodoDeleted`         | Deleting a specific todo         |
| `TodoListUndoDeletionRequested` | Undoing the last deletion      |
| `LoginFormSubmitted`          | Submitting the login form        |
| `ProfilePageRefreshed`        | Refreshing the profile page      |

```dart
sealed class TodoListEvent extends Equatable {
  const TodoListEvent();

  @override
  List<Object> get props => [];
}

final class TodoListSubscriptionRequested extends TodoListEvent {}

final class TodoListTodoDeleted extends TodoListEvent {
  const TodoListTodoDeleted({required this.todo});

  final Todo todo;

  @override
  List<Object> get props => [todo];
}
```

### States

#### Subclass Approach (multiple state types)

Use when each state carries different data.

| State class name              | Meaning                          |
| ----------------------------- | -------------------------------- |
| `LoginInitial`                | No action taken yet              |
| `LoginInProgress`             | Login request in flight          |
| `LoginSuccess`                | Login succeeded                  |
| `LoginFailure`                | Login failed                     |

```dart
sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

final class LoginInitial extends LoginState {}
final class LoginInProgress extends LoginState {}
final class LoginSuccess extends LoginState {
  const LoginSuccess({required this.user});

  final User user;

  @override
  List<Object> get props => [user];
}
final class LoginFailure extends LoginState {
  const LoginFailure({required this.error});

  final String error;

  @override
  List<Object> get props => [error];
}
```

#### Single Class Approach (one state, multiple fields)

Use when all states share the same data shape.

| Field         | Type                | Purpose                        |
| ------------- | ------------------- | ------------------------------ |
| `status`      | `enum`              | Current loading status         |
| `items`       | `List<Item>`        | Loaded data                    |
| `error`       | `String?`           | Error message if failed        |

```dart
enum TodoListStatus { initial, loading, success, failure }

class TodoListState extends Equatable {
  const TodoListState({
    this.status = TodoListStatus.initial,
    this.todos = const [],
    this.error,
  });

  final TodoListStatus status;
  final List<Todo> todos;
  final String? error;

  TodoListState copyWith({
    TodoListStatus? status,
    List<Todo>? todos,
    String? error,
  }) {
    return TodoListState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, todos, error];
}
```

---

## Architecture

| Layer              | Contains                           | Depends on          |
| ------------------ | ---------------------------------- | ------------------- |
| **Presentation**   | Pages, Views, Widgets              | Business Logic      |
| **Business Logic** | Blocs, Cubits                      | Data                |
| **Data**           | Repositories, Data Providers       | External sources    |

### Data Layer

Repositories abstract data sources and provide a clean API for Blocs/Cubits.

```dart
class TodoRepository {
  const TodoRepository({required TodoApiClient apiClient})
      : _apiClient = apiClient;

  final TodoApiClient _apiClient;

  Future<List<Todo>> getTodos() => _apiClient.fetchTodos();

  Future<void> addTodo(Todo todo) => _apiClient.createTodo(todo);

  Future<void> deleteTodo(String id) => _apiClient.deleteTodo(id);
}
```

### Feature Folder Structure

```
lib/
├── todos/
│   ├── todos.dart                  # Barrel file
│   ├── bloc/
│   │   ├── todos_bloc.dart
│   │   ├── todos_event.dart
│   │   └── todos_state.dart
│   ├── view/
│   │   ├── todos_page.dart         # Provides Bloc via BlocProvider
│   │   └── todos_view.dart         # Consumes Bloc via BlocBuilder
│   └── widgets/
│       └── todo_list_tile.dart
test/
├── todos/
│   ├── bloc/
│   │   └── todos_bloc_test.dart
│   ├── view/
│   │   ├── todos_page_test.dart
│   │   └── todos_view_test.dart
│   └── widgets/
│       └── todo_list_tile_test.dart
```

---

## Flutter Widgets

| Widget              | Purpose                                                    |
| ------------------- | ---------------------------------------------------------- |
| `BlocProvider`      | Creates and provides a Bloc/Cubit to the subtree           |
| `BlocBuilder`       | Rebuilds widget when state changes                         |
| `BlocListener`      | Executes side effects (navigation, snackbar) on state change |
| `BlocConsumer`      | Combines `BlocBuilder` + `BlocListener`                    |
| `BlocSelector`      | Rebuilds only when a selected property changes             |
| `MultiBlocProvider` | Provides multiple Blocs/Cubits without nesting             |
| `MultiBlocListener` | Registers multiple listeners without nesting               |
| `RepositoryProvider`| Provides a repository to the subtree                       |

### Context Extensions

| Extension          | Purpose                                          | Rebuilds? |
| ------------------ | ------------------------------------------------ | --------- |
| `context.read<T>()`   | Access Bloc/Cubit instance (one-time read)   | No        |
| `context.watch<T>()`  | Access Bloc/Cubit and subscribe to changes   | Yes       |
| `context.select<T, R>()` | Subscribe to a specific state property    | Yes (selective) |

- Use `context.read` in callbacks (`onPressed`, `onTap`, `initState`)
- Use `context.watch` or `BlocBuilder` in `build` methods
- Never use `context.watch` outside of `build`

### Page/View Pattern

```dart
class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const TodosPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodosBloc(
        todoRepository: context.read<TodoRepository>(),
      )..add(const TodosSubscriptionRequested()),
      child: const TodosView(),
    );
  }
}

class TodosView extends StatelessWidget {
  const TodosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: BlocBuilder<TodosBloc, TodosState>(
        builder: (context, state) {
          return switch (state.status) {
            TodosStatus.initial || TodosStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            TodosStatus.success =>
              ListView.builder(
                itemCount: state.todos.length,
                itemBuilder: (context, index) =>
                    TodoListTile(todo: state.todos[index]),
              ),
            TodosStatus.failure =>
              Center(child: Text('Error: ${state.error}')),
          };
        },
      ),
    );
  }
}
```

### BlocListener for Side Effects

```dart
BlocListener<LoginBloc, LoginState>(
  listener: (context, state) {
    if (state is LoginFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error)),
      );
    }
    if (state is LoginSuccess) {
      Navigator.of(context).pushReplacement(HomePage.route());
    }
  },
  child: const LoginForm(),
)
```

---

## Additional Resources

See [reference.md](reference.md) for detailed testing examples (`blocTest()` parameters, Cubit/Bloc test examples, mocking dependencies, widget integration tests), common patterns (adding features with Bloc/Cubit, async operations, event transformers), and the package quick reference.
