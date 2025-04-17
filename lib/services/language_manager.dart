import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager extends ChangeNotifier {
  static const String LANGUAGE_CODE = 'languageCode';
  late SharedPreferences _prefs;
  late Locale _currentLocale;

  LanguageManager() {
    _currentLocale = Locale('en');
    _loadLanguage();
  }

  Locale get currentLocale => _currentLocale;

  Future<void> _loadLanguage() async {
    _prefs = await SharedPreferences.getInstance();
    String? languageCode = _prefs.getString(LANGUAGE_CODE);
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    await _prefs.setString(LANGUAGE_CODE, languageCode);
    notifyListeners();
  }
} 