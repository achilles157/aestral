import 'package:flutter_riverpod/flutter_riverpod.dart';

class TarotLanguageNotifier extends Notifier<String> {
  @override
  String build() {
    return 'id'; // default language
  }

  void setLanguage(String lang) {
    state = lang;
  }
}

// Stores active language code: 'id' (Indonesian, default) or 'en' (English)
final tarotLanguageProvider = NotifierProvider<TarotLanguageNotifier, String>(() {
  return TarotLanguageNotifier();
});
