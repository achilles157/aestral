import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/features/weton/services/weton_dictionary_service.dart';

void main() {
  // ─── WetonCompatibility.fromJson ─────────────────────────────────────────

  group('WetonCompatibility.fromJson', () {
    final baseJson = {
      'neptu1': 13,
      'neptu2': 11,
      'sisa_bagi': 2,
      'nama_fase': 'Pesthi',
      'arketipe_relasi': 'Jiwa Kembar',
      'dinamika_psikologis': 'Saling melengkapi.',
      'potensi_gesekan': 'Ego beradu.',
      'saran_komunikasi': 'Bicara jujur.',
    };

    test('parses all fields correctly', () {
      final json = {...baseJson, 'ai_hook': 'Pertanyaan AI'};
      final result = WetonCompatibility.fromJson(json);
      expect(result.neptu1, 13);
      expect(result.neptu2, 11);
      expect(result.namaFase, 'Pesthi');
      expect(result.aiHook, 'Pertanyaan AI');
    });

    test('ai_hook null → fallback empty string (tidak crash)', () {
      final json = {...baseJson, 'ai_hook': null};
      expect(() => WetonCompatibility.fromJson(json), returnsNormally);
      final result = WetonCompatibility.fromJson(json);
      expect(result.aiHook, '');
    });

    test('ai_hook missing → fallback empty string (tidak crash)', () {
      expect(() => WetonCompatibility.fromJson(baseJson), returnsNormally);
      final result = WetonCompatibility.fromJson(baseJson);
      expect(result.aiHook, '');
    });
  });

  // ─── BaziCompatibilityDetail.fromJson ────────────────────────────────────

  group('BaziCompatibilityDetail.fromJson', () {
    test('parses all fields correctly', () {
      final result = BaziCompatibilityDetail.fromJson({
        'type': 'harmonious',
        'label': 'Selaras',
        'description': 'Energi mengalir.',
      });
      expect(result.type, 'harmonious');
      expect(result.label, 'Selaras');
      expect(result.description, 'Energi mengalir.');
    });

    test('semua field null → fallback defaults (tidak crash)', () {
      expect(
        () => BaziCompatibilityDetail.fromJson({
          'type': null,
          'label': null,
          'description': null,
        }),
        returnsNormally,
      );
      final result = BaziCompatibilityDetail.fromJson({
        'type': null,
        'label': null,
        'description': null,
      });
      expect(result.type, 'neutral');
      expect(result.label, '');
      expect(result.description, '');
    });
  });

  // ─── BaziCompatibility.fromJson ──────────────────────────────────────────

  group('BaziCompatibility.fromJson', () {
    Map<String, dynamic> makeDetail(String type) => {
      'type': type,
      'label': type,
      'description': '$type desc',
    };

    final fullJson = {
      'dayMasterMatch': makeDetail('harmonious'),
      'spousePalaceMatch': makeDetail('neutral'),
      'monthPillarMatch': makeDetail('challenging'),
      'zodiacMatch': makeDetail('harmonious'),
      'elementCompatibility': makeDetail('neutral'),
      'compatibilityScore': 75,
    };

    test('parses full JSON correctly', () {
      final result = BaziCompatibility.fromJson(fullJson);
      expect(result.dayMasterMatch.type, 'harmonious');
      expect(result.compatibilityScore, 75);
    });

    test('dayMasterMatch null → neutral fallback (tidak crash)', () {
      final json = {...fullJson, 'dayMasterMatch': null};
      expect(() => BaziCompatibility.fromJson(json), returnsNormally);
      final result = BaziCompatibility.fromJson(json);
      expect(result.dayMasterMatch.type, 'neutral');
      expect(result.dayMasterMatch.label, '-');
    });

    test('semua 5 field null → semua neutral fallback (tidak crash)', () {
      final json = {
        'dayMasterMatch': null,
        'spousePalaceMatch': null,
        'monthPillarMatch': null,
        'zodiacMatch': null,
        'elementCompatibility': null,
        'compatibilityScore': null,
      };
      expect(() => BaziCompatibility.fromJson(json), returnsNormally);
      final result = BaziCompatibility.fromJson(json);
      expect(result.dayMasterMatch.type, 'neutral');
      expect(result.zodiacMatch.type, 'neutral');
      expect(result.compatibilityScore, 60);
    });

    test('compatibilityScore null → fallback 60', () {
      final json = {...fullJson, 'compatibilityScore': null};
      final result = BaziCompatibility.fromJson(json);
      expect(result.compatibilityScore, 60);
    });
  });
}
