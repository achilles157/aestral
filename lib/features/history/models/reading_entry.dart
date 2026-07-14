/// Model ringkasan satu sesi pembacaan/kalkulasi kosmis.
/// Disimpan ke SharedPreferences via [ReadingHistoryService].
class ReadingEntry {
  final String id;
  final String type; // 'weton' | 'bazi' | 'tarot'
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final int accentColor;

  const ReadingEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.accentColor,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'subtitle': subtitle,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'accentColor': accentColor,
  };

  factory ReadingEntry.fromJson(Map<String, dynamic> j) => ReadingEntry(
    id: j['id'] as String,
    type: j['type'] as String,
    title: j['title'] as String,
    subtitle: j['subtitle'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
    accentColor: j['accentColor'] as int,
  );
}
