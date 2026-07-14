import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'tarot_language';

class TarotLanguageNotifier extends Notifier<String> {
  @override
  String build() {
    _loadFromPrefs();
    return 'id'; // default sebelum prefs dimuat
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLangKey);
    if (saved != null && saved != state) {
      state = saved;
    }
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, lang);
  }
}

// Stores active language code: 'id' (Indonesian, default) or 'en' (English)
final tarotLanguageProvider = NotifierProvider<TarotLanguageNotifier, String>(
  () {
    return TarotLanguageNotifier();
  },
);
