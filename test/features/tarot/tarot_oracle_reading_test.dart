import 'package:aestral/features/tarot/models/tarot_card.dart';
import 'package:aestral/features/tarot/models/tarot_oracle_reading.dart';
import 'package:aestral/features/tarot/providers/tarot_language_provider.dart';
import 'package:aestral/features/tarot/services/tarot_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TarotOracleReading.fromJson', () {
    test('parse payload lengkap', () {
      final reading = TarotOracleReading.fromJson({
        'cardReadings': [
          {'label': 'past', 'narrative': 'Narasi masa lalu'},
          {'label': 'present', 'narrative': 'Narasi masa kini'},
          {'label': 'future', 'narrative': 'Narasi masa depan'},
        ],
        'synthesis': 'Konklusi menyeluruh.',
      });

      expect(reading.cardNarratives.length, 3);
      expect(reading.cardNarratives[0].label, 'past');
      expect(reading.cardNarratives[0].narrative, 'Narasi masa lalu');
      expect(reading.synthesis, 'Konklusi menyeluruh.');
    });

    test('cardReadings hilang → list kosong, bukan crash', () {
      final reading = TarotOracleReading.fromJson({'synthesis': 'Hanya ini.'});

      expect(reading.cardNarratives, isEmpty);
      expect(reading.synthesis, 'Hanya ini.');
    });

    test('synthesis hilang → string kosong', () {
      final reading = TarotOracleReading.fromJson({'cardReadings': []});

      expect(reading.synthesis, '');
    });

    test('narrative null di satu entri → jadi string kosong', () {
      final reading = TarotOracleReading.fromJson({
        'cardReadings': [
          {'label': 'past', 'narrative': null},
        ],
      });

      expect(reading.cardNarratives.length, 1);
      expect(reading.cardNarratives[0].narrative, '');
    });

    test('payload kosong total → objek aman', () {
      final reading = TarotOracleReading.fromJson({});

      expect(reading.cardNarratives, isEmpty);
      expect(reading.synthesis, '');
    });

    test('label non-tema tetap diterima (mendukung label tematik)', () {
      final reading = TarotOracleReading.fromJson({
        'cardReadings': [
          {'label': 'potensi', 'narrative': 'Narasi potensi'},
          {'label': 'daya_tarik', 'narrative': 'Narasi daya tarik'},
        ],
      });

      expect(reading.cardNarratives.length, 2);
      expect(reading.cardNarratives[0].label, 'potensi');
      expect(reading.cardNarratives[1].label, 'daya_tarik');
    });
  });

  group('TarotOracleReading.getNarrativeForLabel', () {
    late TarotOracleReading reading;

    setUp(() {
      reading = TarotOracleReading.fromJson({
        'cardReadings': [
          {'label': 'past', 'narrative': 'Lampau'},
          {'label': 'present', 'narrative': 'Kini'},
          {'label': 'future', 'narrative': 'Depan'},
        ],
        'synthesis': 'Konklusi.',
      });
    });

    test('mengembalikan narasi sesuai label', () {
      expect(reading.getNarrativeForLabel('past'), 'Lampau');
      expect(reading.getNarrativeForLabel('present'), 'Kini');
      expect(reading.getNarrativeForLabel('future'), 'Depan');
    });

    test('label tidak ada → string kosong (tidak melempar)', () {
      expect(reading.getNarrativeForLabel('tidak-ada'), '');
      expect(reading.getNarrativeForLabel(''), '');
    });

    test('label duplikat → mengembalikan yang pertama', () {
      final dup = TarotOracleReading.fromJson({
        'cardReadings': [
          {'label': 'past', 'narrative': 'Pertama'},
          {'label': 'past', 'narrative': 'Kedua'},
        ],
      });

      expect(dup.getNarrativeForLabel('past'), 'Pertama');
    });

    test('list kosong → string kosong', () {
      final kosong = TarotOracleReading.fromJson({});
      expect(kosong.getNarrativeForLabel('past'), '');
    });
  });

  group('DrawnCardNotifier', () {
    late List<TarotCard> deck;

    setUp(() {
      deck = List.generate(
        10,
        (i) => TarotCard.fromJson({'id': i, 'name_id': 'Kartu $i'}),
      );
    });

    test('state awal adalah null (belum ada penarikan)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(drawnCardProvider), isNull);
    });

    test('drawCard menghasilkan tepat 3 kartu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(drawnCardProvider.notifier).drawCard(deck);
      final drawn = container.read(drawnCardProvider);

      expect(drawn, isNotNull);
      expect(drawn!.length, 3);
    });

    test('drawCard memberi label past/present/future berurutan', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(drawnCardProvider.notifier).drawCard(deck);
      final drawn = container.read(drawnCardProvider)!;

      expect(drawn[0].label, 'past');
      expect(drawn[1].label, 'present');
      expect(drawn[2].label, 'future');
    });

    test('drawCard tidak menghasilkan kartu duplikat', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Ulangi beberapa kali untuk menangkap potensi duplikasi acak.
      for (var i = 0; i < 20; i++) {
        container.read(drawnCardProvider.notifier).drawCard(deck);
        final drawn = container.read(drawnCardProvider)!;
        final ids = drawn.map((d) => d.card.id).toList();

        expect(ids.toSet().length, 3, reason: 'duplikat pada iterasi $i: $ids');
      }
    });

    test('drawCard pada deck < 3 kartu → state tetap null (tidak crash)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(drawnCardProvider.notifier).drawCard([deck[0], deck[1]]);

      expect(container.read(drawnCardProvider), isNull);
    });

    test('drawCard pada deck kosong → state tetap null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(drawnCardProvider.notifier).drawCard([]);

      expect(container.read(drawnCardProvider), isNull);
    });

    test('drawCard pada deck tepat 3 kartu → berhasil', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(drawnCardProvider.notifier)
          .drawCard(deck.take(3).toList());
      final drawn = container.read(drawnCardProvider)!;

      expect(drawn.length, 3);
      expect(drawn.map((d) => d.card.id).toSet().length, 3);
    });

    test('setCards menetapkan state secara langsung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cards = [
        DrawnCardInfo(card: deck[0], isReversed: false, label: 'past'),
        DrawnCardInfo(card: deck[1], isReversed: true, label: 'present'),
      ];
      container.read(drawnCardProvider.notifier).setCards(cards);

      final state = container.read(drawnCardProvider)!;
      expect(state.length, 2);
      expect(state[1].isReversed, isTrue);
      expect(state[1].label, 'present');
    });

    test('reset mengembalikan state ke null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(drawnCardProvider.notifier).drawCard(deck);
      expect(container.read(drawnCardProvider), isNotNull);

      container.read(drawnCardProvider.notifier).reset();
      expect(container.read(drawnCardProvider), isNull);
    });

    test('drawCard bisa dipanggil ulang — menimpa hasil sebelumnya', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(drawnCardProvider.notifier).drawCard(deck);
      final first = container.read(drawnCardProvider)!;

      container.read(drawnCardProvider.notifier).drawCard(deck);
      final second = container.read(drawnCardProvider)!;

      expect(first.length, 3);
      expect(second.length, 3);
    });
  });

  group('DrawnCardInfo', () {
    test('menyimpan card, isReversed, dan label', () {
      final card = TarotCard.fromJson({'id': 7, 'name_id': 'Kartu 7'});
      final info = DrawnCardInfo(card: card, isReversed: true, label: 'future');

      expect(info.card.id, 7);
      expect(info.isReversed, isTrue);
      expect(info.label, 'future');
    });
  });

  group('TarotLanguageNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test("default bahasa adalah 'id' sebelum prefs dimuat", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tarotLanguageProvider), 'id');
    });

    test('setLanguage mengubah state ke nilai baru', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(tarotLanguageProvider.notifier).setLanguage('en');

      expect(container.read(tarotLanguageProvider), 'en');
    });

    test('setLanguage menyimpan ke SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(tarotLanguageProvider.notifier).setLanguage('en');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tarot_language'), 'en');
    });

    test('setLanguage bisa bolak-balik id ↔ en', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tarotLanguageProvider.notifier);

      await notifier.setLanguage('en');
      expect(container.read(tarotLanguageProvider), 'en');

      await notifier.setLanguage('id');
      expect(container.read(tarotLanguageProvider), 'id');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tarot_language'), 'id');
    });

    test(
      'nilai tersimpan dibaca kembali saat provider dibangun ulang',
      () async {
        SharedPreferences.setMockInitialValues({'tarot_language': 'en'});

        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(tarotLanguageProvider), 'id'); // sinkron awal

        // Beri kesempatan _loadFromPrefs menyelesaikan (async).
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(container.read(tarotLanguageProvider), 'en');
      },
    );
  });
}
