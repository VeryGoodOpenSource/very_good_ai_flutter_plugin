# Layered Architecture — Reference

Extended examples, full pubspec files, testing patterns, and model transformation recipes.

---

## Complete Worked Example

End-to-end "user profile" feature across all four layers.

### Data Layer: `user_api_client` Package

**`packages/user_api_client/pubspec.yaml`**

```yaml
name: user_api_client
description: HTTP client for the User API.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  http: ^1.4.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.9.0
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

**`packages/user_api_client/lib/user_api_client.dart`**

```dart
/// HTTP client for the User API.
library;

export 'src/models/models.dart';
export 'src/user_api_client.dart';
```

**`packages/user_api_client/lib/src/models/models.dart`**

```dart
export 'user_response.dart';
```

**`packages/user_api_client/lib/src/models/user_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserResponse {
  const UserResponse({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  final String id;
  final String email;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}
```

**`packages/user_api_client/lib/src/user_api_client.dart`**

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:user_api_client/user_api_client.dart';

/// Exception thrown when a user API request fails.
class UserApiException implements Exception {
  const UserApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

/// HTTP client for the User API.
class UserApiClient {
  UserApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  /// Fetches the user with the given [userId].
  Future<UserResponse> getUser(String userId) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/users/$userId'),
    );

    if (response.statusCode != 200) {
      throw UserApiException(response.statusCode, response.body);
    }

    return UserResponse.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
```

### Data Layer: `local_storage_client` Package

**`packages/local_storage_client/pubspec.yaml`**

```yaml
name: local_storage_client
description: Client for local key-value storage.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  shared_preferences: ^2.5.0

dev_dependencies:
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

**`packages/local_storage_client/lib/local_storage_client.dart`**

```dart
/// Client for local key-value storage.
library;

export 'src/local_storage_client.dart';
```

**`packages/local_storage_client/lib/src/local_storage_client.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Client for local key-value storage.
class LocalStorageClient {
  LocalStorageClient({
    required SharedPreferences sharedPreferences,
  }) : _sharedPreferences = sharedPreferences;

  final SharedPreferences _sharedPreferences;

  /// Reads the string value for the given [key].
  String? read(String key) => _sharedPreferences.getString(key);

  /// Writes a string [value] for the given [key].
  Future<void> write(String key, String value) async {
    await _sharedPreferences.setString(key, value);
  }

  /// Removes the value for the given [key].
  Future<void> delete(String key) async {
    await _sharedPreferences.remove(key);
  }
}
```

### Repository Layer: `user_repository` Package

**`packages/user_repository/pubspec.yaml`**

```yaml
name: user_repository
description: Repository for user data.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  equatable: ^2.0.7
  local_storage_client:
    path: ../local_storage_client
  user_api_client:
    path: ../user_api_client

dev_dependencies:
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

**`packages/user_repository/lib/user_repository.dart`**

```dart
/// Repository for user data.
library;

export 'src/models/models.dart';
export 'src/user_repository.dart';
```

**`packages/user_repository/lib/src/models/models.dart`**

```dart
export 'user.dart';
```

**`packages/user_repository/lib/src/models/user.dart`**

```dart
import 'package:equatable/equatable.dart';

/// Domain model representing a user.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
```

**`packages/user_repository/lib/src/user_repository.dart`**

```dart
import 'package:user_api_client/user_api_client.dart';
import 'package:user_repository/user_repository.dart';

/// Exception thrown when a user is not found.
class UserNotFoundException implements Exception {
  const UserNotFoundException(this.userId);

  final String userId;
}

/// Repository for user data.
///
/// Combines [UserApiClient] with local caching to provide
/// user data to the business logic layer.
class UserRepository {
  const UserRepository({
    required UserApiClient userApiClient,
  }) : _userApiClient = userApiClient;

  final UserApiClient _userApiClient;

  /// Returns the [User] with the given [userId].
  ///
  /// Throws [UserNotFoundException] if the user is not found.
  Future<User> getUser(String userId) async {
    try {
      final response = await _userApiClient.getUser(userId);
      return User(
        id: response.id,
        email: response.email,
        displayName: response.displayName,
        avatarUrl: response.avatarUrl,
      );
    } on UserApiException catch (e) {
      if (e.statusCode == 404) {
        throw UserNotFoundException(userId);
      }
      rethrow;
    }
  }
}
```

### Business Logic Layer: `ProfileBloc`

**`lib/profile/bloc/profile_event.dart`**

```dart
part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

final class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object> get props => [userId];
}
```

**`lib/profile/bloc/profile_state.dart`**

```dart
part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileSuccess extends ProfileState {
  const ProfileSuccess({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

final class ProfileNotFound extends ProfileState {
  const ProfileNotFound();
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure();
}
```

**`lib/profile/bloc/profile_bloc.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required UserRepository userRepository,
  })  : _userRepository = userRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
  }

  final UserRepository _userRepository;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final user = await _userRepository.getUser(event.userId);
      emit(ProfileSuccess(user: user));
    } on UserNotFoundException {
      emit(const ProfileNotFound());
    } catch (_) {
      emit(const ProfileFailure());
    }
  }
}
```

### Presentation Layer: Page and View

**`lib/profile/view/profile_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/profile/bloc/profile_bloc.dart';
import 'package:my_app/profile/view/profile_view.dart';
import 'package:user_repository/user_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        userRepository: context.read<UserRepository>(),
      )..add(ProfileLoadRequested(userId: userId)),
      child: const ProfileView(),
    );
  }
}
```

**`lib/profile/view/profile_view.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/profile/bloc/profile_bloc.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() => const SizedBox.shrink(),
            ProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ProfileSuccess(:final user) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(user.email),
                  ],
                ),
              ),
            ProfileNotFound() => const Center(
                child: Text('User not found'),
              ),
            ProfileFailure() => const Center(
                child: Text('Something went wrong'),
              ),
          };
        },
      ),
    );
  }
}
```

### Bootstrap Wiring

**`lib/main_development.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:user_api_client/user_api_client.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.dev.example.com';

  final userApiClient = UserApiClient(baseUrl: baseUrl);
  final userRepository = UserRepository(userApiClient: userApiClient);

  runApp(
    App(userRepository: userRepository),
  );
}
```

**`lib/app/view/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

class App extends StatelessWidget {
  const App({
    required this.userRepository,
    super.key,
  });

  final UserRepository userRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: userRepository,
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }
}
```

---

## Data Flow Walkthrough

Step-by-step code walkthrough: user taps "Load Profile" button.

**Step 1 — Presentation dispatches event:**

```dart
// lib/profile/view/profile_view.dart
ElevatedButton(
  onPressed: () {
    context.read<ProfileBloc>().add(
      const ProfileLoadRequested(userId: '123'),
    );
  },
  child: const Text('Load Profile'),
)
```

**Step 2 — Business Logic calls repository:**

```dart
// lib/profile/bloc/profile_bloc.dart
Future<void> _onLoadRequested(
  ProfileLoadRequested event,
  Emitter<ProfileState> emit,
) async {
  emit(const ProfileLoading());
  try {
    final user = await _userRepository.getUser(event.userId);
    emit(ProfileSuccess(user: user));
  } on UserNotFoundException {
    emit(const ProfileNotFound());
  } catch (_) {
    emit(const ProfileFailure());
  }
}
```

**Step 3 — Repository calls data client:**

```dart
// packages/user_repository/lib/src/user_repository.dart
Future<User> getUser(String userId) async {
  final response = await _userApiClient.getUser(userId);
  return User(
    id: response.id,
    email: response.email,
    displayName: response.displayName,
    avatarUrl: response.avatarUrl,
  );
}
```

**Step 4 — Data layer communicates with external source:**

```dart
// packages/user_api_client/lib/src/user_api_client.dart
Future<UserResponse> getUser(String userId) async {
  final response = await _httpClient.get(
    Uri.parse('$_baseUrl/users/$userId'),
  );

  if (response.statusCode != 200) {
    throw UserApiException(response.statusCode, response.body);
  }

  return UserResponse.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}
```

**Step 5 — Data flows back up — Presentation rebuilds:**

```dart
// lib/profile/view/profile_view.dart
BlocBuilder<ProfileBloc, ProfileState>(
  builder: (context, state) {
    return switch (state) {
      ProfileInitial() => const SizedBox.shrink(),
      ProfileLoading() => const CircularProgressIndicator(),
      ProfileSuccess(:final user) => ProfileContent(user: user),
      ProfileNotFound() => const Text('User not found'),
      ProfileFailure() => const Text('Something went wrong'),
    };
  },
)
```

---

## Package-Level Testing

### Testing a Data Client

Mock the HTTP client and verify request/response handling.

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_api_client/user_api_client.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  group(UserApiClient, () {
    late http.Client httpClient;
    late UserApiClient subject;

    setUp(() {
      httpClient = _MockHttpClient();
      subject = UserApiClient(
        baseUrl: 'https://api.test.com',
        httpClient: httpClient,
      );
    });

    group('getUser', () {
      test('returns $UserResponse when status is 200', () async {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response(
            json.encode({
              'id': '1',
              'email': 'dash@example.com',
              'display_name': 'Dash',
              'avatar_url': null,
            }),
            200,
          ),
        );

        final result = await subject.getUser('1');

        expect(
          result,
          isA<UserResponse>()
              .having((r) => r.id, 'id', '1')
              .having((r) => r.email, 'email', 'dash@example.com')
              .having((r) => r.displayName, 'displayName', 'Dash'),
        );

        verify(
          () => httpClient.get(Uri.parse('https://api.test.com/users/1')),
        ).called(1);
      });

      test('throws $UserApiException when status is not 200', () {
        when(() => httpClient.get(any())).thenAnswer(
          (_) async => http.Response('Not found', 404),
        );

        expect(
          () => subject.getUser('1'),
          throwsA(
            isA<UserApiException>()
                .having((e) => e.statusCode, 'statusCode', 404),
          ),
        );
      });
    });
  });
}
```

### Testing a Repository

Mock the data client and verify domain model transformation.

```dart
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_api_client/user_api_client.dart';
import 'package:user_repository/user_repository.dart';

class _MockUserApiClient extends Mock implements UserApiClient {}

void main() {
  group(UserRepository, () {
    late UserApiClient userApiClient;
    late UserRepository subject;

    setUp(() {
      userApiClient = _MockUserApiClient();
      subject = UserRepository(userApiClient: userApiClient);
    });

    group('getUser', () {
      const userId = '1';
      final userResponse = UserResponse(
        id: userId,
        email: 'dash@example.com',
        displayName: 'Dash',
      );

      test('returns $User when API call succeeds', () async {
        when(() => userApiClient.getUser(userId))
            .thenAnswer((_) async => userResponse);

        final result = await subject.getUser(userId);

        expect(
          result,
          equals(
            const User(
              id: userId,
              email: 'dash@example.com',
              displayName: 'Dash',
            ),
          ),
        );
      });

      test('throws $UserNotFoundException when API returns 404', () {
        when(() => userApiClient.getUser(userId)).thenThrow(
          const UserApiException(404, 'Not found'),
        );

        expect(
          () => subject.getUser(userId),
          throwsA(isA<UserNotFoundException>()),
        );
      });

      test('rethrows $UserApiException for non-404 errors', () {
        when(() => userApiClient.getUser(userId)).thenThrow(
          const UserApiException(500, 'Server error'),
        );

        expect(
          () => subject.getUser(userId),
          throwsA(
            isA<UserApiException>()
                .having((e) => e.statusCode, 'statusCode', 500),
          ),
        );
      });
    });
  });
}
```

### Running Tests Recursively

From the monorepo root, test all packages at once:

```bash
very_good test -r --min-coverage 100
```

This recursively finds and runs tests in every package (data clients, repositories, and the root app).

### Key Testing Rules

- **Test each layer in isolation** — data client tests mock the HTTP client, repository tests mock the data client, Bloc tests mock the repository
- **Mock only the immediate dependency** — never mock two layers deep (e.g., don't mock the HTTP client when testing a repository)
- **Test model transformations explicitly** — verify that `User.fromResponse` (or equivalent) correctly maps every field, including nullable fields and edge cases
- **Mirror `lib/` structure in `test/`** — `packages/user_api_client/lib/src/user_api_client.dart` → `packages/user_api_client/test/src/user_api_client_test.dart`

### Testing Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Testing repository with a real HTTP client | Crosses layer boundary — test becomes slow, flaky, and tests two layers at once | Mock the data client (`_MockUserApiClient`) and test repository logic only |
| Mocking two layers deep | Repository test mocks `http.Client` instead of `UserApiClient` — tightly couples test to data layer internals | Each test mocks only its direct dependency |
| Skipping model transformation tests | `User.fromResponse` bugs go undetected — wrong fields mapped, nulls mishandled | Write explicit tests for every factory/transformation method |
| Sharing mutable test state across packages | Global variables or static mocks leak between test files — causes intermittent failures | Use `late` + `setUp` in every test group for fresh instances |

---

## pubspec.yaml Reference

### Data Package

```yaml
name: weather_api_client
description: HTTP client for the Weather API.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  http: ^1.4.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.9.0
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

### Repository Package

```yaml
name: weather_repository
description: Repository for weather data.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0

dependencies:
  equatable: ^2.0.7
  weather_api_client:
    path: ../weather_api_client

dev_dependencies:
  mocktail: ^1.0.0
  test: ^1.25.0
  very_good_analysis: ^7.0.0
```

### Root App

```yaml
name: my_app
description: A Very Good App.
version: 1.0.0+1
publish_to: none

environment:
  sdk: ^3.11.0
  flutter: ^3.29.0

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.0
  auth_repository:
    path: packages/auth_repository
  user_repository:
    path: packages/user_repository
  weather_repository:
    path: packages/weather_repository

dev_dependencies:
  bloc_test: ^9.1.0
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  very_good_analysis: ^7.0.0

flutter:
  uses-material-design: true
```

### Shared Flutter Package

Used for shared widgets or themes that depend on the Flutter SDK.

```yaml
name: app_ui
description: Shared UI components and theme for the app.
version: 0.1.0+1
publish_to: none

environment:
  sdk: ^3.11.0
  flutter: ^3.29.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^7.0.0
```

---

## Model Transformation Patterns

### Data Model vs Domain Model

Data models (response models) reflect the external API shape. Domain models reflect the app's internal representation. The repository layer transforms between them.

```
API JSON → UserResponse (data model) → User (domain model)
```

### Factory Constructor Pattern

Add a named factory on the domain model to transform from the response model:

```dart
import 'package:equatable/equatable.dart';
import 'package:user_api_client/user_api_client.dart' show UserResponse;

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  /// Creates a [User] from a [UserResponse].
  factory User.fromResponse(UserResponse response) {
    return User(
      id: response.id,
      email: response.email,
      displayName: response.displayName,
      avatarUrl: response.avatarUrl,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
```

Usage in the repository:

```dart
Future<User> getUser(String userId) async {
  final response = await _userApiClient.getUser(userId);
  return User.fromResponse(response);
}
```

### Handling Nullable Fields

When the API returns fields that are optional or may change shape:

```dart
factory User.fromResponse(UserResponse response) {
  return User(
    id: response.id,
    email: response.email,
    // Default when the API field is missing
    displayName: response.displayName ?? 'Unknown',
    // Nullable fields pass through
    avatarUrl: response.avatarUrl,
  );
}
```

### Combining Multiple Data Sources

When a domain model requires data from more than one client:

```dart
class UserRepository {
  const UserRepository({
    required UserApiClient userApiClient,
    required LocalStorageClient localStorageClient,
  })  : _userApiClient = userApiClient,
        _localStorageClient = localStorageClient;

  final UserApiClient _userApiClient;
  final LocalStorageClient _localStorageClient;

  Future<User> getUser(String userId) async {
    final response = await _userApiClient.getUser(userId);
    final cachedNickname = _localStorageClient.read('nickname_$userId');

    return User(
      id: response.id,
      email: response.email,
      displayName: cachedNickname ?? response.displayName,
      avatarUrl: response.avatarUrl,
    );
  }
}
```

### Testing Model Transformations

```dart
group('User.fromResponse', () {
  test('transforms $UserResponse to $User', () {
    const response = UserResponse(
      id: '1',
      email: 'dash@example.com',
      displayName: 'Dash',
      avatarUrl: 'https://example.com/avatar.png',
    );

    expect(
      User.fromResponse(response),
      equals(
        const User(
          id: '1',
          email: 'dash@example.com',
          displayName: 'Dash',
          avatarUrl: 'https://example.com/avatar.png',
        ),
      ),
    );
  });

  test('handles null avatarUrl', () {
    const response = UserResponse(
      id: '1',
      email: 'dash@example.com',
      displayName: 'Dash',
    );

    expect(User.fromResponse(response).avatarUrl, isNull);
  });
});
```
