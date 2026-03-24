---
name: vgv-dart-flutter-sdk-upgrade
description: >
  VGV-specific reference for bumping Dart and Flutter SDK constraints across packages.
  Use when upgrading the Flutter or Dart SDK version in any VGV repository — bumping
  pubspec.yaml environment constraints, updating CI workflow Flutter versions, or preparing
  an SDK upgrade PR. CI uses ^MAJOR.MINOR.x to resolve to the latest patch; pubspec pins
  the exact patch version (e.g., ^3.50.1). Trigger on phrases like "bump Flutter to 3.x",
  "update SDK constraints", "upgrade Dart SDK", "update CI Flutter version",
  "bump SDK version", or "prep the SDK upgrade PR".
allowed-tools: Read,Glob,Grep,Edit,Write,Bash
---

# VGV Flutter/Dart SDK Upgrade — Quick Reference

One PR per project. Only CI workflow and `pubspec.yaml` changes — no logic, no dependency
version bumps, no test changes.

---

## 0. Resolve target version

Flutter bundles a specific Dart release — their version numbers do **not** match. For
example, Flutter 3.41.0 ships with Dart 3.11.0. You must look up the correct Dart version
for the target Flutter release before editing any files.

**How to find the Dart version:**
1. Open https://docs.flutter.dev/install/archive
2. Find the target Flutter stable release
3. Note the Dart version listed alongside it

If the user has not specified a Flutter version, look up the latest Flutter stable release
from that same page. For pure Dart packages (no Flutter dependency), the Dart version is
whatever the user specifies or the latest stable — no Flutter mapping needed.

Confirm both resolved versions with the user before editing files.

---

## 1. CI workflows — `.github/workflows/`

VGV packages use `VeryGoodOpenSource/very_good_workflows` reusable workflows. Leave the
`@v1` tag untouched. Use `^MAJOR.MINOR.x` — caret with literal `x` as the patch wildcard
so CI always resolves to the latest release patch automatically. When bumping versions,
update MAJOR and/or MINOR as appropriate (e.g., `^3.41.x` → `^3.42.x` or `^4.0.x`):

**Flutter package:**

```yaml
uses: VeryGoodOpenSource/very_good_workflows/.github/workflows/flutter_package.yml@v1
with:
  flutter_version: "^3.41.x" # ← caret + MAJOR.MINOR.x, resolves to latest patch
```

**Pure Dart package** — note the key is `dart_sdk`, not `flutter_version`. Use the Dart
version, not the Flutter version:

```yaml
uses: VeryGoodOpenSource/very_good_workflows/.github/workflows/dart_package.yml@v1
with:
  dart_sdk: "^3.11.x" # ← Dart version (not Flutter version)
```

If a file uses `flutter_channel: stable` instead of a pinned version, ask the user whether
they want to pin it — pinning is generally preferred at VGV.

---

## 2. `pubspec.yaml` environment constraints

Format is `^MAJOR.MINOR.PATCH` (caret, exact patch). Unlike CI, pubspec pins a specific
patch version — the one the user specifies or the current stable at the time of the bump.

**Flutter package** (has `flutter:` under `dependencies`):

```yaml
environment:
  sdk: ^3.11.0    # ← Dart version bundled with the target Flutter release
  flutter: ^3.41.0 # ← Flutter version
```

**Pure Dart package** (no Flutter SDK dependency):

```yaml
environment:
  sdk: ^3.11.0 # ← Dart version only
  # no flutter: line
```

In a monorepo, update each package's `pubspec.yaml` individually. The shared CI workflow
only needs updating once.

---

## 3. Verify

Run from each package directory. **Use Dart/Flutter MCP tools if available; otherwise Bash.**

```bash
flutter pub get   # or: dart pub get  (for pure Dart packages)
flutter analyze   # or: dart analyze
```

If `pub get` fails with dependency conflicts, report them — don't silently resolve by
upgrading packages. If `analyze` surfaces new errors introduced by the SDK bump, report
them rather than fixing them in this PR.

---

## 4. PR scope check

Before committing, confirm the diff contains only:

- `.github/workflows/*.yml`
- `pubspec.yaml` (one or more)

```bash
git diff --name-only
```

Suggested commit/PR message:

```
chore: bump Flutter to 3.41.0 / Dart to 3.11.0

- Update flutter_version in .github/workflows/ to ^3.41.x (CI resolves latest patch)
- Update environment sdk/flutter constraints in pubspec.yaml

No logic or code changes.
```
