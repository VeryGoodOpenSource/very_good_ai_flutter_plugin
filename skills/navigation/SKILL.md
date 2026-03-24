---
name: vgv-navigation
description: Best practices for navigation and routing in Flutter using GoRouter. Use when creating, modifying, or reviewing routes, deep links, redirects, or navigation logic that uses package:go_router or package:go_router_builder.
allowed-tools: Read,Glob,Grep
---

# Navigation

Routing and navigation best practices for Flutter applications using GoRouter, the Flutter team's recommended routing package built on the Navigator 2.0 API.

## Core Standards

Apply these standards to ALL navigation work:

- **Use `package:go_router` for all navigation** — never raw Navigator 2.0 or Navigator 1.0 push/pop
- **Use `@TypedGoRoute` annotations for type-safe routes** — never raw string paths in route definitions
- **Prefer `go()` over `push()`** — use `push()` only when expecting return data from the destination
- **Never use the `extra` parameter** — it breaks deep linking and does not work on the web
- **Hierarchical sub-routes for proper back navigation** — structure routes as parent-child trees, not flat lists
- **Hyphens for URL word separation** — never underscores or camelCase in URL paths
- **Navigate by route name, not raw path strings** — use named route navigation to decouple from path changes
- **Use `BuildContext` extensions for navigation** — prefer `context.goNamed()` over `GoRouter.of(context).goNamed()`

## Route Organization

Structure routes hierarchically with logical parent-child relationships. Sub-routes ensure the app bar back button displays correctly and URLs remain clean.

### Hierarchical Structure (Preferred)

```text
/flutter
  /flutter/news
  /flutter/chat
  /flutter/articles
    /flutter/articles?category=all
    /flutter/article/:id
/android
  /android/news
  /android/chat
```

### Flat Structure (Avoid)

```text
/flutter-news
/flutter-chat
/android-news
/android-chat
```

Hierarchical sub-routes produce proper backward navigation automatically — when a user is on `/flutter/news`, the back button navigates to `/flutter`.

## Type-Safe Routes

Use `@TypedGoRoute` annotations with `GoRouteData` classes to eliminate typos and manual parameter casting. The `go_router_builder` package generates type-safe route helpers at build time.

### Basic Route

```dart
@TypedGoRoute<CategoriesPageRoute>(
  name: 'categories',
  path: '/categories',
)
@immutable
class CategoriesPageRoute extends GoRouteData {
  const CategoriesPageRoute({
    this.size,
    this.color,
  });

  final String? size;
  final String? color;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CategoriesPage(size: size, color: color);
  }
}
```

### Route with Sub-Routes

```dart
@TypedGoRoute<FlutterPageRoute>(
  name: 'flutter',
  path: '/flutter',
  routes: [
    TypedGoRoute<FlutterNewsPageRoute>(
      name: 'flutterNews',
      path: 'news',
    ),
    TypedGoRoute<FlutterArticlesPageRoute>(
      name: 'flutterArticles',
      path: 'articles',
      routes: [
        TypedGoRoute<FlutterArticlePageRoute>(
          name: 'flutterArticle',
          path: 'article/:id',
        ),
      ],
    ),
  ],
)
@immutable
class FlutterPageRoute extends GoRouteData {
  const FlutterPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FlutterPage();
  }
}
```

## Navigation Methods

### `go()` vs `push()`

| Method   | URL Updates | Back Button | Use Case                                    |
| -------- | ----------- | ----------- | ------------------------------------------- |
| `go()`   | Yes         | App bar     | Standard navigation between screens         |
| `push()` | No          | System      | When expecting return data from popped route |

### Using `go()` (Default)

```dart
const CategoriesPageRoute(size: 'small', color: 'blue').go(context);
```

Using `go()` ensures the back button in the app's `AppBar` displays when the current route has a parent to navigate back to.

### Using `push()` (Return Data Only)

```dart
final result = await DialogPageRoute().push<String>(context);
```

Use `push()` only when a route must return data (e.g., a dialog collecting user input). On the web, `push()` does not update the address bar.

### BuildContext Extensions

Always use extension methods for cleaner syntax:

```dart
// Preferred
context.goNamed('flutterNews');

// Avoid
GoRouter.of(context).goNamed('flutterNews');
```

## Parameter Strategies

### Path Parameters — Resource Identification

Use path parameters to identify specific resources:

```dart
@TypedGoRoute<FlutterArticlePageRoute>(
  name: 'flutterArticle',
  path: 'article/:id',
)
@immutable
class FlutterArticlePageRoute extends GoRouteData {
  const FlutterArticlePageRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FlutterArticlePage(id: id);
  }
}
```

Navigation: `FlutterArticlePageRoute(id: article.id).go(context);`

### Query Parameters — Filtering and Sorting

Use query parameters for optional filtering or sorting criteria:

```dart
@TypedGoRoute<FlutterArticlesPageRoute>(
  name: 'flutterArticles',
  path: 'articles',
)
@immutable
class FlutterArticlesPageRoute extends GoRouteData {
  const FlutterArticlesPageRoute({
    this.date,
    this.category,
  });

  final String? date;
  final String? category;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FlutterArticlesPage(
      date: date,
      category: category,
    );
  }
}
```

URL example: `/flutter/articles?date=07162024&category=all`

### Why `extra` Is Prohibited

The `extra` parameter does not work on the web and cannot be used for deep linking. Instead, pass identifiers via path or query parameters and fetch data within the destination page.

## Redirects

Redirects can be applied at the root router level and at individual route levels. Parent redirects execute before child redirects.

### Root-Level Redirect (Authentication Guard)

```dart
GoRouter _routes(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorKey,
    redirect: (context, state) {
      final status = context.read<AppBloc>().state.status;
      if (status == AppStatus.unauthenticated) {
        return SignInPageRoute().location;
      }
      return null;
    },
    routes: $appRoutes,
  );
}
```

### Route-Level Redirect (Authorization Guard)

```dart
@TypedGoRoute<PremiumPageRoute>(
  name: 'premium',
  path: '/premium',
  routes: [
    TypedGoRoute<PremiumShowsPageRoute>(
      name: 'premiumShows',
      path: 'shows',
    ),
  ],
)
class PremiumPageRoute extends GoRouteData {
  @override
  String? redirect(BuildContext context, GoRouterState state) {
    final status = context.read<AppBloc>().state.user.status;
    if (status != UserStatus.premium) {
      return RestrictedPageRoute().location;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PremiumPage();
  }
}
```

## Testing

### Mocking GoRouter for Widget Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
  });

  testWidgets('navigates to details on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockRouter,
          child: const HomePage(),
        ),
      ),
    );

    await tester.tap(find.text('View Details'));
    verify(() => mockRouter.goNamed('details')).called(1);
  });
}
```

### Testing Redirects

```dart
testWidgets('redirects unauthenticated user to sign in', (tester) async {
  final router = GoRouter(
    initialLocation: '/premium',
    redirect: (context, state) {
      // Simulate unauthenticated state
      return '/sign-in';
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumPage()),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  await tester.pumpAndSettle();

  expect(find.byType(SignInPage), findsOneWidget);
});
```

## Common Patterns

### Adding a New Route

1. Create the page widget (following the Page/View pattern if using Bloc)
2. Define a `GoRouteData` class with `@TypedGoRoute` annotation
3. Add it as a sub-route under the appropriate parent route
4. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate route helpers
5. Navigate using the generated type-safe route class

### Deep Linking Setup

1. Structure routes hierarchically with meaningful URL paths
2. Use path parameters for resource identification
3. Use query parameters for filtering — never `extra`
4. Navigate by route name so path restructuring does not break links
5. Test deep links by launching the app with the target URL

### Nested Navigation (Shell Routes)

```dart
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<HomePageRoute>(
      name: 'home',
      path: '/home',
    ),
    TypedGoRoute<SettingsPageRoute>(
      name: 'settings',
      path: '/settings',
    ),
  ],
)
class AppShellRoute extends ShellRouteData {
  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return AppShell(child: navigator);
  }
}
```

## Quick Reference

| Package              | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `go_router`          | Declarative routing built on Navigator 2.0   |
| `go_router_builder`  | Code generation for type-safe route classes   |

| Command                                                    | Purpose                          |
| ---------------------------------------------------------- | -------------------------------- |
| `dart run build_runner build --delete-conflicting-outputs`  | Generate type-safe route helpers |
| `dart run build_runner watch --delete-conflicting-outputs`  | Watch and regenerate on changes  |
