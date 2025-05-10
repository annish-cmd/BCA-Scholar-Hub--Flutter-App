import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  double _textSize = 14.0; // Base text size
  double get textSize => _textSize;

  // Keys for SharedPreferences
  static const String _themeKey = 'isDarkMode';
  static const String _textSizeKey = 'textSize';

  ThemeProvider() {
    _loadPrefs();
  }

  // Load preferences from SharedPreferences
  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _textSize = prefs.getDouble(_textSizeKey) ?? 14.0;
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  // Save text size to SharedPreferences
  Future<void> _saveTextSizeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, _textSize);
  }

  // Toggle between light and dark theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // Update text size
  void setTextSize(double size) {
    _textSize = size;
    _saveTextSizeToPrefs();
    notifyListeners();
  }

  // Reset all settings to default
  void resetSettings() {
    _isDarkMode = false;
    _textSize = 14.0;
    _saveThemeToPrefs();
    _saveTextSizeToPrefs();
    notifyListeners();
  }

  // Get scale factor for text
  double get textScaleFactor {
    return _textSize / 14.0; // 14.0 is our base size
  }

  // Light theme data
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.black,
          fontSize: 26 * textScaleFactor,
        ),
        displayMedium: TextStyle(
          color: Colors.black,
          fontSize: 22 * textScaleFactor,
        ),
        displaySmall: TextStyle(
          color: Colors.black,
          fontSize: 18 * textScaleFactor,
        ),
        headlineLarge: TextStyle(
          color: Colors.black,
          fontSize: 24 * textScaleFactor,
        ),
        headlineMedium: TextStyle(
          color: Colors.black,
          fontSize: 20 * textScaleFactor,
        ),
        headlineSmall: TextStyle(
          color: Colors.black,
          fontSize: 18 * textScaleFactor,
        ),
        titleLarge: TextStyle(
          color: Colors.black,
          fontSize: 18 * textScaleFactor,
        ),
        titleMedium: TextStyle(
          color: Colors.black,
          fontSize: 16 * textScaleFactor,
        ),
        titleSmall: TextStyle(
          color: Colors.black,
          fontSize: 14 * textScaleFactor,
        ),
        bodyLarge: TextStyle(
          color: Colors.black,
          fontSize: 16 * textScaleFactor,
        ),
        bodyMedium: TextStyle(
          color: Colors.black,
          fontSize: 14 * textScaleFactor,
        ),
        bodySmall: TextStyle(
          color: Colors.black,
          fontSize: 12 * textScaleFactor,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.purple,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
    );
  }

  // Dark theme data
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontSize: 26 * textScaleFactor,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontSize: 22 * textScaleFactor,
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontSize: 18 * textScaleFactor,
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 24 * textScaleFactor,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 20 * textScaleFactor,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontSize: 18 * textScaleFactor,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18 * textScaleFactor,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 16 * textScaleFactor,
        ),
        titleSmall: TextStyle(
          color: Colors.white,
          fontSize: 14 * textScaleFactor,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 16 * textScaleFactor,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: 14 * textScaleFactor,
        ),
        bodySmall: TextStyle(
          color: Colors.white,
          fontSize: 12 * textScaleFactor,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blue,
        secondary: Colors.purple,
        surface: const Color(0xFF1F1F1F),
        onSurface: Colors.white,
      ),
      cardColor: const Color(0xFF1F1F1F),
      dividerColor: Colors.grey.shade800,
    );
  }
}
