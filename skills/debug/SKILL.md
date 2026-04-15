---
name: vgv-debug
description: >
  Hypothesis-driven debugging for Dart and Flutter bugs, regressions, crashes,
  flaky behavior, routing issues, state bugs, and hard-to-reproduce failures.
  Use when the main task is understanding why behavior is wrong, reproducing the
  issue, adding minimal temporary instrumentation, narrowing the failure surface,
  and implementing the smallest root-cause fix.
argument-hint: "[bug-summary] [expected-behavior] [repro-steps-or-failing-test]"
allowed-tools: Read Glob Grep Edit Write Bash mcp__very-good-cli__test
effort: high
---

# Debug

Focused debugging workflow for Dart and Flutter codebases. Use this skill to reproduce the failure, trace the execution path, validate hypotheses with targeted evidence, fix the root cause, and verify the result without broad refactors.

## Core Standards

Apply these standards to ALL debugging work:

- **Reproduce before fixing** — confirm the failing behavior and the expected behavior before editing code
- **Collect evidence before naming a root cause** — do not guess from symptoms alone
- **Search the execution path first** — trace entry points, state transitions, async boundaries, and side effects before adding instrumentation
- **Use 1-3 ranked hypotheses** — keep the investigation focused and explicitly eliminate wrong theories
- **Add only minimal temporary instrumentation** — instrument the narrowest fault line that can confirm or reject a concrete hypothesis
- **Tag temporary debugging artifacts** — use `DEBUG(agent):`, `TRACE(agent):`, and `HYP(agent):` so they are searchable and removable
- **Fix the root cause, not only the symptom** — avoid defensive patches that leave the underlying failure path intact when a deeper cause is identifiable
- **Remove temporary instrumentation before finishing** — keep only durable diagnostics that match the project's normal logging style
- **Keep the diff surgical** — do not mix cleanup, refactors, or unrelated improvements into a debugging change
- **Verify with the closest reliable signal** — rerun the failing test, reproduction path, or command that demonstrated the issue

## When To Use This Skill

Use this skill when the primary task is investigation rather than feature delivery:

- Bugs and regressions with unclear causes
- Crashes or exceptions with incomplete stack traces
- Flaky tests, timing bugs, and race conditions
- Navigation and redirect failures in `package:go_router`
- Bloc/Cubit state bugs, duplicate emissions, or stale UI
- Async lifecycle issues involving `BuildContext`, `mounted`, streams, timers, or disposals
- Data mismatches caused by caching, transformation, or repository coordination

Do not use this skill for broad feature work, design tasks, or speculative refactors.

## Debugging Workflow

### 1. Restate the failure precisely

Capture four facts before editing:

1. What is failing?
2. What should happen instead?
3. What is the most reliable reproduction path?
4. What changed recently, if known?

Use concrete language such as:

```text
Observed: Tapping Save on EditProfilePage leaves the button spinning forever.
Expected: The request completes and the page pops with the updated profile.
Repro: Launch app -> open profile -> edit display name -> tap Save.
Recent change: UserRepository save flow was migrated to a new API client.
```

### 2. Trace before editing

Start with search and read operations to map the execution path end-to-end:

- UI event source
- Route / redirect entry point
- Bloc/Cubit event and state transitions
- Use case / repository call
- Data source or API boundary
- Error mapping and UI rendering path

For Flutter apps, trace both directions:

- **Downstream** — user action to side effect
- **Upstream** — returned data or thrown error back to rendered state

### 3. Form ranked hypotheses

Limit the active hypothesis set to 1-3 concrete theories.

Good hypotheses are specific and testable:

- `LoginCubit` emits `loading` but never handles the repository success branch
- a `GoRouter` redirect reads stale auth state before hydration completes
- a `StreamSubscription` survives `dispose()` and emits into a closed Bloc

Avoid vague hypotheses such as "state management is broken" or "async issue somewhere".

### 4. Instrument the fault line

Add the smallest useful instrumentation near the suspected branch, invariant, or state transition.

Temporary code must use searchable tags:

```dart
// DEBUG(agent): Remove after confirming why save() never clears the loading state.
if (kDebugMode) {
  debugPrint('TRACE(agent): EditProfileCubit.save status=$status userId=${state.user.id}');
}
```

Keep instrumentation high-signal:

- log inputs and outputs at a boundary
- log branch decisions
- log state transitions
- log whether cleanup ran
- log values that distinguish the expected path from the faulty path

Do not spam logs in loops, build methods, or unrelated layers.

### 5. Reproduce again and eliminate hypotheses

Re-run the failing test or reproduction path after each focused instrumentation change. Use the new evidence to discard incorrect theories quickly.

When one hypothesis is confirmed, stop instrumenting and implement the smallest coherent fix.

### 6. Fix the root cause

The correct fix usually lives at the first broken invariant, not at the last visible symptom.

Examples:

- initialize a repository dependency before a redirect reads from it
- cancel a prior subscription before attaching a new one
- emit the terminal success or failure state in every async branch
- map transport errors to domain failures consistently instead of swallowing them
- await the operation that mutates state before navigating away

### 7. Remove instrumentation and verify

Delete temporary tagged comments and logs unless a durable diagnostic is clearly justified. If a log must remain, convert it to the project's normal logging style and remove the temporary tag.

Verify using the narrowest reliable signal:

- failing unit or widget test now passes
- manual repro no longer fails
- focused integration flow succeeds
- route redirect behaves correctly after hot restart or cold launch
- flaky test passes repeatedly with stable ordering

## Logging Style

Use structured, contextual logs over broad `print()` spam.

- Log state transitions, branch decisions, inputs, outputs, and invariants
- Prefer IDs and statuses over dumping entire models
- Never log secrets, tokens, passwords, or sensitive user data
- If the codebase already uses a logger, use that instead of ad hoc printing

```dart
logger.info(
  'TRACE(agent): Auth redirect evaluated',
  extra: {
    'isAuthenticated': authState.isAuthenticated,
    'isHydrated': authState.isHydrated,
    'location': state.uri.toString(),
  },
);
```

## Common Flutter Fault Lines

### Bloc / Cubit

- missing terminal success or failure emissions
- duplicate event handling due to multiple providers or listeners
- stale state reads after async gaps
- unhandled exceptions inside repository calls that prevent follow-up emits

### Navigation

- redirects firing before auth or bootstrap state hydrates
- multiple route sources encoding the same decision in different places
- path/query parameter parsing mismatches
- navigation side effects triggered during rebuilds instead of listener callbacks

### Widget Lifecycle

- using `BuildContext` after an async gap without checking `mounted`
- `setState()` after `dispose()`
- forgotten controller, timer, stream, or subscription cleanup
- side effects placed in `build()` instead of `initState()`, listeners, or effects

### Data / Repository Flows

- cache invalidation missing after writes
- DTO-to-domain transformation dropping required fields
- optimistic updates not rolled back on failure
- retry wrappers swallowing terminal errors

### Flaky Tests

- incomplete `pumpAndSettle()` assumptions
- timers, animations, or debounces not advanced deterministically
- shared mutable test state leaking across cases
- mocks returning different async scheduling behavior than production code

## Anti-Patterns

Do not do the following during debugging:

- fix the symptom without identifying the broken invariant
- add broad refactors while the failure surface is still unclear
- leave `TRACE(agent):` or `DEBUG(agent):` artifacts in the final diff
- suppress exceptions or add blanket `try/catch` blocks that hide failures
- mark flaky tests as skipped without isolating the cause
- rewrite large sections of state management when one transition is wrong

## Output Format

Return the investigation outcome in this structure:

- short bug summary
- confirmed root cause
- exact fix made
- how the result was verified
- residual risks or next checks