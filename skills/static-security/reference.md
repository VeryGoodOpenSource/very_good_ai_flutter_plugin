# Security — Reference

Extended reference material for the Security skill: package quick reference, severity triage guide, certificate pinning implementation, biometric authentication, password hashing, typosquatting detection signals, transitive permission creep checks, and `osv-scanner` installation.

---

## Package Quick Reference

| Package                            | Replaces / Prevents                                    | Category                   |
| ---------------------------------- | ------------------------------------------------------ | -------------------------- |
| `package:flutter_secure_storage`   | `SharedPreferences` for sensitive data                 | Secure Storage             |
| `package:http_certificate_pinning` | Certificate spoofing / MITM attacks                    | Network Security           |
| `package:local_auth`               | Custom biometric implementations                       | Authentication             |
| `package:crypto`                   | Weak hash algorithms, custom crypto                    | Cryptography               |
| `package:dart_crypt`               | Insecure password storage (SHA-512-crypt)              | Cryptography               |
| `package:formz`                    | Raw `TextEditingController` input without validation   | Input Validation           |
| `osv-scanner`                      | Undetected CVEs in `pubspec.lock`                      | Dependency Vulnerabilities |
| `package:freerasp`                 | Compromised device / repackaged app (runtime)          | Binary Protection          |

---

## Severity Guide

When auditing a codebase with this skill, triage findings using these tiers:

| Severity | Examples                                                                                                                                                     |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Critical | Hardcoded API key or token; `badCertificateCallback` bypass; JWT in `SharedPreferences`; sensitive data in logs                                              |
| Warning  | Missing certificate pinning on auth endpoints; `Random()` used for session IDs; no `package:formz` validation before API calls; `android:allowBackup="true"` |
| Note     | Missing Dart obfuscation; `dart pub outdated` shows available patches; low-pub-point transitive dependency with broad permissions                             |

---

## Certificate Pinning

Implement certificate pinning (`package:http_certificate_pinning`) for endpoints that handle authentication, payments, or personal data. Only accept certificates signed by the expected certificate authority.

```dart
final result = await HttpCertificatePinning.check(
  serverURL: 'https://api.example.com',
  headerHttp: {},
  sha: SHA.SHA256,
  allowedSHAFingerprints: ['AA:BB:CC:...'],
  timeout: 60,
);
if (result != 'CONNECTION_SECURE') {
  throw CertificatePinningException();
}
```

---

## Biometric Authentication

Use `package:local_auth` for biometric gating of sensitive in-app flows. Do not invoke platform channels directly — the abstraction handles platform differences and reduces implementation error.

```dart
// ❌ Custom biometric implementation via platform channel — error-prone
final result = await platform.invokeMethod('checkFingerprint');

// ✅ Biometric authentication via package:local_auth
final auth = LocalAuthentication();
final didAuthenticate = await auth.authenticate(
  localizedReason: 'Confirm your identity to view this information',
  options: const AuthenticationOptions(biometricOnly: true),
);
```

---

## Password Hashing

Use `package:dart_crypt` for password storage. SHA-512-crypt is a slow, salted algorithm designed for passwords — unlike `sha256` from `package:crypto`, which is fast and unsuitable for password hashing.

```dart
import 'package:dart_crypt/dart_crypt.dart';

// Hash on registration / password change
final hashed = Crypt.sha512(password);

// Verify on login
final isValid = hashed.match(inputPassword);
```

---

## Typosquatting Signals

Flag packages in `pubspec.yaml` that match any of these patterns:

- Name differs from a well-known package by one character, a dash/underscore swap, or transposed letters (e.g., `flutter-secure-storage` vs `flutter_secure_storage`, `bloc_fluter` vs `flutter_bloc`)
- No verified publisher on pub.dev (check the publisher badge on the package's pub.dev page) and fewer than 100 pub points, while performing high-privilege operations: file I/O, network requests, camera, Keychain/Keystore access
- Publisher's GitHub repo URL does not match the package's declared homepage

---

## Transitive Permission Creep

Review `AndroidManifest.xml` for permissions that no first-party Dart code requires. Permissions can be merged in silently by transitive dependencies:

```xml
<!-- Flag: does any first-party code actually use READ_CONTACTS? -->
<uses-permission android:name="android.permission.READ_CONTACTS" />
```

Trace which package introduced an unexpected permission:

```bash
flutter pub deps --style=tree
```

Apply the same check to `NSUsageDescription` keys in `ios/Runner/Info.plist`.

---

## osv-scanner Installation

Scan `pubspec.lock` against the [OSV database](https://osv.dev) for known CVEs.

```bash
# macOS
brew install osv-scanner

# Linux / CI — download binary from https://github.com/google/osv-scanner/releases
osv-scanner --lockfile=pubspec.lock
# Output: table of vulnerable packages with CVE links and affected versions
```
