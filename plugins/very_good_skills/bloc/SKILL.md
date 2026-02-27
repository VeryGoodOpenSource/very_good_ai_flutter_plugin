---
name: bloc
description: Best practices when working the the Bloc state management solution, as well as testing.
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

## Testing

### `blocTest()` Parameters

| Parameter  | Type                        | Purpose                                        |
| ---------- | --------------------------- | ---------------------------------------------- |
| `build`    | `() => Bloc/Cubit`         | Creates the Bloc/Cubit under test              |
| `act`      | `(bloc) => void`           | Interacts with the Bloc/Cubit                  |
| `expect`   | `() => List<State>`        | Expected states emitted (in order)             |
| `seed`     | `() => State`              | Initial state before `act`                     |
| `setUp`    | `() => void`               | Runs before `build`                            |
| `verify`   | `(bloc) => void`           | Additional verifications after `expect`        |
| `errors`   | `() => List<Matcher>`      | Expected errors thrown                         |
| `wait`     | `Duration`                 | Wait duration before asserting (for debounce)  |

### Cubit Test Example

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/counter/counter.dart';

void main() {
  group('CounterCubit', () {
    test('initial state is 0', () {
      expect(CounterCubit().state, equals(0));
    });

    blocTest<CounterCubit, int>(
      'emits [1] when increment is called',
      build: CounterCubit.new,
      act: (cubit) => cubit.increment(),
      expect: () => [1],
    );

    blocTest<CounterCubit, int>(
      'emits [2] when increment is called from 1',
      build: CounterCubit.new,
      seed: () => 1,
      act: (cubit) => cubit.increment(),
      expect: () => [2],
    );
  });
}
```

### Bloc Test Example

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_app/todos/todos.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late TodoRepository todoRepository;

  setUp(() {
    todoRepository = MockTodoRepository();
  });

  group('TodosBloc', () {
    blocTest<TodosBloc, TodosState>(
      'emits [loading, success] when subscription is requested',
      setUp: () {
        when(() => todoRepository.getTodos())
            .thenAnswer((_) async => [Todo(id: '1', title: 'Test')]);
      },
      build: () => TodosBloc(todoRepository: todoRepository),
      act: (bloc) => bloc.add(const TodosSubscriptionRequested()),
      expect: () => [
        const TodosState(status: TodosStatus.loading),
        isA<TodosState>()
            .having((s) => s.status, 'status', TodosStatus.success)
            .having((s) => s.todos, 'todos', hasLength(1)),
      ],
      verify: (_) {
        verify(() => todoRepository.getTodos()).called(1);
      },
    );

    blocTest<TodosBloc, TodosState>(
      'emits [loading, failure] when repository throws',
      setUp: () {
        when(() => todoRepository.getTodos()).thenThrow(Exception('oops'));
      },
      build: () => TodosBloc(todoRepository: todoRepository),
      act: (bloc) => bloc.add(const TodosSubscriptionRequested()),
      expect: () => [
        const TodosState(status: TodosStatus.loading),
        isA<TodosState>()
            .having((s) => s.status, 'status', TodosStatus.failure),
      ],
    );
  });
}
```

### Mocking Dependencies

```dart
import 'package:mocktail/mocktail.dart';

// Create mock
class MockTodoRepository extends Mock implements TodoRepository {}

// Stub methods
when(() => repository.getTodos()).thenAnswer((_) async => []);
when(() => repository.addTodo(any())).thenAnswer((_) async {});

// Verify calls
verify(() => repository.getTodos()).called(1);
verifyNever(() => repository.deleteTodo(any()));

// Register fallback for custom types
setUpAll(() {
  registerFallbackValue(Todo(id: '', title: ''));
});
```

### Testing Widget Integration

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_app/todos/todos.dart';

class MockTodosBloc extends MockBloc<TodosEvent, TodosState>
    implements TodosBloc {}

void main() {
  late TodosBloc todosBloc;

  setUp(() {
    todosBloc = MockTodosBloc();
  });

  group('TodosView', () {
    testWidgets('renders loading indicator when status is loading',
        (tester) async {
      when(() => todosBloc.state).thenReturn(
        const TodosState(status: TodosStatus.loading),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: todosBloc,
            child: const TodosView(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders todos when status is success', (tester) async {
      final todos = [Todo(id: '1', title: 'Test Todo')];
      when(() => todosBloc.state).thenReturn(
        TodosState(status: TodosStatus.success, todos: todos),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: todosBloc,
            child: const TodosView(),
          ),
        ),
      );

      expect(find.text('Test Todo'), findsOneWidget);
    });
  });
}
```

---

## Common Patterns

### Adding a New Feature with Bloc

1. Create feature directory: `lib/<feature>/`
2. Add barrel file: `lib/<feature>/<feature>.dart`
3. Define events: `lib/<feature>/bloc/<feature>_event.dart` — sealed class with event subclasses
4. Define state: `lib/<feature>/bloc/<feature>_state.dart` — sealed or single class with Equatable
5. Implement Bloc: `lib/<feature>/bloc/<feature>_bloc.dart` — register event handlers, inject repository
6. Create page: `lib/<feature>/view/<feature>_page.dart` — provides Bloc via `BlocProvider`
7. Create view: `lib/<feature>/view/<feature>_view.dart` — consumes state via `BlocBuilder`
8. Create test structure: mirror under `test/<feature>/`
9. Write `blocTest` for every event handler and state transition

### Adding a New Feature with Cubit

1. Create feature directory: `lib/<feature>/`
2. Add barrel file: `lib/<feature>/<feature>.dart`
3. Define state: `lib/<feature>/cubit/<feature>_state.dart`
4. Implement Cubit: `lib/<feature>/cubit/<feature>_cubit.dart` — public methods that `emit`
5. Create page and view with `BlocProvider` / `BlocBuilder`
6. Create test structure: mirror under `test/<feature>/`
7. Write `blocTest` for every public method

### Handling Async Operations

```dart
Future<void> _onDataRequested(
  DataRequested event,
  Emitter<DataState> emit,
) async {
  emit(state.copyWith(status: DataStatus.loading));
  try {
    final data = await _repository.fetchData();
    emit(state.copyWith(status: DataStatus.success, data: data));
  } catch (error, stackTrace) {
    addError(error, stackTrace);
    emit(state.copyWith(status: DataStatus.failure, error: '$error'));
  }
}
```

### Event Transformers

Use `package:bloc_concurrency` for controlling event processing:

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchRepository repository})
      : _repository = repository,
        super(const SearchState()) {
    on<SearchTermChanged>(
      _onSearchTermChanged,
      transformer: restartable(),  // Cancels in-flight when new event arrives
    );
  }
}
```

| Transformer       | Behavior                                              |
| ------------------ | ---------------------------------------------------- |
| `concurrent()`    | Process all events concurrently (default)             |
| `sequential()`    | Process events one at a time in order                 |
| `droppable()`     | Ignore new events while one is processing             |
| `restartable()`   | Cancel current processing, start new event            |

---

## Quick Reference

| Package              | Purpose                                | Dev dependency? |
| -------------------- | -------------------------------------- | --------------- |
| `flutter_bloc`       | Flutter widgets (`BlocProvider`, etc.) | No              |
| `bloc`               | Core Bloc/Cubit classes                | No              |
| `equatable`          | Value equality for states/events       | No              |
| `bloc_test`          | `blocTest()` helper                    | Yes             |
| `mocktail`           | Mocking library                        | Yes             |
| `bloc_concurrency`   | Event transformers (debounce, etc.)    | No              |
