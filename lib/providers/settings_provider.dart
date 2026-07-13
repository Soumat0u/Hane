import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama tercihleri — SharedPreferences ile kalıcı.
/// Tema, dil, biyometrik kilit, bildirim ve para birimi ayarlarını tutar.
class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'pref_theme_mode';
  static const _kBiometric = 'pref_biometric';
  static const _kPinEnabled = 'pref_pin_enabled';
  static const _kNotifications = 'pref_notifications';
  static const _kLocale = 'pref_locale';

  ThemeMode _themeMode = ThemeMode.light;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _notificationsEnabled = true;
  Locale _locale = const Locale('tr');

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get biometricEnabled => _biometricEnabled;
  // Gerçek PIN değeri PinService'te (güvenli depo) tutulur; burada sadece
  // kilit ekranının PIN modunu gösterip göstermeyeceği bilgisi tutulur.
  bool get pinEnabled => _pinEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  Locale get locale => _locale;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  SettingsProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tm = prefs.getString(_kThemeMode);
    _themeMode = tm == 'dark'
        ? ThemeMode.dark
        : tm == 'system'
            ? ThemeMode.system
            : ThemeMode.light;
    _biometricEnabled = prefs.getBool(_kBiometric) ?? false;
    _pinEnabled = prefs.getBool(_kPinEnabled) ?? false;
    _notificationsEnabled = prefs.getBool(_kNotifications) ?? true;
    _locale = Locale(prefs.getString(_kLocale) ?? 'tr');
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, value ? 'dark' : 'light');
  }

  Future<void> setBiometric(bool value) async {
    _biometricEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometric, value);
  }

  Future<void> setPinEnabled(bool value) async {
    _pinEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPinEnabled, value);
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, languageCode);
  }
}
