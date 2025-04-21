import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final ThemeData themeData;
  final Color primaryColor;

  AppTheme({
    required this.name, 
    required this.themeData, 
    required this.primaryColor
  });
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Define available themes
  final List<AppTheme> _themes = [
    AppTheme(
      name: 'Purple (Default)',
      primaryColor: Colors.purple,
      themeData: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    AppTheme(
      name: 'Blue',
      primaryColor: Colors.blue,
      themeData: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    AppTheme(
      name: 'Green',
      primaryColor: Colors.green,
      themeData: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    AppTheme(
      name: 'Orange',
      primaryColor: Colors.orange,
      themeData: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    ),
    AppTheme(
      name: 'Dark',
      primaryColor: Colors.grey.shade800,
      themeData: ThemeData.dark().copyWith(
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  ];

  // Current theme index
  int _currentThemeIndex = 0;

  // Getters
  ThemeData get currentTheme => _themes[_currentThemeIndex].themeData;
  Color get primaryColor => _themes[_currentThemeIndex].primaryColor;
  List<AppTheme> get themes => _themes;
  int get currentThemeIndex => _currentThemeIndex;
  String get currentThemeName => _themes[_currentThemeIndex].name;

  // Set theme by index
  Future<void> setTheme(int index) async {
    if (index >= 0 && index < _themes.length) {
      _currentThemeIndex = index;
      notifyListeners();
      await _saveThemeToPrefs();
    }
  }

  // Load theme from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_index');
    if (themeIndex != null && themeIndex >= 0 && themeIndex < _themes.length) {
      _currentThemeIndex = themeIndex;
      notifyListeners();
    }
  }

  // Save theme to SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', _currentThemeIndex);
  }
} 