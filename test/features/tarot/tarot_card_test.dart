import 'dart:convert';
import 'dart:io';

import 'package:aestral/features/tarot/models/tarot_card.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit test untuk model [TarotCard] — parsing JSON, helper bilingual,
/// dan round-trip serialisasi.
///
/// Sumber data nyata: `assets/tarot/tarot-merged.json` (78 kartu).
/// Test ini memverifikasi bahwa asumsi model benar-benar cocok dengan data
/// produksi, bukan hanya dengan fixture buatan.
void main() {
  group('TarotCard.fromJson', () {
    test('parse satu kartu lengkap dari payload penuh', () {
      final card = TarotCard.fromJson({
        'id': 0,
        'name_id': 'Sang Pengelana',
        'name_en': 'The Wanderer',
        'suit': 'Major',
        'img': '0.png',
        'keywords_id': ['awal', 'keberanian'],
        'keywords_en': ['beginning', 'courage'],
        'upright_meaning_id': 'Awal perjalanan baru.',
        'reversed_meaning_id': 'Menahan diri.',
        'upright_meaning_en': 'A new journey begins.',
        'reversed_meaning_en': 'Holding back.',
        'fortune_telling_id': ['petualangan'],
        'fortune_telling_en': ['adventure'],
        'questions_to_ask_id': ['Apa yang kutakutkan?'],
        'questions_to_ask_en': ['What do I fear?'],
        'elemental_id': 'Udara',
        'elemental_en': 'Air',
        'archetype_id': 'Sang Pencari',
        'archetype_en': 'The Seeker',
        'numerology_id': '0',
        'numerology_en': '0',
        'mythical_id': 'Mitos A',
        'mythical_en': 'Myth A',
        'image_prompt_keywords_id': 'langit, bintang',
        'image_prompt_keywords_en': 'sky, stars',
        'ai_hook_id': 'Kaitkan dengan keberanian.',
      });

      expect(card.id, 0);
      expect(card.nameId, 'Sang Pengelana');
      expect(card.nameEn, 'The Wanderer');
      expect(card.suit, 'Major');
      expect(card.img, '0.png');
      expect(card.keywordsId, ['awal', 'keberanian']);
      expect(card.keywordsEn, ['beginning', 'courage']);
      expect(card.uprightMeaningId, 'Awal perjalanan baru.');
      expect(card.elementalId, 'Udara');
      expect(card.aiHookId, 'Kaitkan dengan keberanian.');
    });

    test('field hilang → fallback ke string kosong, tidak crash', () {
      final card = TarotCard.fromJson({'id': 5});

      expect(card.id, 5);
      expect(card.nameId, '');
      expect(card.nameEn, '');
      expect(card.suit, '');
      expect(card.keywordsId, isEmpty);
      expect(card.keywordsEn, isEmpty);
      expect(card.uprightMeaningId, '');
      expect(card.aiHookId, '');
    });

    test('fallback legacy: name dipakai kalau name_id tidak ada', () {
      final card = TarotCard.fromJson({'id': 1, 'name': 'Nama Lama'});

      expect(card.nameId, 'Nama Lama');
    });

    test('fallback legacy: upright_meaning dipakai kalau _id tidak ada', () {
      final card = TarotCard.fromJson({
        'id': 2,
        'upright_meaning': 'Arti lama',
        'reversed_meaning': 'Arti terbalik lama',
        'image_prompt_keywords': 'kata kunci lama',
      });

      expect(card.uprightMeaningId, 'Arti lama');
      expect(card.reversedMeaningId, 'Arti terbalik lama');
      expect(card.imagePromptKeywordsId, 'kata kunci lama');
    });

    test('name_id menang atas name kalau keduanya ada', () {
      final card = TarotCard.fromJson({
        'id': 3,
        'name_id': 'Nama Baru',
        'name': 'Nama Lama',
      });

      expect(card.nameId, 'Nama Baru');
    });

    test('list null → jadi list kosong, bukan null', () {
      final card = TarotCard.fromJson({
        'id': 4,
        'keywords_id': null,
        'fortune_telling_id': null,
        'questions_to_ask_id': null,
      });

      expect(card.keywordsId, isNotNull);
      expect(card.keywordsId, isEmpty);
      expect(card.fortuneTellingId, isEmpty);
      expect(card.questionsToAskId, isEmpty);
    });

    test('tipe salah pada id → melempar error (kontrak ketat)', () {
      expect(
        () => TarotCard.fromJson({'id': 'bukan-angka'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('TarotCard bilingual helper', () {
    late TarotCard card;

    setUp(() {
      card = TarotCard.fromJson({
        'id': 10,
        'name_id': 'Nama ID',
        'name_en': 'Name EN',
        'keywords_id': ['id1'],
        'keywords_en': ['en1'],
        'upright_meaning_id': 'Tegak ID',
        'upright_meaning_en': 'Upright EN',
        'reversed_meaning_id': 'Terbalik ID',
        'reversed_meaning_en': 'Reversed EN',
        'fortune_telling_id': ['ramalan id'],
        'fortune_telling_en': ['fortune en'],
        'questions_to_ask_id': ['tanya id'],
        'questions_to_ask_en': ['ask en'],
        'elemental_id': 'Api',
        'elemental_en': 'Fire',
        'archetype_id': 'Arketipe ID',
        'archetype_en': 'Archetype EN',
        'numerology_id': '7',
        'numerology_en': 'seven',
        'mythical_id': 'Mitos ID',
        'mythical_en': 'Myth EN',
      });
    });

    test("lang 'id' mengembalikan varian Indonesia", () {
      expect(card.getName('id'), 'Nama ID');
      expect(card.getKeywords('id'), ['id1']);
      expect(card.getUprightMeaning('id'), 'Tegak ID');
      expect(card.getReversedMeaning('id'), 'Terbalik ID');
      expect(card.getFortuneTelling('id'), ['ramalan id']);
      expect(card.getQuestionsToAsk('id'), ['tanya id']);
      expect(card.getElemental('id'), 'Api');
      expect(card.getArchetype('id'), 'Arketipe ID');
      expect(card.getNumerology('id'), '7');
      expect(card.getMythical('id'), 'Mitos ID');
    });

    test("lang 'en' mengembalikan varian Inggris", () {
      expect(card.getName('en'), 'Name EN');
      expect(card.getKeywords('en'), ['en1']);
      expect(card.getUprightMeaning('en'), 'Upright EN');
      expect(card.getReversedMeaning('en'), 'Reversed EN');
      expect(card.getFortuneTelling('en'), ['fortune en']);
      expect(card.getQuestionsToAsk('en'), ['ask en']);
      expect(card.getElemental('en'), 'Fire');
      expect(card.getArchetype('en'), 'Archetype EN');
      expect(card.getNumerology('en'), 'seven');
      expect(card.getMythical('en'), 'Myth EN');
    });

    test('lang tidak dikenal → fallback ke varian Inggris', () {
      // Kontrak: hanya 'id' yang dianggap Indonesia, sisanya Inggris.
      expect(card.getName('fr'), 'Name EN');
      expect(card.getElemental('xx'), 'Fire');
    });

    test('getter default mengembalikan varian Indonesia (backward compat)', () {
      expect(card.name, 'Nama ID');
      expect(card.keywords, ['id1']);
      expect(card.uprightMeaning, 'Tegak ID');
      expect(card.reversedMeaning, 'Terbalik ID');
    });
  });

  group('TarotCard.toJson round-trip', () {
    test('toJson → fromJson menghasilkan objek setara', () {
      final original = TarotCard.fromJson({
        'id': 21,
        'name_id': 'Dunia',
        'name_en': 'The World',
        'suit': 'Major',
        'img': '21.png',
        'keywords_id': ['selesai'],
        'keywords_en': ['completion'],
        'upright_meaning_id': 'Siklus selesai.',
        'reversed_meaning_id': 'Belum tuntas.',
        'upright_meaning_en': 'Cycle complete.',
        'reversed_meaning_en': 'Incomplete.',
        'fortune_telling_id': ['pencapaian'],
        'fortune_telling_en': ['achievement'],
        'questions_to_ask_id': ['Apa yang selesai?'],
        'questions_to_ask_en': ['What is done?'],
        'elemental_id': 'Tanah',
        'elemental_en': 'Earth',
        'archetype_id': 'Penyelesai',
        'archetype_en': 'Completer',
        'numerology_id': '21',
        'numerology_en': '21',
        'mythical_id': 'Mitos Dunia',
        'mythical_en': 'World Myth',
        'image_prompt_keywords_id': 'globe',
        'image_prompt_keywords_en': 'globe',
        'ai_hook_id': 'Kaitkan dengan penyelesaian.',
      });

      final restored = TarotCard.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.nameId, original.nameId);
      expect(restored.nameEn, original.nameEn);
      expect(restored.suit, original.suit);
      expect(restored.img, original.img);
      expect(restored.keywordsId, original.keywordsId);
      expect(restored.keywordsEn, original.keywordsEn);
      expect(restored.uprightMeaningId, original.uprightMeaningId);
      expect(restored.reversedMeaningEn, original.reversedMeaningEn);
      expect(restored.fortuneTellingId, original.fortuneTellingId);
      expect(restored.questionsToAskEn, original.questionsToAskEn);
      expect(restored.elementalId, original.elementalId);
      expect(restored.archetypeEn, original.archetypeEn);
      expect(restored.numerologyId, original.numerologyId);
      expect(restored.mythicalEn, original.mythicalEn);
      expect(restored.imagePromptKeywordsId, original.imagePromptKeywordsId);
      expect(restored.aiHookId, original.aiHookId);
    });

    test('toJson menghasilkan semua key yang diharapkan', () {
      final card = TarotCard.fromJson({'id': 1});
      final json = card.toJson();

      const expectedKeys = {
        'id',
        'name_id',
        'name_en',
        'suit',
        'img',
        'keywords_id',
        'keywords_en',
        'upright_meaning_id',
        'reversed_meaning_id',
        'upright_meaning_en',
        'reversed_meaning_en',
        'fortune_telling_id',
        'fortune_telling_en',
        'questions_to_ask_id',
        'questions_to_ask_en',
        'elemental_id',
        'elemental_en',
        'archetype_id',
        'archetype_en',
        'numerology_id',
        'numerology_en',
        'mythical_id',
        'mythical_en',
        'image_prompt_keywords_id',
        'image_prompt_keywords_en',
        'ai_hook_id',
      };

      expect(json.keys.toSet(), expectedKeys);
    });
  });

  group('TarotCard — integrasi dengan data produksi', () {
    late List<TarotCard> deck;

    setUpAll(() {
      // Baca asset langsung dari disk (flutter_test tidak menyediakan rootBundle
      // untuk JSON nyata tanpa binding; membaca file lebih deterministik).
      final file = File('assets/tarot/tarot-merged.json');
      final jsonList = json.decode(file.readAsStringSync()) as List<dynamic>;
      deck = jsonList
          .map((e) => TarotCard.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    test('deck berisi 78 kartu (standar tarot lengkap)', () {
      expect(deck.length, 78);
    });

    test('semua id unik dan tidak ada yang negatif', () {
      final ids = deck.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ada id duplikat');
      expect(ids.every((id) => id >= 0), isTrue);
    });

    test('Major Arcana berjumlah 22 (id 0-21)', () {
      final major = deck.where((c) => c.suit == 'Major').toList();
      expect(major.length, 22);
    });

    test('setiap kartu punya nameId & nameEn tidak kosong', () {
      final tanpaNamaId = deck.where((c) => c.nameId.isEmpty).toList();
      final tanpaNamaEn = deck.where((c) => c.nameEn.isEmpty).toList();

      // Nama ID wajib ada — ini yang dipakai UI default.
      expect(
        tanpaNamaId,
        isEmpty,
        reason: 'kartu tanpa nameId: ${tanpaNamaId.map((c) => c.id).toList()}',
      );
      expect(
        tanpaNamaEn,
        isEmpty,
        reason: 'kartu tanpa nameEn: ${tanpaNamaEn.map((c) => c.id).toList()}',
      );
    });

    test('setiap kartu punya makna tegak & terbalik (ID)', () {
      final kurang = deck
          .where(
            (c) => c.uprightMeaningId.isEmpty || c.reversedMeaningId.isEmpty,
          )
          .map((c) => c.id)
          .toList();

      expect(kurang, isEmpty, reason: 'kartu tanpa makna: $kurang');
    });

    test('semua kartu punya keywords minimal 1 (ID)', () {
      final kosong = deck
          .where((c) => c.keywordsId.isEmpty)
          .map((c) => c.id)
          .toList();

      expect(kosong, isEmpty, reason: 'kartu tanpa keywords: $kosong');
    });

    test('nama kartu unik — tidak ada duplikat', () {
      final names = deck.map((c) => c.nameId).toList();
      final duplikat = names
          .where((n) => names.where((x) => x == n).length > 1)
          .toSet()
          .toList();

      expect(duplikat, isEmpty, reason: 'nama duplikat: $duplikat');
    });
  });
}
