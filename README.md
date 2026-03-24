# remove_unused_localizations

A Flutter development tool that automatically detects and removes unused localization keys from
`.arb` files, keeping your project clean and optimized.

## Features

✅ Scans all `.arb` files dynamically (supports multiple languages).  
✅ Detects and removes **only truly unused keys** (avoiding false deletions).  
✅ Works with **global localization variables** like:

```dart
localizations.welcome           // Generic localization instance
S.of(context).welcome           // Flutter-generated localization access
AppLocalizations.of(context)!.welcome // Nullable-safe access
_myCubit.appLocalizations.welcome    // Deep object chains
SomeClass().localizations.welcome    // Method return chaining
```

✅ **Excludes important files** (e.g., `app_localizations.dart`).  
✅ Provides a **detailed report** of removed keys.

## Installation

Add the package to your **dev dependencies** in `pubspec.yaml`:

```yaml
dev_dependencies:
  remove_unused_localizations: ^1.1.1
```

Run:

```sh
flutter pub get
```

## Usage

### **Run the Package from the Terminal**

You can run the package directly as a CLI tool using:

```sh
dart run remove_unused_localizations
```

This will automatically scan all `.arb` files in your project, detect unused keys, and remove them,
keeping your localization files clean and optimized.

If you want to keep the unused keys in order to delete it manually you can use this command:

```sh
dart run remove_unused_localizations --keep-unused
```

## Configuration

By default, the tool scans only the `lib` directory for Dart files that use localization keys. For monorepos, shared packages, or projects with Dart code in other directories, you can add a `remove_unused_localizations.yaml` config file at your project root (next to `l10n.yaml`).

**Config file:** `remove_unused_localizations.yaml`

```yaml
# Directories to scan for Dart files that use localization keys.
# Paths are relative to the project root. Default: [lib]
dart-scan-dirs:
  - lib
  - packages/app1/lib
  - packages/shared/lib
```

- The config file is **optional**. When absent, the tool scans `lib` only (backward compatible).
- Paths in `dart-scan-dirs` are relative to the project root.
- If a directory does not exist, the tool prints a warning and skips it.

**Note:** If you use a non-standard project structure (e.g. you set `arb-dir` to a custom path like `reference/l10n` in `l10n.yaml`), make sure to also configure `dart-scan-dirs` in `remove_unused_localizations.yaml` to include all directories that contain Dart code using localization keys. Otherwise, the tool may incorrectly mark keys as unused.

**Example for monorepos:**

```yaml
dart-scan-dirs:
  - packages/app1/lib
  - packages/app2/lib
  - packages/shared/lib
```

## Example Output

```
Unused keys found: welcome_message, login_button
Updated lib/l10n/app_en.arb, removed unused keys.
Updated lib/l10n/app_ar.arb, removed unused keys.
✅ Unused keys successfully removed.
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request
on [GitHub](https://github.com/OsamaAssaf/remove_unused_localizations).

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
