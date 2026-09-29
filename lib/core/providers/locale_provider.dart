import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be provided at app startup.',
  );
});

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController(ref.watch(sharedPreferencesProvider));
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._preferences)
    : super(Locale(_preferences.getString(_languageCodeKey) ?? 'en'));

  static const _languageCodeKey = 'app_language_code';
  final SharedPreferences _preferences;

  Future<void> setLanguageCode(String languageCode) async {
    if (state.languageCode == languageCode) {
      return;
    }
    state = Locale(languageCode);
    await _preferences.setString(_languageCodeKey, languageCode);
  }
}
