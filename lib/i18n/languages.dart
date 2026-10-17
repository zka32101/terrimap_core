/// アプリが対応する表示言語（言語コードと、その言語での名前）。
/// 翻訳の進み具合に関わらず、候補として並べる（文言が足りない言語は英語で補う）。
class AppLanguage {
  final String code, nativeName;
  const AppLanguage(this.code, this.nativeName);
}

const appLanguages = <AppLanguage>[
  AppLanguage('en', 'English'),
  AppLanguage('de', 'Deutsch'),
  AppLanguage('fr', 'Français'),
  AppLanguage('es', 'Español'),
  AppLanguage('it', 'Italiano'),
  AppLanguage('pt', 'Português'),
  AppLanguage('nl', 'Nederlands'),
  AppLanguage('tr', 'Türkçe'),
  AppLanguage('ja', '日本語'),
  AppLanguage('ko', '한국어'),
  AppLanguage('zh', '简体中文'),
];

/// 端末の言語から、使う言語を決める。対応していなければ英語。
String resolveLanguage(String deviceLanguageCode, {String fallback = 'en'}) {
  final code = deviceLanguageCode.toLowerCase();
  return appLanguages.any((l) => l.code == code) ? code : fallback;
}
