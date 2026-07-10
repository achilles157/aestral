import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../../../core/services/api_service.dart';

// ── Konfigurasi per Oracle Type ─────────────────────────────────────────────

class OracleConfig {
  final String type;
  final String name;
  final String greetingTitle;
  final int accentColor;
  final String bgAsset;

  const OracleConfig({
    required this.type,
    required this.name,
    required this.greetingTitle,
    required this.accentColor,
    required this.bgAsset,
  });
}

const Map<String, OracleConfig> kOracleConfigs = {
  'weton': OracleConfig(
    type: 'weton',
    name: 'Ki Sabdo',
    greetingTitle: 'Oracle Weton',
    accentColor: 0xFFD4AF37, // Emas perunggu
    bgAsset: 'assets/images/weton_bg.png',
  ),
  'bazi': OracleConfig(
    type: 'bazi',
    name: 'Suhu Wang',
    greetingTitle: 'Oracle Ba Zi',
    accentColor: 0xFF00BFA5, // Teal / giok
    bgAsset: 'assets/images/bazi_bg.png',
  ),
  'tarot': OracleConfig(
    type: 'tarot',
    name: 'Madame Sophia',
    greetingTitle: 'Oracle Tarot',
    accentColor: 0xFFBA68C8, // Violet / pink magenta
    bgAsset: 'assets/images/tarot_bg.png',
  ),
  'synthesis': OracleConfig(
    type: 'synthesis',
    name: 'Sesepuh Kosmis',
    greetingTitle: 'Grand Reading',
    accentColor: 0xFF5C6BC0, // Deep indigo
    bgAsset: 'assets/images/mandala_bg.png',
  ),
};

// ── Suggestion Pills Pool ────────────────────────────────────────────────────

const Map<String, List<String>> kSuggestionPools = {
  'weton': [
    '💼 Karier & Rezeki',
    '❤️ Asmara & Kecocokan',
    '🔮 Ritual Penyelarasan Energi',
    '🌙 Mimpi & Pertanda',
    '👨‍👩‍👧 Keluarga & Hubungan Darah',
    '💰 Keuangan & Keberlimpahan',
  ],
  'bazi': [
    '🌱 Karier & Ambisi',
    '💧 Keseimbangan Emosiku',
    '🔥 Energi & Motivasi',
    '⚖️ Kekuatan & Kelemahan Day Master',
    '🌀 Da Yun Aktifku Sekarang',
    '🤝 Hubungan & Dinamika',
  ],
  'tarot': [
    '🃏 Arti Kartuku Minggu Ini',
    '⚠️ Sisi Gelap & Peringatan',
    '🧘 Solusi Masalah Batin',
    '🔮 Apa yang Tersembunyi?',
    '🌟 Potensi Terbesarku Saat Ini',
  ],
  'synthesis': [
    '🌌 Benang Merah Tiga Sistem',
    '⚡ Energi Dominan Saat Ini',
    '🎯 Fokus Utama Hidupku',
    '🔄 Pola yang Berulang',
    '✨ Pesan Kosmis Untukku',
  ],
};

// ── State Model ──────────────────────────────────────────────────────────────

class OracleChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool isRateLimited;
  final int rateLimitSeconds;
  final List<String> availablePills;
  final bool isFirstOpen;
  final int daysSinceLastOpen;
  final String? lastTopic;

  const OracleChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isRateLimited = false,
    this.rateLimitSeconds = 0,
    this.availablePills = const [],
    this.isFirstOpen = true,
    this.daysSinceLastOpen = 0,
    this.lastTopic,
  });

  OracleChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isRateLimited,
    int? rateLimitSeconds,
    List<String>? availablePills,
    bool? isFirstOpen,
    int? daysSinceLastOpen,
    String? lastTopic,
  }) {
    return OracleChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRateLimited: isRateLimited ?? this.isRateLimited,
      rateLimitSeconds: rateLimitSeconds ?? this.rateLimitSeconds,
      availablePills: availablePills ?? this.availablePills,
      isFirstOpen: isFirstOpen ?? this.isFirstOpen,
      daysSinceLastOpen: daysSinceLastOpen ?? this.daysSinceLastOpen,
      lastTopic: lastTopic ?? this.lastTopic,
    );
  }
}

// ── Provider Family ──────────────────────────────────────────────────────────

final oracleChatProvider = NotifierProvider.family<
    OracleChatNotifier, OracleChatState, String>(
  (String oracleType) => OracleChatNotifier(oracleType),
);

// ── Notifier ─────────────────────────────────────────────────────────────────

class OracleChatNotifier extends Notifier<OracleChatState> {
  final String oracleType;
  OracleChatNotifier(this.oracleType);

  @override
  OracleChatState build() {
    return const OracleChatState();
  }

  // Local storage key helpers
  String get _tsKey => 'oracle_${oracleType}_lastOpenTimestamp';
  String get _topicKey => 'oracle_${oracleType}_lastTopic';
  String get _pillsKey => 'oracle_${oracleType}_usedPills';

  /// Pill 1 selalu kontekstual berdasarkan data oracle yang tersedia (logic lokal, tanpa LLM).
  String? _buildContextualPill(Map<String, dynamic>? aiContext) {
    if (aiContext == null) return null;
    switch (oracleType) {
      case 'weton':
        final neptu = aiContext['wetonLahir']?['neptu'];
        if (neptu is int) {
          return neptu >= 14
              ? '⚡ Momentum apa yang bisa kumanfaatkan hari ini?'
              : '🛡️ Bagaimana cara menjaga energi hari ini?';
        }
        return null;
      case 'bazi':
        final dominant = aiContext['baziChart']?['wuXingBalance']?['dominant'];
        if (dominant is String && dominant.isNotEmpty) {
          const elementPills = {
            'kayu': '🌱 Bagaimana energi Kayu membentuk jalanku?',
            'api': '🔥 Bagaimana energi Api membentuk jalanku?',
            'tanah': '🏔️ Bagaimana energi Tanah membentuk jalanku?',
            'logam': '⚔️ Bagaimana energi Logam membentuk jalanku?',
            'air': '💧 Bagaimana energi Air membentuk jalanku?',
          };
          return elementPills[dominant.toLowerCase()];
        }
        return null;
      case 'tarot':
        final cards = aiContext['tarotCards'];
        if (cards is List && cards.isNotEmpty) {
          final presentCard = cards.firstWhere(
            (c) => c['label'] == 'present',
            orElse: () => cards[0],
          );
          final name = presentCard['name'] as String? ?? '';
          if (name.isNotEmpty) return '🃏 Apa pesan terdalam dari kartu $name?';
        }
        return null;
      case 'synthesis':
        return '🌌 Apa benang merah dari semua sistemku saat ini?';
      default:
        return null;
    }
  }

  /// Inisialisasi state dari local storage saat layar dibuka.
  Future<void> initialize({Map<String, dynamic>? aiContext}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTs = prefs.getInt(_tsKey);
    final now = DateTime.now();

    final isFirstOpen = lastTs == null;
    int daysSince = 0;
    if (lastTs != null) {
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTs);
      daysSince = now.difference(lastDate).inDays;
    }

    final lastTopic = prefs.getString(_topicKey);
    final usedPillsJson = prefs.getString(_pillsKey);
    final usedPills = usedPillsJson != null
        ? (json.decode(usedPillsJson) as List).cast<String>()
        : <String>[];

    // Pill 1 selalu kontekstual; Pill 2–3 rotate dari pool
    final pool = kSuggestionPools[oracleType] ?? [];
    final available = pool.where((p) => !usedPills.contains(p)).toList();
    final contextualPill = _buildContextualPill(aiContext);
    final rotatingSlots = contextualPill != null ? 2 : 3;
    final rotating = available.isNotEmpty
        ? available.take(rotatingSlots).toList()
        : pool.take(rotatingSlots).toList();
    final pills = [
      if (contextualPill != null) contextualPill,
      ...rotating,
    ];

    // Update last open timestamp
    await prefs.setInt(_tsKey, now.millisecondsSinceEpoch);

    state = state.copyWith(
      isFirstOpen: isFirstOpen,
      daysSinceLastOpen: daysSince,
      lastTopic: lastTopic,
      availablePills: pills,
    );
  }

  /// Kirim pesan ke Oracle. Otomatis mengelola history multi-turn dan local storage.
  Future<void> sendMessage({
    required String prompt,
    required String authHeader,
    Map<String, dynamic>? context,
    bool isSilent = false,
  }) async {
    if (state.isLoading) return;

    final userMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      role: 'user',
      text: prompt,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: isSilent ? state.messages : [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      // Build Gemini-format history (exclude the current user message if it was added to state.messages)
      final historyForApi = isSilent
          ? state.messages.map((m) => m.toGeminiContent()).toList()
          : state.messages
              .take(state.messages.length - 1) // exclude msg baru
              .map((m) => m.toGeminiContent())
              .toList();

      final result = await ApiService.sendOracleChat(
        oracleType: oracleType,
        prompt: prompt,
        authHeader: authHeader,
        chatHistory: historyForApi,
        isFirstOpen: state.isFirstOpen,
        daysSinceLastOpen: state.daysSinceLastOpen,
        lastTopic: state.lastTopic,
        context: context,
      );

      final messageText = result['message'] as String? ?? '';

      // Parse card opsional — failsafe
      OracleCard? card;
      try {
        final cardData = result['card'];
        if (cardData is Map<String, dynamic>) {
          card = OracleCard.fromJson(cardData);
        }
      } catch (e) {
        debugPrint('OracleChatProvider: card parse error (non-fatal): $e');
      }

      final modelMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_model',
        role: 'model',
        text: messageText,
        timestamp: DateTime.now(),
        card: card,
      );

      // Update last topic dari prompt user (ambil 50 karakter pertama)
      final topicSnippet = prompt.length > 50 ? '${prompt.substring(0, 50)}...' : prompt;
      await _saveLastTopic(topicSnippet);

      state = state.copyWith(
        messages: [...state.messages, modelMsg],
        isLoading: false,
        // Setelah first message terkirim, sudah bukan first open lagi
        isFirstOpen: false,
      );
    } catch (e) {
      final errStr = e.toString();
      String userMsg2;
      bool isRateLimit = false;
      int rateLimitSec = 0;

      if (errStr.contains('RATE_LIMIT:')) {
        isRateLimit = true;
        rateLimitSec = int.tryParse(errStr.split('RATE_LIMIT:').last) ?? 60;
        userMsg2 = 'Oracle sedang bermeditasi. Coba lagi dalam $rateLimitSec detik.';
      } else {
        userMsg2 = 'Koneksi ke dunia kosmis terputus. Oracle akan kembali segera.';
      }

      final errorModelMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_error',
        role: 'model',
        text: userMsg2,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorModelMsg],
        isLoading: false,
        errorMessage: errStr,
        isRateLimited: isRateLimit,
        rateLimitSeconds: rateLimitSec,
      );
    }
  }

  /// Tandai sebuah pill sudah digunakan (untuk rotasi).
  Future<void> markPillUsed(String pill) async {
    final prefs = await SharedPreferences.getInstance();
    final usedJson = prefs.getString(_pillsKey);
    final used = usedJson != null
        ? (json.decode(usedJson) as List).cast<String>()
        : <String>[];

    if (!used.contains(pill)) {
      used.add(pill);
    }

    // Reset jika semua sudah dipakai; fresh adalah satu-satunya sumber kebenaran
    final pool = kSuggestionPools[oracleType] ?? [];
    final fresh = used.length >= pool.length ? <String>[] : used;
    await prefs.setString(_pillsKey, json.encode(fresh));

    // Refresh pills dari fresh (bukan stale used) agar reset langsung efektif
    final usedSet = fresh.toSet();
    final remaining = pool.where((p) => !usedSet.contains(p)).toList();
    final nextPills = remaining.isNotEmpty
        ? remaining.take(3).toList()
        : pool.take(3).toList();
    state = state.copyWith(availablePills: nextPills);
  }

  Future<void> _saveLastTopic(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topicKey, topic);
  }

  void clearError() => state = state.copyWith(clearError: true);
}
