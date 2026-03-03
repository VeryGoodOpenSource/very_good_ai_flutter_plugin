---
name: architecture
description: Best practices for Flutter/Dart project architecture. Use when structuring apps, defining layer boundaries, organizing features, setting up monorepos, or deciding when to extract packages.
---

# Architecture

Clean architecture principles for Flutter and Dart projects — layer separation, dependency rules, feature-first organization, monorepo structure, and package extraction.

---

## Standards (Non-Negotiable)

These constraints apply to ALL architecture decisions — no exceptions:

- **Separate every project into exactly three concerns: data packages, repositories, and presentation** — no additional layers, no skipping layers
- **Dependency rule: presentation depends on repositories; repositories depend on data packages; data packages depend on nothing**
- **Data packages are per data source type** — one package per external data source (e.g., `api_client` for a REST API, `geolocation_client` for platform geolocation, `local_storage_client` for a database)
- **Data packages export domain models and a typed client class** — JSON/SQL handling is internal
- **DTOs are internal to data packages** — never export them; consumers only see domain models
- **Use `package:bloc` / `package:flutter_bloc` for state management** — Blocs and Cubits are the standard
- **Repositories, design systems, and shared data concerns are modularized as independent packages under `packages/`**
- **Feature-first folder organization** — never layer-first (no global `blocs/`, `models/`, `widgets/` directories)
- **Every feature and package has a barrel file** exporting only its public API
- **Never import from `lib/src/` of another package** — only import from barrel exports
- **`very_good_analysis` for linting** in every package — include in `dev_dependencies` and `analysis_options.yaml`
- **100% test coverage** in every package — enforce with `very_good test --coverage --min-coverage 100`
- **One repository class per domain concern** — never combine unrelated domain logic into a single repository
- **Domain models are plain Dart classes** with no framework dependencies (no Flutter imports, no JSON annotations, no code generation)
- **`package:equatable` for value equality** on all domain models, entities, states, and events

---

## Dependency Rules

| Concern | Contains | Responsibility | Depends on |
| --- | --- | --- | --- |
| **Data package** | API client class, domain models, DTOs (internal) | Transforms raw data sources into typed Dart APIs; exports models + client | Nothing |
| **Repository** | Concrete repository class | Consumes data packages; applies business logic (caching, combining, error mapping) | Data packages |
| **Presentation** | Pages, Views, Widgets, Blocs/Cubits | Renders UI, delegates user actions to business logic | Repositories |

### What belongs where

| Artifact | Concern | Example |
| --- | --- | --- |
| API client | Data package | `class ApiClient` |
| Domain model | Data package (exported) | `class Todo extends Equatable` |
| DTO | Data package (internal) | `class TodoDto` — never exported |
| Repository | Repository | `class TodoRepository` |
| Bloc / Cubit | Presentation | `class TodosBloc extends Bloc<TodosEvent, TodosState>` |
| Page / View / Widget | Presentation | `class TodosPage extends StatelessWidget` |

The dependency rule is the most critical constraint. Violations create tight coupling and untestable code.

```
┌──────────────┐      ┌──────────────┐      ┌─────────────────────────┐
│ Presentation │ ───▶ │  Repository  │ ───▶ │      Data Package       │
│              │      │              │      │                         │
│ Blocs/Cubits │      │ Business     │      │ API client + Models     │
│ Pages/Views  │      │ logic        │      │ (DTOs internal)         │
└──────────────┘      └──────────────┘      └─────────────────────────┘
```

Repositories re-export domain models from data packages, so presentation never imports data packages directly.

### Data package — API client

The API client is the public surface of a data package. It takes transport-level dependencies (e.g., `http.Client`), internally handles JSON via DTOs, and returns typed domain models. Consumers never see DTOs or raw JSON.

```dart
/// Data package — typed API client. Consumers see only domain models.
/// A single ApiClient wraps the entire REST API; domain-level separation
/// happens at the repository layer.
class ApiClient {
  const ApiClient({
    required http.Client httpClient,
    required String baseUrl,
  })  : _httpClient = httpClient,
        _baseUrl = baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  Future<List<Todo>> getTodos() async {
    final response = await _httpClient.get(Uri.parse('$_baseUrl/todos'));
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((json) => TodoDto.fromJson(json as Map<String, dynamic>))
        .map((dto) => dto.toDomain())
        .toList();
  }

  Future<void> createTodo(Todo todo) async {
    await _httpClient.post(
      Uri.parse('$_baseUrl/todos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(TodoDto.fromDomain(todo).toJson()),
    );
  }

  Future<void> deleteTodo(String id) async {
    await _httpClient.delete(Uri.parse('$_baseUrl/todos/$id'));
  }
}
```

### Data package — domain model (exported)

Domain models live in the data package and are exported for consumers. Plain Dart classes with value equality — no framework dependencies, no JSON annotations.

```dart
/// Data package — domain model, exported for consumers.
class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final bool isCompleted;

  Todo copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object> get props => [id, title, isCompleted];
}
```

### Data package — DTO (internal)

DTOs handle serialization and convert to/from domain models. They are internal to the data package — never exported. Only the API client uses them.

```dart
/// Data package — internal DTO. Never exported.
class TodoDto {
  const TodoDto({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory TodoDto.fromJson(Map<String, dynamic> json) {
    return TodoDto(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool,
    );
  }

  factory TodoDto.fromDomain(Todo todo) {
    return TodoDto(
      id: todo.id,
      title: todo.title,
      isCompleted: todo.isCompleted,
    );
  }

  final String id;
  final String title;
  final bool isCompleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
    };
  }

  Todo toDomain() {
    return Todo(
      id: id,
      title: title,
      isCompleted: isCompleted,
    );
  }
}
```

### Repository — consumes typed data-package APIs

Repositories take data-package clients and apply business logic: caching, combining sources, error mapping. They never touch DTOs or JSON — data packages handle that.

```dart
import 'package:api_client/api_client.dart';

/// Repository — business logic over typed data-package APIs.
class TodoRepository {
  TodoRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;
  List<Todo>? _todosCache;

  Future<List<Todo>> getTodos({bool forceRefresh = false}) async {
    if (_todosCache != null && !forceRefresh) return _todosCache!;
    _todosCache = await _apiClient.getTodos();
    return _todosCache!;
  }

  Future<void> createTodo(Todo todo) async {
    await _apiClient.createTodo(todo);
    _todosCache = null;
  }

  Future<void> deleteTodo(String id) async {
    await _apiClient.deleteTodo(id);
    _todosCache = null;
  }
}
```

---

## Feature-First Folder Organization

Organize by feature, not by layer. Each feature is a self-contained directory with its own barrel file and tests.

### Single-Package App Structure

Data clients and repositories are always isolated packages under `packages/` — they never live inside feature folders in `lib/`. Features contain only presentation code: `bloc/`, `view/`, and `widgets/`.

```
my_project/
├── lib/
│   ├── app/
│   │   ├── app.dart                        # Barrel file
│   │   └── view/
│   │       └── app.dart                    # App widget, router, theme
│   ├── todos/
│   │   ├── todos.dart                      # Barrel file
│   │   ├── bloc/
│   │   │   ├── todos_bloc.dart
│   │   │   ├── todos_event.dart
│   │   │   └── todos_state.dart
│   │   ├── view/
│   │   │   ├── todos_page.dart             # Page provides Bloc
│   │   │   └── todos_view.dart             # View consumes Bloc
│   │   └── widgets/
│   │       └── todo_list_tile.dart
│   ├── auth/
│   │   ├── auth.dart                       # Barrel file
│   │   ├── bloc/
│   │   │   └── ...
│   │   └── view/
│   │       └── ...
│   ├── l10n/
│   │   ├── arb/
│   │   │   ├── app_en.arb
│   │   │   └── app_es.arb
│   │   └── l10n.dart
│   ├── main_development.dart
│   ├── main_staging.dart
│   └── main_production.dart
├── packages/
│   ├── api_client/                         # Data package — REST API
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── models/
│   │   │   │   │   ├── todo.dart           # Domain model (exported)
│   │   │   │   │   ├── todo_dto.dart       # DTO (internal)
│   │   │   │   │   ├── user.dart           # Domain model (exported)
│   │   │   │   │   └── user_dto.dart       # DTO (internal)
│   │   │   │   └── api_client.dart
│   │   │   └── api_client.dart             # Barrel file
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── todo_repository/                    # Repository — domain logic
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   └── todo_repository.dart    # (re-exports Todo from api_client)
│   │   │   └── todo_repository.dart        # Barrel file
│   │   ├── test/
│   │   └── pubspec.yaml
│   └── auth_repository/                    # Repository — domain logic
│       ├── lib/
│       │   ├── src/
│       │   │   └── auth_repository.dart    # (re-exports User from api_client)
│       │   └── auth_repository.dart        # Barrel file
│       ├── test/
│       └── pubspec.yaml
├── test/
│   ├── app/
│   │   └── view/
│   │       └── app_test.dart
│   ├── todos/
│   │   ├── bloc/
│   │   │   └── todos_bloc_test.dart
│   │   ├── view/
│   │   │   ├── todos_page_test.dart
│   │   │   └── todos_view_test.dart
│   │   └── widgets/
│   │       └── todo_list_tile_test.dart
│   └── auth/
│       └── ...
└── pubspec.yaml
```

Domain models always live in the data package — the data package is the single source of truth for both the typed API and its models. Repository tests live in the repository package under `packages/`, not in the app's `test/` directory.

### Anti-Pattern: Layer-First Organization

Never organize by layer at the top level:

```
# WRONG — layer-first organization
lib/
├── blocs/           # Global blocs directory
├── models/          # Global models directory
├── repositories/    # Global repositories directory
├── views/           # Global views directory
└── widgets/         # Global widgets directory
```

This creates artificial boundaries between related code. A change to a single feature touches every top-level directory, making navigation harder and coupling higher.

---

## When to Extract a Package

Extract code into a separate package when any of these conditions apply:

| Condition | Example |
| --- | --- |
| **2+ consumers** — multiple apps or packages need the same code | `app_ui` used by `app` and `admin_app` |
| **Testable in isolation** — the code has no dependency on the consuming app | `todo_repository` tested without Flutter |
| **Clear API boundary** — the public surface is well-defined | `api_client` with a single barrel export |
| **Independent versioning** — the code evolves on a different cadence | `analytics` package updated separately |
| **Distinct data source boundary** — the data source has its own schema, auth, or protocol | `api_client` wrapping a REST API |

In a monorepo, data packages, repositories, and UI packages are always extracted — they are shared concerns by definition and benefit from independent testing and versioning.

### Do not extract when

- Only one consumer exists and the code is unlikely to be reused
- The "package" would be fewer than 2-3 files with no meaningful API surface
- Extraction would create circular dependencies between packages

---

## Monorepo Structure

Use a monorepo when the project has multiple apps sharing code or when features grow large enough to warrant independent packages.

### Melos / Very Good CLI Layout

The app lives at the project root (`lib/`, `test/`, `pubspec.yaml`). Each data source type gets its own data package (e.g., `api_client` for the REST API, `geolocation_client` for platform geolocation) that exports a typed client class and domain models. Repository packages consume data packages and apply business logic. Design systems and other shared concerns are also modularized under `packages/`. Each package owns its tests, making them reusable across apps and testable in isolation.

```
my_project/
├── melos.yaml                          # Monorepo config
├── lib/                                # Main Flutter application
│   ├── app/
│   ├── todos/                         # bloc/, view/, widgets/
│   ├── auth/                          # bloc/, view/
│   ├── l10n/
│   ├── main_development.dart
│   ├── main_staging.dart
│   └── main_production.dart
├── test/
├── pubspec.yaml
├── packages/
│   ├── app_ui/                         # Design system
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── widgets/
│   │   │   │   ├── theme/
│   │   │   │   └── spacing/
│   │   │   └── app_ui.dart             # Barrel file
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── api_client/                     # Data package — REST API
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── models/
│   │   │   │   │   ├── todo.dart       # Domain model (exported)
│   │   │   │   │   ├── todo_dto.dart   # DTO (internal)
│   │   │   │   │   ├── user.dart       # Domain model (exported)
│   │   │   │   │   └── user_dto.dart   # DTO (internal)
│   │   │   │   └── api_client.dart
│   │   │   └── api_client.dart         # Barrel file
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── geolocation_client/             # Data package — platform geolocation
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── models/
│   │   │   │   │   └── position.dart   # Domain model (exported)
│   │   │   │   └── geolocation_client.dart
│   │   │   └── geolocation_client.dart # Barrel file
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── todo_repository/                # Repository — domain logic
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   └── todo_repository.dart  # (re-exports Todo from api_client)
│   │   │   └── todo_repository.dart    # Barrel file
│   │   ├── test/
│   │   └── pubspec.yaml
│   └── auth_repository/                # Repository — domain logic
│       ├── lib/
│       │   ├── src/
│       │   │   └── auth_repository.dart  # (re-exports User from api_client)
│       │   └── auth_repository.dart    # Barrel file
│       ├── test/
│       └── pubspec.yaml
```

For Melos configuration and scripts, see [reference.md](reference.md).

---

## Barrel Files

Every feature directory and every package has a barrel file that defines its public API.

### Rules

- Export only the types consumers need — hide implementation details
- Never re-export transitive dependencies (a barrel file must not export another package's types)
- Name the barrel file after the feature or package (`todos.dart`, `todo_repository.dart`)

### Feature barrel file

```dart
/// lib/todos/todos.dart
export 'bloc/todos_bloc.dart';
export 'view/todos_page.dart';
```

### Data package barrel file

```dart
/// lib/api_client.dart
export 'src/models/todo.dart';
export 'src/models/user.dart';
export 'src/api_client.dart';
// NOT exported: src/models/todo_dto.dart, src/models/user_dto.dart — DTOs are internal
```

### Repository package barrel file

```dart
/// lib/todo_repository.dart
export 'src/todo_repository.dart';
export 'package:api_client/api_client.dart' show Todo;
// Re-export domain models so consumers depend only on the repository package
```

### Anti-Pattern: Exporting everything

```dart
// WRONG — exposes implementation details
export 'bloc/todos_bloc.dart';
export 'bloc/todos_event.dart';              // Events are internal to the Bloc
export 'bloc/todos_state.dart';              // States are internal to the Bloc
export 'view/todos_page.dart';
export 'view/todos_view.dart';               // View is internal — only Page is public
export 'widgets/todo_list_tile.dart';        // Internal widget
```

DTOs, views, and internal widgets are implementation details — never export them. In a monorepo, API clients are also implementation details of their repository package.

---

## Dependency Injection

Provide dependencies from the top of the widget tree using constructor injection. Never use service locators or global singletons.

### Bloc — RepositoryProvider

```dart
import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_repository/todo_repository.dart';

class App extends StatelessWidget {
  const App({
    required TodoRepository todoRepository,
    required AuthRepository authRepository,
    super.key,
  })  : _todoRepository = todoRepository,
        _authRepository = authRepository;

  final TodoRepository _todoRepository;
  final AuthRepository _authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TodoRepository>.value(value: _todoRepository),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
      ],
      child: const AppView(),
    );
  }
}
```

Create data-package clients and repositories in `main`, then pass them to the `App` widget. `http.Client` can be shared — it's a transport detail.

```dart
import 'package:api_client/api_client.dart';
import 'package:auth_repository/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:todo_repository/todo_repository.dart';

import 'app/app.dart';

void main() {
  final httpClient = http.Client();
  final apiClient = ApiClient(
    httpClient: httpClient,
    baseUrl: 'https://api.example.com',
  );
  final todoRepository = TodoRepository(apiClient: apiClient);
  final authRepository = AuthRepository(apiClient: apiClient);

  runApp(
    App(
      todoRepository: todoRepository,
      authRepository: authRepository,
    ),
  );
}
```

---

## Quick Reference

| Package | Purpose |
| --- | --- |
| `very_good_cli` | Project scaffolding, templates, test runner, license checking |
| `melos` | Monorepo management — bootstrapping, scripting, versioning |
| `package:equatable` | Value equality for domain models, states, and events |
| `very_good_analysis` | Lint rules — include in every package |

---

## Additional Resources

See [reference.md](reference.md) for common workflows (adding a feature, extracting a shared package, setting up a monorepo), Melos configuration, and a consolidated anti-patterns reference.
