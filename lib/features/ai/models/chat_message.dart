/// Model untuk menyimpan satu sesi tanya-jawab dengan Aestral Oracle.
/// Digunakan untuk caching lokal via SharedPreferences.
class ChatMessage {
  final String id;
  final String prompt;
  final String response;
  final DateTime timestamp;
  final String contextTitle;

  const ChatMessage({
    required this.id,
    required this.prompt,
    required this.response,
    required this.timestamp,
    required this.contextTitle,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      response: json['response'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      contextTitle: json['context_title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'response': response,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'context_title': contextTitle,
    };
  }
}
