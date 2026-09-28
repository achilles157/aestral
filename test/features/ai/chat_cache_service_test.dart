import 'dart:convert';

import 'package:aestral/features/ai/models/chat_message.dart';
import 'package:aestral/features/ai/services/chat_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit test untuk [ChatCacheService] — persistensi riwayat chat lokal
/// di SharedPreferences, termasuk perilaku trim FIFO 20 pesan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const historyKey = 'aestral_chat_history';

  ChatMessage pesan(int i, {String role = 'user'}) => ChatMessage(
    id: 'msg-$i',
    role: role,
    text: 'Pesan ke-$i',
    timestamp: DateTime(2026, 9, 28, 10, 0, 0).add(Duration(minutes: i)),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatCacheService.loadHistory', () {
    test('tanpa data tersimpan → list kosong', () async {
      final history = await ChatCacheService.loadHistory();
      expect(history, isEmpty);
    });

    test('memuat pesan yang tersimpan dengan urutan benar', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        historyKey,
        json.encode([pesan(1).toJson(), pesan(2, role: 'model').toJson()]),
      );

      final history = await ChatCacheService.loadHistory();

      expect(history.length, 2);
      expect(history[0].id, 'msg-1');
      expect(history[0].role, 'user');
      expect(history[1].id, 'msg-2');
      expect(history[1].role, 'model');
    });

    test('JSON rusak → list kosong, tidak melempar', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(historyKey, 'ini bukan json {{{');

      final history = await ChatCacheService.loadHistory();

      expect(history, isEmpty);
    });

    test('JSON valid tapi bukan list → list kosong', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(historyKey, json.encode({'bukan': 'list'}));

      final history = await ChatCacheService.loadHistory();

      expect(history, isEmpty);
    });

    test(
      'list berisi item cacat → list kosong (dibungkus try/catch)',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          historyKey,
          json.encode([
            {'id': 'x'},
          ]),
        );

        final history = await ChatCacheService.loadHistory();

        expect(history, isEmpty);
      },
    );

    test('array kosong → list kosong', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(historyKey, '[]');

      final history = await ChatCacheService.loadHistory();

      expect(history, isEmpty);
    });
  });

  group('ChatCacheService.saveMessage', () {
    test('menyimpan satu pesan', () async {
      await ChatCacheService.saveMessage(pesan(1));

      final history = await ChatCacheService.loadHistory();

      expect(history.length, 1);
      expect(history[0].id, 'msg-1');
      expect(history[0].text, 'Pesan ke-1');
    });

    test('menambahkan pesan berikutnya di akhir (append)', () async {
      await ChatCacheService.saveMessage(pesan(1));
      await ChatCacheService.saveMessage(pesan(2));

      final history = await ChatCacheService.loadHistory();

      expect(history.length, 2);
      expect(history[0].id, 'msg-1');
      expect(history[1].id, 'msg-2');
    });

    test('menyimpan pesan dengan kartu tetap utuh', () async {
      final denganKartu = ChatMessage(
        id: 'kartu',
        role: 'model',
        text: 'Lihat ini',
        timestamp: DateTime(2026, 1, 1),
        card: const OracleCard(
          type: 'checklist',
          data: {
            'items': ['a'],
          },
        ),
      );

      await ChatCacheService.saveMessage(denganKartu);
      final history = await ChatCacheService.loadHistory();

      expect(history.single.card, isNotNull);
      expect(history.single.card!.type, 'checklist');
    });
  });

  group('ChatCacheService — trim FIFO 20 pesan', () {
    test('menyimpan tepat 20 pesan tanpa trim', () async {
      for (var i = 1; i <= 20; i++) {
        await ChatCacheService.saveMessage(pesan(i));
      }

      final history = await ChatCacheService.loadHistory();

      expect(history.length, 20);
      expect(history.first.id, 'msg-1');
      expect(history.last.id, 'msg-20');
    });

    test('pesan ke-21 membuang yang paling lama', () async {
      for (var i = 1; i <= 21; i++) {
        await ChatCacheService.saveMessage(pesan(i));
      }

      final history = await ChatCacheService.loadHistory();

      expect(history.length, 20);
      expect(history.first.id, 'msg-2', reason: 'msg-1 seharusnya terbuang');
      expect(history.last.id, 'msg-21');
    });

    test('menyimpan 25 pesan → hanya 20 terakhir yang tersisa', () async {
      for (var i = 1; i <= 25; i++) {
        await ChatCacheService.saveMessage(pesan(i));
      }

      final history = await ChatCacheService.loadHistory();

      expect(history.length, 20);
      expect(history.first.id, 'msg-6');
      expect(history.last.id, 'msg-25');
    });

    test('urutan tetap kronologis setelah trim', () async {
      for (var i = 1; i <= 30; i++) {
        await ChatCacheService.saveMessage(pesan(i));
      }

      final history = await ChatCacheService.loadHistory();
      final ids = history.map((m) => m.id).toList();

      expect(ids, List.generate(20, (i) => 'msg-${i + 11}'));
    });
  });

  group('ChatCacheService.clearHistory', () {
    test('menghapus seluruh riwayat', () async {
      await ChatCacheService.saveMessage(pesan(1));
      await ChatCacheService.saveMessage(pesan(2));
      expect((await ChatCacheService.loadHistory()).length, 2);

      await ChatCacheService.clearHistory();
      final history = await ChatCacheService.loadHistory();

      expect(history, isEmpty);
    });

    test('dipanggil dua kali tetap aman (idempoten)', () async {
      await ChatCacheService.saveMessage(pesan(1));

      await ChatCacheService.clearHistory();
      await ChatCacheService.clearHistory();

      expect(await ChatCacheService.loadHistory(), isEmpty);
    });

    test('setelah clear, bisa menyimpan lagi', () async {
      await ChatCacheService.saveMessage(pesan(1));
      await ChatCacheService.clearHistory();

      await ChatCacheService.saveMessage(pesan(99));
      final history = await ChatCacheService.loadHistory();

      expect(history.length, 1);
      expect(history.single.id, 'msg-99');
    });
  });
}
