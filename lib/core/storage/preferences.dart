import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local settings. Tokens live in [TokenStorage] instead.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingSeenKey = 'onboarding_seen';
  // Same key the web app uses for the chosen language.
  static const _languageKey = 'pw_language';

  bool get onboardingSeen => _prefs.getBool(_onboardingSeenKey) ?? false;
  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeenKey, true);

  /// Language code, or null to follow the device language.
  String? get languageCode => _prefs.getString(_languageKey);
  Future<void> setLanguageCode(String? code) =>
      code == null ? _prefs.remove(_languageKey) : _prefs.setString(_languageKey, code);
}
