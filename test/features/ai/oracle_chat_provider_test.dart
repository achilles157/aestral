import 'package:aestral/features/ai/providers/oracle_chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit test untuk konfigurasi oracle & logika state provider yang
/// **tidak memerlukan jaringan** (pill kontekstual, greeting milestone,
/// rotasi pill, increment counter tamu).
///
/// Alur yang memanggil `ApiService` sengaja tidak diuji di sini —
/// itu ranah integration test dengan server tiruan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('kOracleConfigs — 4 persona oracle', () {
    test('berisi tepat 4 oracle: weton, bazi, tarot, synthesis', () {
      expect(kOracleConfigs.keys.toSet(), {
        'weton',
        'bazi',
        'tarot',
        'synthesis',
      });
    });

    test('key map sesuai dengan field type di dalamnya (konsistensi)', () {
      kOracleConfigs.forEach((key, config) {
        expect(config.type, key, reason: 'key "$key" != type "${config.type}"');
      });
    });

    test('setiap oracle punya nama persona, judul, warna, dan latar', () {
      for (final entry in kOracleConfigs.entries) {
        final c = entry.value;
        expect(c.name, isNotEmpty, reason: '${entry.key} tanpa nama persona');
        expect(
          c.greetingTitle,
          isNotEmpty,
          reason: '${entry.key} tanpa greeting title',
        );
        expect(c.bgAsset, isNotEmpty, reason: '${entry.key} tanpa bg asset');
      }
    });

    test('nama persona sesuai keputusan produk', () {
      expect(kOracleConfigs['weton']!.name, 'Ki Sabdo');
      expect(kOracleConfigs['bazi']!.name, 'Suhu Wang');
      expect(kOracleConfigs['tarot']!.name, 'Madame Sophia');
      expect(kOracleConfigs['synthesis']!.name, 'Sesepuh Kosmis');
    });

    test('warna aksen keempat oracle berbeda satu sama lain', () {
      final colors = kOracleConfigs.values.map((c) => c.accentColor).toList();
      expect(colors.toSet().length, colors.length);
    });
  });

  group('kSuggestionPools', () {
    test('setiap oracle punya pool pill yang tidak kosong', () {
      for (final key in kOracleConfigs.keys) {
        expect(
          kSuggestionPools[key],
          isNotNull,
          reason: 'pool untuk "$key" tidak ada',
        );
        expect(
          kSuggestionPools[key]!,
          isNotEmpty,
          reason: 'pool untuk "$key" kosong',
        );
      }
    });

    test('pool weton punya minimal 6 pilihan (untuk rotasi)', () {
      expect(kSuggestionPools['weton']!.length, greaterThanOrEqualTo(6));
    });

    test('tidak ada pill duplikat dalam satu pool', () {
      kSuggestionPools.forEach((key, pool) {
        expect(
          pool.toSet().length,
          pool.length,
          reason: 'pool "$key" punya duplikat',
        );
      });
    });
  });

  group('OracleChatState — copyWith', () {
    test('default state: kosong, tidak loading, belum dibuka', () {
      const s = OracleChatState();

      expect(s.messages, isEmpty);
      expect(s.isLoading, isFalse);
      expect(s.isFirstOpen, isTrue);
      expect(s.errorMessage, isNull);
      expect(s.isRateLimited, isFalse);
      expect(s.guestMessageCount, 0);
    });

    test('copyWith mengganti field yang diberikan saja', () {
      const s = OracleChatState();
      final baru = s.copyWith(isLoading: true, guestMessageCount: 3);

      expect(baru.isLoading, isTrue);
      expect(baru.guestMessageCount, 3);
      expect(baru.isFirstOpen, isTrue, reason: 'field lain harus tetap');
      expect(baru.messages, isEmpty);
    });

    test('clearError menghapus errorMessage', () {
      const s = OracleChatState(errorMessage: 'ada error');
      expect(s.errorMessage, 'ada error');

      final baru = s.copyWith(clearError: true);
      expect(baru.errorMessage, isNull);
    });

    test('clearError menang atas errorMessage baru', () {
      const s = OracleChatState(errorMessage: 'lama');
      final baru = s.copyWith(errorMessage: 'baru', clearError: true);

      expect(baru.errorMessage, isNull);
    });

    test('copyWith tanpa argumen mempertahankan semua nilai', () {
      const s = OracleChatState(
        isLoading: true,
        isRateLimited: true,
        rateLimitSeconds: 120,
        guestMessageCount: 5,
      );

      final baru = s.copyWith();

      expect(baru.isLoading, isTrue);
      expect(baru.isRateLimited, isTrue);
      expect(baru.rateLimitSeconds, 120);
      expect(baru.guestMessageCount, 5);
    });
  });

  group('OracleChatNotifier — state awal', () {
    ProviderContainer buat(String oracleType) {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(oracleChatProvider(oracleType));
      return c;
    }

    test('state awal untuk tiap oracle type adalah default kosong', () {
      for (final type in kOracleConfigs.keys) {
        final container = buat(type);
        final state = container.read(oracleChatProvider(type));

        expect(state.messages, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.availablePills, isEmpty);
      }
    });

    test(
      'setiap oracle type punya notifier sendiri dengan type yang benar',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final nWeton = container.read(oracleChatProvider('weton').notifier);
        final nBazi = container.read(oracleChatProvider('bazi').notifier);

        expect(identical(nWeton, nBazi), isFalse);
        expect(nWeton.oracleType, 'weton');
        expect(nBazi.oracleType, 'bazi');
      },
    );

    test('key lokal antar oracle type saling independen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Isi topik untuk weton saja.
      await container.read(oracleChatProvider('weton').notifier).initialize();

      // Tarot belum diinisialisasi → tidak boleh melihat data weton.
      final tarot = container.read(oracleChatProvider('tarot'));

      expect(tarot.lastTopic, isNull);
      expect(tarot.isFirstOpen, isTrue);
    });
  });

  group('initialize — greeting milestone & pill', () {
    Future<ProviderContainer> init(
      String type, {
      Map<String, dynamic>? aiContext,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(oracleChatProvider(type).notifier)
          .initialize(aiContext: aiContext);
      return container;
    }

    test('pembukaan pertama → isFirstOpen true', () async {
      final container = await init('weton');
      final state = container.read(oracleChatProvider('weton'));

      expect(state.isFirstOpen, isTrue);
      expect(state.daysSinceLastOpen, 0);
    });

    test('pembukaan pertama menyimpan timestamp', () async {
      await init('weton');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('oracle_weton_lastOpenTimestamp'), isNotNull);
    });

    test('pembukaan kedua → isFirstOpen false', () async {
      await init('weton');

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      await container2.read(oracleChatProvider('weton').notifier).initialize();

      expect(container2.read(oracleChatProvider('weton')).isFirstOpen, isFalse);
    });

    test('pembukaan setelah 3 hari → daysSinceLastOpen >= 3', () async {
      final tigaHariLalu = DateTime.now()
          .subtract(const Duration(days: 3))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'oracle_weton_lastOpenTimestamp': tigaHariLalu,
      });

      final container = await init('weton');
      final state = container.read(oracleChatProvider('weton'));

      expect(state.isFirstOpen, isFalse);
      expect(state.daysSinceLastOpen, greaterThanOrEqualTo(3));
    });

    test('membaca lastTopic yang tersimpan sebelumnya', () async {
      SharedPreferences.setMockInitialValues({
        'oracle_bazi_lastTopic': 'Karier dan ambisi',
      });

      final container = await init('bazi');

      expect(
        container.read(oracleChatProvider('bazi')).lastTopic,
        'Karier dan ambisi',
      );
    });

    test('membaca lastSessionSummary yang tersimpan sebelumnya', () async {
      SharedPreferences.setMockInitialValues({
        'oracle_tarot_session_summary': 'Ringkasan sesi lalu',
      });

      final container = await init('tarot');

      expect(
        container.read(oracleChatProvider('tarot')).lastSessionSummary,
        'Ringkasan sesi lalu',
      );
    });

    test('tanpa aiContext → 3 pill dari pool', () async {
      final container = await init('weton');
      final state = container.read(oracleChatProvider('weton'));

      expect(state.availablePills.length, 3);
      expect(
        state.availablePills.every(
          (p) => kSuggestionPools['weton']!.contains(p),
        ),
        isTrue,
      );
    });

    test('key lokal per-oracle tidak saling bocor', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(oracleChatProvider('weton').notifier).initialize();
      await container.read(oracleChatProvider('tarot').notifier).initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('oracle_weton_lastOpenTimestamp'), isNotNull);
      expect(prefs.getInt('oracle_tarot_lastOpenTimestamp'), isNotNull);
    });
  });
}
