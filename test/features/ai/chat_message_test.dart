import 'package:aestral/features/ai/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit test untuk model [ChatMessage] & [OracleCard] — serialisasi,
/// format riwayat Gemini, dan ketahanan terhadap payload cacat.
void main() {
  group('ChatMessage.fromJson', () {
    test('parse pesan lengkap tanpa kartu', () {
      final ts = DateTime(2026, 9, 28, 12, 30);
      final msg = ChatMessage.fromJson({
        'id': 'msg-1',
        'role': 'user',
        'text': 'Apa arti weton saya?',
        'timestamp': ts.millisecondsSinceEpoch,
      });

      expect(msg.id, 'msg-1');
      expect(msg.role, 'user');
      expect(msg.text, 'Apa arti weton saya?');
      expect(msg.timestamp, ts);
      expect(msg.card, isNull);
    });

    test('parse pesan dengan OracleCard', () {
      final msg = ChatMessage.fromJson({
        'id': 'msg-2',
        'role': 'model',
        'text': 'Ini panduanmu.',
        'timestamp': 0,
        'card': {
          'type': 'checklist',
          'data': {
            'items': ['Langkah 1', 'Langkah 2'],
          },
        },
      });

      expect(msg.card, isNotNull);
      expect(msg.card!.type, 'checklist');
      expect(msg.card!.data['items'], ['Langkah 1', 'Langkah 2']);
    });

    test('role hilang → default user', () {
      final msg = ChatMessage.fromJson({
        'id': 'x',
        'text': 'halo',
        'timestamp': 0,
      });

      expect(msg.role, 'user');
    });

    test('card null eksplisit → tetap null', () {
      final msg = ChatMessage.fromJson({
        'id': 'x',
        'text': 'halo',
        'timestamp': 0,
        'card': null,
      });

      expect(msg.card, isNull);
    });

    test('id hilang → melempar error (field wajib)', () {
      expect(
        () => ChatMessage.fromJson({'text': 'x', 'timestamp': 0}),
        throwsA(isA<TypeError>()),
      );
    });

    test('text hilang → melempar error (field wajib)', () {
      expect(
        () => ChatMessage.fromJson({'id': 'x', 'timestamp': 0}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ChatMessage.toJson round-trip', () {
    test('round-trip tanpa kartu', () {
      final original = ChatMessage(
        id: 'a',
        role: 'model',
        text: 'Teks',
        timestamp: DateTime(2026, 1, 2, 3, 4, 5),
      );

      final restored = ChatMessage.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.role, original.role);
      expect(restored.text, original.text);
      expect(restored.timestamp, original.timestamp);
      expect(restored.card, isNull);
    });

    test('round-trip dengan kartu', () {
      final original = ChatMessage(
        id: 'b',
        role: 'model',
        text: 'Teks',
        timestamp: DateTime(2026, 5, 5),
        card: const OracleCard(
          type: 'key_insight',
          data: {'title': 'Wawasan', 'body': 'Isi'},
        ),
      );

      final restored = ChatMessage.fromJson(original.toJson());

      expect(restored.card, isNotNull);
      expect(restored.card!.type, 'key_insight');
      expect(restored.card!.data['title'], 'Wawasan');
    });

    test('toJson tidak menyertakan key card kalau card null', () {
      final msg = ChatMessage(
        id: 'c',
        role: 'user',
        text: 'x',
        timestamp: DateTime(2026, 1, 1),
      );

      expect(msg.toJson().containsKey('card'), isFalse);
    });

    test('toJson menyertakan key card kalau card ada', () {
      final msg = ChatMessage(
        id: 'd',
        role: 'model',
        text: 'x',
        timestamp: DateTime(2026, 1, 1),
        card: const OracleCard(type: 'checklist', data: {}),
      );

      expect(msg.toJson().containsKey('card'), isTrue);
    });

    test('timestamp disimpan sebagai millisecondsSinceEpoch', () {
      final ts = DateTime(2026, 9, 28, 10, 20, 30);
      final msg = ChatMessage(id: 'e', role: 'user', text: 'x', timestamp: ts);

      expect(msg.toJson()['timestamp'], ts.millisecondsSinceEpoch);
    });
  });

  group('ChatMessage.toGeminiContent', () {
    test('menghasilkan format role + parts yang diharapkan Gemini', () {
      final msg = ChatMessage(
        id: 'x',
        role: 'model',
        text: 'Balasan oracle',
        timestamp: DateTime(2026, 1, 1),
      );

      final content = msg.toGeminiContent();

      expect(content.keys.toSet(), {'role', 'parts'});
      expect(content['role'], 'model');
      expect(content['parts'], [
        {'text': 'Balasan oracle'},
      ]);
    });

    test('role user dipertahankan apa adanya', () {
      final msg = ChatMessage(
        id: 'x',
        role: 'user',
        text: 'Pertanyaan',
        timestamp: DateTime(2026, 1, 1),
      );

      expect(msg.toGeminiContent()['role'], 'user');
    });

    test('kartu tidak ikut dikirim ke Gemini (hanya teks)', () {
      final msg = ChatMessage(
        id: 'x',
        role: 'model',
        text: 'Teks saja',
        timestamp: DateTime(2026, 1, 1),
        card: const OracleCard(type: 'checklist', data: {'a': 1}),
      );

      final content = msg.toGeminiContent();
      expect(content.containsKey('card'), isFalse);
      expect((content['parts'] as List).length, 1);
    });

    test('teks kosong tetap menghasilkan satu part', () {
      final msg = ChatMessage(
        id: 'x',
        role: 'model',
        text: '',
        timestamp: DateTime(2026, 1, 1),
      );

      expect(msg.toGeminiContent()['parts'], [
        {'text': ''},
      ]);
    });
  });

  group('OracleCard', () {
    test('parse tipe dan data', () {
      final card = OracleCard.fromJson({
        'type': 'element_bar',
        'data': {
          'elements': ['kayu', 'api'],
        },
      });

      expect(card.type, 'element_bar');
      expect(card.data['elements'], ['kayu', 'api']);
    });

    test('data hilang → map kosong, tidak crash', () {
      final card = OracleCard.fromJson({'type': 'checklist'});

      expect(card.type, 'checklist');
      expect(card.data, isEmpty);
    });

    test('data null eksplisit → map kosong', () {
      final card = OracleCard.fromJson({'type': 'checklist', 'data': null});

      expect(card.data, isEmpty);
    });

    test('type hilang → melempar error (field wajib)', () {
      expect(
        () => OracleCard.fromJson({'data': {}}),
        throwsA(isA<TypeError>()),
      );
    });

    test('round-trip toJson/fromJson', () {
      const original = OracleCard(
        type: 'key_insight',
        data: {
          'title': 'T',
          'nested': {'x': 1},
        },
      );

      final restored = OracleCard.fromJson(original.toJson());

      expect(restored.type, original.type);
      expect(restored.data['title'], 'T');
      expect((restored.data['nested'] as Map)['x'], 1);
    });
  });
}
