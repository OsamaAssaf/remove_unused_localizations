import 'package:flutter_test/flutter_test.dart';
import 'package:remove_unused_localizations/src/cleaner.dart';

void main() {
  const Set<String> testKeys = {
    'subscribe_button',
    'maturity_block_title',
    'content_restriction_title',
    'maturity_block_description',
    'content_restriction_description',
    'geo_restriction_description',
    'externalDescription',
    'nothingToSync',
    'syncedDataset',
    'criticalError',
    'fixedPriceProjectTheItemCannotBeBillable',
  };

  group('findUsedKeysInContent', () {
    test('detects single-line property access', () {
      const content = '''
        final text = AppLocalizations.of(context)!.subscribe_button;
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('subscribe_button'));
    });

    test('detects single-line chained property access', () {
      const content = '''
        final title = l10n.maturity_block_title;
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('maturity_block_title'));
    });

    test('detects multi-line property access (accessor and key on separate lines)', () {
      const content = '''
        final text = AppLocalizations.of(context)!.
          subscribe_button;
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('subscribe_button'));
    });

    test('detects multi-line chained property access', () {
      const content = '''
        final title = l10n.
          maturity_block_title;
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('maturity_block_title'));
    });

    test('detects multi-line chained property access', () {
      const content = '''
        Text(
          context
              .l10n
              .maturity_block_title,
        ),
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('maturity_block_title'));
    });

    test('detects multi-line method call with parameter', () {
      const content = '''
        final desc = l10n.
          maturity_block_description(content.contentRating!.minAge);
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('maturity_block_description'));
    });

    test('detects multiple keys in multi-line format', () {
      const content = '''
        Widget build(BuildContext context) {
          return Column(
            children: [
              Text(AppLocalizations.of(context)!.
                content_restriction_title),
              Text(l10n.
                geo_restriction_description(content.title.toString())),
            ],
          );
        }
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, containsAll([
        'content_restriction_title',
        'geo_restriction_description',
      ]));
    });

    test('detects AppLocalizations.of(Get.context!)!.key (GetX)', () {
      const content = '''
        displayLabel: AppLocalizations.of(Get.context!)!.externalDescription,
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('externalDescription'));
    });

    test('detects null-aware getter (variable?.key)', () {
      const content = '''
        return (true, localizations?.nothingToSync ?? 'Nothing to sync');
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('nothingToSync'));
    });

    test('detects null-aware method with parameter (variable?.key(param))', () {
      const content = '''
        ? (_syncLocalizations?.syncedDataset(type.name) ?? '');
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('syncedDataset'));
    });

    test('detects method with nested parentheses (variable?.key(e.toString()))', () {
      const content = '''
        localizations?.criticalError(e.toString()) ?? 'Critical error';
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('criticalError'));
    });

    test('detects of() with comma and newline before closing paren', () {
      const content = '''
        Components().snackBar(
          message: AppLocalizations.of(
            Get.context!,
          )!.fixedPriceProjectTheItemCannotBeBillable,
        );
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, contains('fixedPriceProjectTheItemCannotBeBillable'));
    });

    test('returns empty set when no keys are used', () {
      const content = '''
        void main() {
          print('hello');
        }
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, isEmpty);
    });

    test('returns empty set when keys appear without valid accessor', () {
      const content = '''
        final x = 'subscribe_button'; // string literal, not localization
      ''';
      final used = findUsedKeysInContent(content, testKeys);
      expect(used, isEmpty);
    });

    test('handles empty key set', () {
      const content = 'l10n.some_key';
      final used = findUsedKeysInContent(content, <String>{});
      expect(used, isEmpty);
    });
  });
}
