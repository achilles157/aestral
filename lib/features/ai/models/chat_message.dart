/// Model untuk satu pesan dalam sesi multi-turn chat dengan Aestral Oracle.
/// Mendukung riwayat percakapan dan kartu UI interaktif dari Structured Output.
class ChatMessage {
  final String id;
  final String role; // 'user' | 'model'
  final String text;
  final DateTime timestamp;
  final OracleCard? card;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.card,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'user',
      text: json['text'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      card: json['card'] != null
          ? OracleCard.fromJson(json['card'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        if (card != null) 'card': card!.toJson(),
      };

  /// Converts this message to Gemini chat history format (role + parts).
  Map<String, dynamic> toGeminiContent() => {
        'role': role,
        'parts': [
          {'text': text}
        ],
      };
}

/// Kartu UI interaktif opsional yang menyertai pesan oracle.
/// Tiga tipe yang didukung: checklist, element_bar, key_insight.
class OracleCard {
  final String type; // 'checklist' | 'element_bar' | 'key_insight'
  final Map<String, dynamic> data;

  const OracleCard({required this.type, required this.data});

  factory OracleCard.fromJson(Map<String, dynamic> json) {
    return OracleCard(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'data': data};
}
