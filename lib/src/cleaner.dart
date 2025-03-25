import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Read l10n.yaml and checking (now Flutter Depracte Flutter_gen and l10n became required at all )
void runLocalizationCleaner({bool keepUnused = false}) {
  final File yamlFile = File('l10n.yaml'); // Path to your l10n.yaml file
  if (!yamlFile.existsSync()) {
    print('Error: l10n.yaml file not found!');
    return;
  }

  // Read & parse YAML
  final String yamlContent = yamlFile.readAsStringSync();
  final Map yamlData = loadYaml(yamlContent);

  // Extract values dynamically
  final String arbDir = yamlData['arb-dir'] as String;
  final String outputDir = yamlData['output-dir'] as String;
  final String outputFile = yamlData['output-localization-file'] as String;
  final String locClassName = yamlData['output-class'] as String;

  // Construct values
  final Directory localizationDir = Directory(arbDir);
  final Set<String> excludedFiles = {'$outputDir/$outputFile'};

 //read arb file
  final List<File> localizationFiles =
      localizationDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();

  if (localizationFiles.isEmpty) {
    log('No .arb files found in ${localizationDir.path}');
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
  final Directory libDir = Directory('lib');
//improve Reg Exp 
  final String keysPattern = allKeys.map(RegExp.escape).join('|');
  final RegExp regex = RegExp(
    r'(?:' // Start non-capturing group for all possible access patterns
    r'(?:[a-zA-Z0-9_]+\.)+' // e.g., `_appLocalizations.` or `cubit.appLocalizations.`
    r'|'
    r'[a-zA-Z0-9_]+\.of\(\s*(?:context|AppNavigation\.context|this\.context|BuildContext\s+\w+)\s*\)\!?\s*\.\s*' // `of(context)!.key` with optional whitespace
    r'|'
    r'[a-zA-Z0-9_]+\.\w+\(\s*\)\s*\.\s*' // `SomeClass.method().key`
    r')'
    r'(' + keysPattern + r')\b', // The actual key
    multiLine: true,
    dotAll: true, // Makes `.` match newlines (crucial for multi-line cases)
  );

  for (final FileSystemEntity file in libDir.listSync(recursive: true)) {
    if (file is File &&
        file.path.endsWith('.dart') &&
        !excludedFiles.contains(file.path)) {
      final String content = file.readAsStringSync();

      // Quick pre-check: Skip files that don't contain any key substring
      if (!content.contains(RegExp(keysPattern))) continue;

      for (final Match match in regex.allMatches(content)) {
        usedKeys.add(match.group(1)!); // Capture only the key
      }
    }
  }

  // Determine unused keys
  final Set<String> unusedKeys = allKeys.difference(usedKeys);
  if (unusedKeys.isEmpty) {
    log('No unused localization keys found.');
    return;
  }

  log("Unused keys found: ${unusedKeys.join(', ')}");

  if (keepUnused) {
    // Keep unused keys to a file instead of deleting them
    final File unusedKeysFile = File('unused_localization_keys.txt');
    unusedKeysFile.writeAsStringSync(unusedKeys.join('\n'));
    log('✅ Unused keys saved to ${unusedKeysFile.path}');
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
        log('Updated ${file.path}, removed unused keys.');
      }
    }
    log('✅ Unused keys successfully removed.');
  }
}
