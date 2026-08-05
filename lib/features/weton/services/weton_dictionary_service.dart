import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WetonDictionaryEntry {
  final int id;
  final String wetonName;
  final String headline;
  final String karirRezeki;
  final String asmaraHubungan;
  final String sisiGelapPeringatan;
  final String aiHook;
  final String? warnaHarmoni;
  final String? saranHarian;

  WetonDictionaryEntry({
    required this.id,
    required this.wetonName,
    required this.headline,
    required this.karirRezeki,
    required this.asmaraHubungan,
    required this.sisiGelapPeringatan,
    required this.aiHook,
    this.warnaHarmoni,
    this.saranHarian,
  });

  factory WetonDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return WetonDictionaryEntry(
      id: json['id'] as int,
      wetonName: json['weton_name'] as String,
      headline: json['headline'] as String,
      karirRezeki: json['karir_rezeki'] as String,
      asmaraHubungan: json['asmara_hubungan'] as String,
      sisiGelapPeringatan: json['sisi_gelap_peringatan'] as String,
      aiHook:
          json['ai_hook'] as String? ??
          'Bagaimana pengaruh Weton ${json['weton_name']} saya terhadap nasib dan sisi gelap karakter saya?',
      warnaHarmoni: json['warna_harmoni'] as String?,
      saranHarian: json['saran_harian'] as String?,
    );
  }
}

final wetonDictionaryProvider = FutureProvider<List<WetonDictionaryEntry>>((
  ref,
) async {
  final String jsonString = await rootBundle.loadString(
    'assets/weton/kamus-weton.json',
  );
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => WetonDictionaryEntry.fromJson(json)).toList();
});

final sisaBagiProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final String jsonString = await rootBundle.loadString(
    'assets/weton/sisabagi.json',
  );
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.cast<Map<String, dynamic>>();
});

final wukuProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final String jsonString = await rootBundle.loadString(
    'assets/weton/wuku.json',
  );
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.cast<Map<String, dynamic>>();
});

WetonDictionaryEntry? lookupWetonEntry(
  List<WetonDictionaryEntry> list,
  String wetonName,
) {
  // Normalize search input
  String target = wetonName.toLowerCase().replaceAll(' ', '');
  if (target == 'seninpon') {
    target =
        'senipon'; // Map 'Senin Pon' to 'Seni Pon' to handle the JSON typo robustly
  }

  for (final entry in list) {
    String entryName = entry.wetonName.toLowerCase().replaceAll(' ', '');
    if (entryName == target) {
      return entry;
    }
  }
  return null;
}

// ─── Planner Label ───────────────────────────────────────────────────────────

class PlannerLabelEntry {
  final String id;
  final String label;
  final String kategori;
  final String deskripsiPsikologis;
  final List<String> rekomendasiAktivitas;
  final String aiHook;

  PlannerLabelEntry({
    required this.id,
    required this.label,
    required this.kategori,
    required this.deskripsiPsikologis,
    required this.rekomendasiAktivitas,
    required this.aiHook,
  });

  factory PlannerLabelEntry.fromJson(Map<String, dynamic> json) {
    return PlannerLabelEntry(
      id: json['id'] as String,
      label: json['label'] as String,
      kategori: json['kategori'] as String,
      deskripsiPsikologis: json['deskripsi_psikologis'] as String,
      rekomendasiAktivitas: (json['rekomendasi_aktivitas'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      aiHook: json['ai_hook'] as String? ?? '',
    );
  }
}

final plannerLabelProvider = FutureProvider<List<PlannerLabelEntry>>((
  ref,
) async {
  final String jsonString = await rootBundle.loadString(
    'assets/weton/kamus-label-planner.json',
  );
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((j) => PlannerLabelEntry.fromJson(j as Map<String, dynamic>))
      .toList();
});

PlannerLabelEntry? lookupPlannerLabel(List<PlannerLabelEntry> list, String id) {
  try {
    return list.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
}

// ─── Weton Compatibility ──────────────────────────────────────────────────────

class WetonCompatibility {
  final int neptu1;
  final int neptu2;
  final int sisaBagi;
  final String namaFase;
  final String arketipeRelasi;
  final String dinamikaPsikologis;
  final String potensiGesekan;
  final String saranKomunikasi;
  final String aiHook;

  const WetonCompatibility({
    required this.neptu1,
    required this.neptu2,
    required this.sisaBagi,
    required this.namaFase,
    required this.arketipeRelasi,
    required this.dinamikaPsikologis,
    required this.potensiGesekan,
    required this.saranKomunikasi,
    required this.aiHook,
  });

  factory WetonCompatibility.fromJson(Map<String, dynamic> json) {
    return WetonCompatibility(
      neptu1: json['neptu1'] as int,
      neptu2: json['neptu2'] as int,
      sisaBagi: json['sisa_bagi'] as int,
      namaFase: json['nama_fase'] as String,
      arketipeRelasi: json['arketipe_relasi'] as String,
      dinamikaPsikologis: json['dinamika_psikologis'] as String,
      potensiGesekan: json['potensi_gesekan'] as String,
      saranKomunikasi: json['saran_komunikasi'] as String,
      aiHook: json['ai_hook'] as String? ?? '',
    );
  }
}

// ─── Ba Zi Compatibility Models ──────────────────────────────────────────────

class BaziCompatibilityDetail {
  final String type;
  final String label;
  final String description;

  const BaziCompatibilityDetail({
    required this.type,
    required this.label,
    required this.description,
  });

  factory BaziCompatibilityDetail.fromJson(Map<String, dynamic> json) {
    return BaziCompatibilityDetail(
      type: json['type'] as String? ?? 'neutral',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class BaziCompatibility {
  final BaziCompatibilityDetail dayMasterMatch;
  final BaziCompatibilityDetail spousePalaceMatch;
  final BaziCompatibilityDetail monthPillarMatch;
  final BaziCompatibilityDetail zodiacMatch;
  final BaziCompatibilityDetail elementCompatibility;
  final int compatibilityScore;

  const BaziCompatibility({
    required this.dayMasterMatch,
    required this.spousePalaceMatch,
    required this.monthPillarMatch,
    required this.zodiacMatch,
    required this.elementCompatibility,
    required this.compatibilityScore,
  });

  factory BaziCompatibility.fromJson(Map<String, dynamic> json) {
    BaziCompatibilityDetail detail(String key) {
      final v = json[key];
      if (v is Map<String, dynamic>) return BaziCompatibilityDetail.fromJson(v);
      return const BaziCompatibilityDetail(
        type: 'neutral',
        label: '-',
        description: '',
      );
    }

    return BaziCompatibility(
      dayMasterMatch: detail('dayMasterMatch'),
      spousePalaceMatch: detail('spousePalaceMatch'),
      monthPillarMatch: detail('monthPillarMatch'),
      zodiacMatch: detail('zodiacMatch'),
      elementCompatibility: detail('elementCompatibility'),
      compatibilityScore: json['compatibilityScore'] as int? ?? 60,
    );
  }
}

class SynthesisCompatibility {
  final WetonCompatibility weton;
  final BaziCompatibility bazi;

  const SynthesisCompatibility({required this.weton, required this.bazi});

  factory SynthesisCompatibility.fromJson(Map<String, dynamic> json) {
    return SynthesisCompatibility(
      weton: WetonCompatibility.fromJson(json['weton'] as Map<String, dynamic>),
      bazi: BaziCompatibility.fromJson(json['bazi'] as Map<String, dynamic>),
    );
  }
}
