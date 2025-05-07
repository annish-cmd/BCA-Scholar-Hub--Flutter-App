import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en', 'US');

  static const String _languageCodeKey = 'languageCode';
  static const String _countryCodeKey = 'countryCode';

  // Available languages
  static const Map<String, Locale> availableLocales = {
    'English': Locale('en', 'US'),
    'नेपाली': Locale('ne', 'NP'), // Nepali
    'हिंदी': Locale('hi', 'IN'), // Hindi
  };

  LanguageProvider() {
    _loadLanguageFromPrefs();
  }

  Locale get currentLocale => _currentLocale;

  String get currentLanguageName {
    for (final entry in availableLocales.entries) {
      if (entry.value.languageCode == _currentLocale.languageCode &&
          entry.value.countryCode == _currentLocale.countryCode) {
        return entry.key;
      }
    }
    return 'English'; // Default fallback
  }

  // Load saved language preference
  Future<void> _loadLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);

    if (languageCode != null && countryCode != null) {
      _currentLocale = Locale(languageCode, countryCode);
      notifyListeners();
    }
  }

  // Save language preference
  Future<void> _saveLanguageToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, _currentLocale.languageCode);
    await prefs.setString(_countryCodeKey, _currentLocale.countryCode!);
  }

  // Change the app language by name
  void setLanguage(String languageName) {
    if (availableLocales.containsKey(languageName)) {
      _currentLocale = availableLocales[languageName]!;
      _saveLanguageToPrefs();
      notifyListeners();
    }
  }

  // Reset to default language (English)
  void resetLanguage() {
    _currentLocale = const Locale('en', 'US');
    _saveLanguageToPrefs();
    notifyListeners();
  }
}
