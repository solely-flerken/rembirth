import 'dart:ui';

class LocaleUtil {
  static const isoLanguages = {
    "de": {"name": "German", "nativeName": "Deutsch"},
    "en": {"name": "English (US)", "nativeName": "English (US)"},
    "en_GB": {"name": "English (UK)", "nativeName": "English (UK)"},
    "pl": {"name": "Polish", "nativeName": "polski"},
  };

  static String getLanguageName(String key) {
    if (isoLanguages.containsKey(key)) {
      return isoLanguages[key]?["name"] ?? key;
    } else {
      throw Exception("Language key incorrect");
    }
  }

  static String getLanguageNativeName(String key) {
    if (isoLanguages.containsKey(key)) {
      return isoLanguages[key]?["nativeName"] ?? key;
    } else {
      throw Exception("Language key incorrect");
    }
  }

  static Locale parseLocale(String code) {
    final parts = code.split('_');
    return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }
}
