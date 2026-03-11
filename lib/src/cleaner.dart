import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Finds localization keys used in Dart source content.
///
/// Supports single-line and multi-line usage patterns (e.g., accessor and key
/// split across lines).
Set<String> findUsedKeysInContent(String content, Set<String> allKeys) {
  if (allKeys.isEmpty) return <String>{};

  final String keysPattern = allKeys.map(RegExp.escape).join('|');

  // Quick pre-check: skip if content doesn't contain any key substring
  if (!content.contains(RegExp(keysPattern))) return <String>{};

  final RegExp regex = RegExp(
    // ignore: prefer_interpolation_to_compose_strings
    r'(?:' // Start non-capturing group for all possible access patterns
        r'(?:[a-zA-Z0-9_]+(?:\?)?\s*\.\s*)+' // e.g., `_appLocalizations.`, `l10n?.` (null-aware)
        r'|'
        r'[a-zA-Z0-9_]+\.of\(\s*(?:context|Get\.context\!?|AppNavigation\.context|this\.context|BuildContext\s+\w+)[\s,]*\)\!?\s*\.\s*' // `of(context)!.key`, `of(Get.context!,\n)!.key`
        r'|'
        r'[A-Za-z_]\w*\.[A-Za-z_]\w*\(\s*\)\s*\.\s*' // `SomeClass.method().key`
        r')'
        r'\s*' // Allow whitespace/newlines between accessor and key (fixes multi-line usage)
        r'(' +
    keysPattern +
    r')(?:\b|\s*\()', // Key as getter or method (e.g., `key` or `key(param)`)
    multiLine: true,
    dotAll: true, // Makes `.` match newlines (crucial for multi-line cases)
  );

  final Set<String> usedKeys = <String>{};
  for (final Match match in regex.allMatches(content)) {
    usedKeys.add(match.group(1)!); // Capture only the key
  }
  return usedKeys;
}

/// Reads dart-scan-dirs from remove_unused_localizations.yaml.
/// Returns ['lib'] if the file is missing, invalid, or the key is absent.
List<String> _getDartScanDirs() {
  const String defaultDir = 'lib';
  const List<String> defaultDirs = [defaultDir];

  final File configFile = File('remove_unused_localizations.yaml');
  if (!configFile.existsSync()) {
    return defaultDirs;
  }

  try {
    final String content = configFile.readAsStringSync();
    final dynamic data = loadYaml(content);
    if (data == null || data is! Map) {
      return defaultDirs;
    }

    final dynamic dartScanDirs = data['dart-scan-dirs'];
    if (dartScanDirs == null) {
      return defaultDirs;
    }

    if (dartScanDirs is! YamlList) {
      return defaultDirs;
    }

    final List<String> result = dartScanDirs
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    return result.isEmpty ? defaultDirs : result;
  } catch (_) {
    return defaultDirs;
  }
}

/// Scans the project for unused localization keys and removes them from `.arb` files.
void runLocalizationCleaner({bool keepUnused = false}) {
  final File yamlFile = File('l10n.yaml'); // Path to the l10n.yaml file
  if (!yamlFile.existsSync()) {
    print('✅ Error: l10n.yaml file not found!');
    return;
  }

  // Read & parse YAML
  final String yamlContent = yamlFile.readAsStringSync();
  final Map yamlData = loadYaml(yamlContent);

  // Extract values dynamically
  final String arbDir = yamlData['arb-dir'] as String;

  // Construct values
  final Directory localizationDir = Directory(arbDir);
  final Set<String> excludedFiles = {'$arbDir/app_localizations.dart'};

  // Read .arb file
  final List<File> localizationFiles =
      localizationDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();

  if (localizationFiles.isEmpty) {
    print('✅ No .arb files found in ${localizationDir.path}');
    return;
  }

  final Set<String> allKeys = <String>{};
  final Map<File, Set<String>> fileKeyMap = <File, Set<String>>{};

  // Read all keys from ARB files
  for (final File file in localizationFiles) {
    final Map<String, dynamic> data =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final Set<String> keys =
        data.keys.where((key) => !key.startsWith('@')).toSet();
    allKeys.addAll(keys);
    fileKeyMap[file] = keys;
  }

  final Set<String> usedKeys = <String>{};
  final List<String> dartScanDirs = _getDartScanDirs();

  // Scan Dart files for key usage
  for (final String dirPath in dartScanDirs) {
    final Directory dir = Directory(dirPath);
    if (!dir.existsSync()) {
      print('⚠️ Warning: dart-scan-dir "$dirPath" does not exist, skipping.');
      continue;
    }
    for (final FileSystemEntity file in dir.listSync(recursive: true)) {
      if (file is File &&
          file.path.endsWith('.dart') &&
          !excludedFiles.contains(file.path)) {
        final String content = file.readAsStringSync();
        usedKeys.addAll(findUsedKeysInContent(content, allKeys));
      }
    }
  }

  // Determine unused keys
  final Set<String> unusedKeys = allKeys.difference(usedKeys);
  if (unusedKeys.isEmpty) {
    print('✅ No unused localization keys found.');
    return;
  }

  print("✅ Unused keys found: ${unusedKeys.join(', ')}");

  if (keepUnused) {
    // Keep unused keys to a file instead of deleting them
    final File unusedKeysFile = File('unused_localization_keys.txt');
    unusedKeysFile.writeAsStringSync(unusedKeys.join('\n'));
    print('✅ Unused keys saved to ${unusedKeysFile.path}');
  } else {
    // Remove unused keys from all .arb files
    for (final MapEntry<File, Set<String>> entry in fileKeyMap.entries) {
      final File file = entry.key;
      final Set<String> keys = entry.value;
      final Map<String, dynamic> data =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;

      bool updated = false;
      for (final key in keys) {
        if (unusedKeys.contains(key)) {
          data.remove(key);
          data.remove('@$key');
          updated = true;
        }
      }

      if (updated) {
        file.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(data),
        );
        print('✅ Updated ${file.path}, removed unused keys.');
      }
    }
    print('✅ Unused keys successfully removed.');
  }
}
