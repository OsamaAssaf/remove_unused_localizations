# remove_unused_localizations

A Flutter development tool that automatically detects and removes unused localization keys from `.arb` files, keeping your project clean and optimized.

## Features
✅ Scans all `.arb` files dynamically (supports multiple languages).  
✅ Detects and removes **only truly unused keys** (avoiding false deletions).  
✅ Works with **global localization variables** like:
   ```dart
   localizations.welcome
S.of(context).welcome
AppLocalizations.of(context)!.welcome
   ```
✅ **Excludes important files** (e.g., `app_localizations.dart`).  
✅ Provides a **detailed report** of removed keys.

## Installation

Add the package to your **dev dependencies** in `pubspec.yaml`:

```yaml
dev_dependencies:
  remove_unused_localizations: ^0.0.2
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

This will automatically scan all `.arb` files in your project, detect unused keys, and remove them, keeping your localization files clean and optimized.

## Example Output
```
Unused keys found: welcome_message, login_button
Updated lib/l10n/app_en.arb, removed unused keys.
Updated lib/l10n/app_ar.arb, removed unused keys.
✅ Unused keys successfully removed.
```

## Contributing
Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/OsamaAssaf/remove_unused_localizations).

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
