## 0.0.1 - Initial Release
- 🎉 First version of `remove_unused_localizations`.
- 🛠 Automatically detects and removes unused localization keys.
- 🚀 Supports all `.arb` files dynamically.
- 🔍 Excludes important localization files to prevent accidental deletions.
- 📊 Provides detailed output on removed keys.

## 0.0.2 - Fixes for Initial Release

## 0.0.3 - Fixes for Initial Release

## 0.0.4 - Add New Feature
- 🎉 Add new feature to not automatically remove unused localization keys from `lib` folder (If needed).

## 1.0.0 - Stable Release & Performance Improvements
-  🏁 Stable release — officially moved to version 1.0.0.
-  🚀 Improved performance: Faster scanning of .arb and Dart files.
-  🔒 Safer file handling: Improved exclusion logic for critical files.
-  🧠 Smarter key detection: Better regex accuracy for detecting used localization keys.
-  📦 Improved CLI structure: Now works properly as a CLI tool and prints output to the terminal.
-  🧪 General refactoring and stability improvements.

## 1.0.1 - Documentation Update
- 📝 Updated `README.md` with detailed usage instructions, examples, and feature descriptions.
- ✅ Improved overall clarity for installation and usage on pub.dev.

## 1.0.2 - Extended Localization Pattern Support
- 🐛 **Fixed**: Plugin no longer incorrectly removes used translations when localization keys are accessed across multiple lines (e.g., `AppLocalizations.of(context)!.\n  key`).
- 🔍 Detection regex now allows optional whitespace and newlines between the accessor and the key.
- 🐛 **Fixed**: Plugin now detects `AppLocalizations.of(Get.context!)!.key` (GetX).
- 🐛 **Fixed**: Plugin now detects null-aware access (`variable?.key`, `variable?.method(param)`).
- 🐛 **Fixed**: Plugin now detects method calls with parameters (e.g., `key(type.name)`, `key(e.toString())`).
- 🐛 **Fixed**: Plugin now detects `AppLocalizations.of(Get.context!,\n)!.key` (formatted multi-line with trailing comma).

## 1.0.3 - Configurable Dart Scan Directories

- ✨ **New**: Add optional `remove_unused_localizations.yaml` config file to specify custom directories to scan for Dart files.
- 📂 Supports monorepos, shared packages, and projects with Dart code outside `lib`.
- ⚙️ New `dart-scan-dirs` option: list of directories to scan (paths relative to project root).
- 🔄 Defaults to `lib` when config is absent for backward compatibility.
- 📝 Updated README with Configuration section and note about syncing with `l10n.yaml`.
