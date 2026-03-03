# Architecture — Reference

Extended workflows, configuration, and anti-patterns for the Architecture skill.

---

## Common Workflows

### Adding a New Feature

1. Add domain models and the API client to the data package under `packages/` (or create a new data package if a new data source is needed)
2. Create or update the repository package under `packages/` — consumes the typed API client, applies business logic
3. Create the feature directory: `lib/<feature>/`
4. Create the Bloc/Cubit in `lib/<feature>/bloc/`
5. Create the Page (provides Bloc) and View (consumes Bloc) in `lib/<feature>/view/`
6. Add the barrel file: `lib/<feature>/<feature>.dart`
7. Wire the page into the app's router
8. Mirror the `lib/<feature>/` structure under `test/<feature>/` (repository and data package tests live in their own packages)
9. Run the quality checklist: format, analyze, test with 100% coverage

### Extracting a Shared Package

Extract in two phases — data package first, then repository package:

**Phase 1 — Data package** (API client + models + DTOs):

1. Create the data package: `very_good create dart_package packages/<data_source>_client` (e.g., `api_client`, `local_storage_client`)
2. Move the API client, domain models, and DTOs into `lib/src/`
3. Create the barrel file exporting only the client class and domain models — not DTOs
4. Add `very_good_analysis` to `dev_dependencies`
5. Move data-layer tests into the new package's `test/` directory

**Phase 2 — Repository package**:

1. Create the repository package: `very_good create dart_package packages/<concern>_repository`
2. Move the repository class into `lib/src/`
3. Add the data package as a dependency in `pubspec.yaml`
4. Create the barrel file exporting the repository class and re-exporting domain models from the data package
5. Update consumers to depend on the repository package in `pubspec.yaml`
6. Replace direct imports with barrel file imports
7. Move repository tests into the new package's `test/` directory
8. Run `very_good packages get -r` from the monorepo root
9. Run the quality checklist in every affected package

### Setting Up a Monorepo

1. Create the project root: `very_good create flutter_app my_project`
2. Add `melos.yaml` at the project root
3. Identify data packages — one per data source type (e.g., `api_client` for the REST API, `geolocation_client` for platform geolocation)
4. Move API clients, domain models, and DTOs into data packages under `packages/`
5. Create repository packages that consume data packages and apply business logic
6. Move shared widgets and theme into an `app_ui` package
7. Update `pubspec.yaml` in each package to declare local dependencies
8. Run `melos bootstrap` (or `very_good packages get -r`) to link local packages
9. Verify every package passes format, analyze, and test independently

---

## Melos Configuration

```yaml
name: my_project
packages:
  - .
  - packages/**

command:
  bootstrap:
    usePubspecOverrides: true

scripts:
  analyze:
    exec: dart analyze --fatal-infos --fatal-warnings
  format:
    exec: dart format --set-exit-if-changed .
  test:
    exec: very_good test --coverage --min-coverage 100
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Layer-first folder organization | Artificial boundaries between related code | Feature-first organization |
| Exporting everything from barrel files | Exposes implementation details (DTOs, internal widgets) | Export only public API |
| Repository handling DTOs or JSON | Breaks concern separation — that's the data package's job | Repository consumes typed API client methods |
| Service locator / global singleton | Hidden dependencies, untestable | Constructor injection via RepositoryProvider |
| Per-domain data packages (e.g., `todo_api_client`, `auth_api_client`) | Splits one data source across packages; duplicates transport config | One data package per data source type |
| Circular package dependencies | Unclear ownership, build fragility | Unidirectional: presentation → repository → data package |
| Skipping the repository layer | Presentation coupled to raw data source | Always route through a repository |
