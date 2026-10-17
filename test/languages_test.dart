import 'package:flutter_test/flutter_test.dart';
import 'package:terrimap_core/i18n/languages.dart';

void main() {
  test('対応言語: コードが重複せず、英語を含み、約10言語', () {
    final codes = appLanguages.map((l) => l.code).toList();
    expect(codes.toSet().length, codes.length);
    expect(codes, contains('en'));
    expect(codes.length, inInclusiveRange(9, 12));
    for (final l in appLanguages) {
      expect(l.nativeName.trim(), isNotEmpty);
    }
  });

  test('端末の言語から決める。対応外は英語', () {
    expect(resolveLanguage('de'), 'de');
    expect(resolveLanguage('JA'), 'ja');
    expect(resolveLanguage('sv'), 'en');
    expect(resolveLanguage('sv', fallback: 'de'), 'de');
  });
}
