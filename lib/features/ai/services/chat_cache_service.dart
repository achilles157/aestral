import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// Layanan caching riwayat chat lokal menggunakan SharedPreferences.
/// Menyimpan maksimal 20 percakapan terakhir (FIFO).
class ChatCacheService {
  static const String _historyKey = 'aestral_chat_history';
  static const int _maxMessages = 20;

  /// Muat semua riwayat chat yang tersimpan secara lokal.
  static Future<List<ChatMessage>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_historyKey);
      if (jsonStr == null) return [];
      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } catch (e) {
      debugPrint('ChatCacheService.loadHistory error: $e');
      return [];
    }
  }

  /// Simpan satu pesan baru ke riwayat.
  /// Jika sudah mencapai batas [_maxMessages], hapus pesan paling lama.
  static Future<void> saveMessage(ChatMessage message) async {
    try {
      final history = await loadHistory();
      history.add(message);

      // Trim ke maxMessages terakhir (FIFO)
      final trimmed = history.length > _maxMessages
          ? history.sublist(history.length - _maxMessages)
          : history;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _historyKey,
        json.encode(trimmed.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('ChatCacheService.saveMessage error: $e');
    }
  }

  /// Hapus seluruh riwayat chat lokal.
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('ChatCacheService.clearHistory error: $e');
    }
  }
}
