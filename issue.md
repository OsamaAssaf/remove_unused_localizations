## Bug Report

### Description

`remove_unused_localizations` v1.1.2 fails to detect two common localization access patterns, causing keys that **are** used in the codebase to be reported as unused (false positives in the unused report / false negatives in the detection).

### Environment

- Package version: 1.1.2
- Flutter: 3.32+
- State management: Riverpod 3 (with `@riverpod` codegen)

### Bug 1: Nullable access `?.` after `of(context)` is not recognized

**Pattern that fails:**
```dart
AppLocalizations.of(context)?.trafficLightRestBadge ?? "REST"
```

**Patterns that work correctly:**
```dart
AppLocalizations.of(context)!.trafficLightRestBadge  // ✅ non-null assert
AppLocalizations.of(context).trafficLightRestBadge   // ✅ direct access
```

**Root cause** (`cleaner.dart` line 22):
```regex
[a-zA-Z0-9_]+\.of\(\s*(?:context|...)\)\!?\s*\.\s*
                                        ^^
```
The `\!?` makes the `!` optional but does not account for `?` (null-aware access). The fix is:
```regex
\)[!?]?\s*\.
```

### Bug 2: Chained method calls with arguments are not matched

**Pattern that fails:**
```dart
ref.read(l10nProvider).microphoneError
```

**Pattern that works:**
```dart
l10n.microphoneError  // ✅ simple word.key
```

**Root cause** (`cleaner.dart` line 20):
```regex
(?:[a-zA-Z0-9_]+(?:\?)?\s*\.\s*)+
```
This chain pattern matches `word.word.word` sequences but cannot cross parenthesized arguments like `(l10nProvider)`. When it encounters `read(`, the chain breaks and the key after the closing `)` is never captured.

**Suggested fix** — allow optional `(...)` in chain links:
```regex
(?:[a-zA-Z0-9_]+(?:\([^)]*\))?(?:\?)?\s*\.\s*)+
```

### Minimal Reproduction

```dart
// lib/core/l10n_provider.dart
import package:flutter_gen/gen_l10n/app_localizations.dart;
import package:riverpod_annotation/riverpod_annotation.dart;
part l10n_provider.g.dart;

@Riverpod(keepAlive: true)
AppLocalizations l10n(Ref ref) => lookupAppLocalizations(/* ... */);

// lib/features/audio_capture_mixin.dart
// This usage is NOT detected → key reported as unused:
ref.read(l10nProvider).microphoneError

// lib/features/intensity/widgets/traffic_light_gauge.dart
// This usage is NOT detected → key reported as unused:
AppLocalizations.of(context)?.trafficLightRestBadge ?? "REST"
```

Run:
```bash
dart run remove_unused_localizations --keep-unused
```

Both `microphoneError` and `trafficLightRestBadge` are incorrectly listed as unused.

### Impact

Projects using Riverpod providers or nullable `AppLocalizations.of(context)?` (common in Flutter 3.x) will have legitimate keys flagged as unused and potentially deleted.

Thank you for the great package! Happy to submit a PR with the regex fixes if helpful.