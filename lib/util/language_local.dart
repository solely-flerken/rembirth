class LanguageLocal {
  static const isoLanguages = {
    "de": {"name": "German", "nativeName": "Deutsch"},
    "en": {"name": "English", "nativeName": "English"},
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
}
