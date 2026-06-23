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

  WetonDictionaryEntry({
    required this.id,
    required this.wetonName,
    required this.headline,
    required this.karirRezeki,
    required this.asmaraHubungan,
    required this.sisiGelapPeringatan,
  });

  factory WetonDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return WetonDictionaryEntry(
      id: json['id'] as int,
      wetonName: json['weton_name'] as String,
      headline: json['headline'] as String,
      karirRezeki: json['karir_rezeki'] as String,
      asmaraHubungan: json['asmara_hubungan'] as String,
      sisiGelapPeringatan: json['sisi_gelap_peringatan'] as String,
    );
  }
}

final wetonDictionaryProvider = FutureProvider<List<WetonDictionaryEntry>>((ref) async {
  final String jsonString = await rootBundle.loadString('data/kamus-weton.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => WetonDictionaryEntry.fromJson(json)).toList();
});

WetonDictionaryEntry? lookupWetonEntry(List<WetonDictionaryEntry> list, String wetonName) {
  // Normalize search input
  String target = wetonName.toLowerCase().replaceAll(' ', '');
  if (target == 'seninpon') {
    target = 'senipon'; // Map 'Senin Pon' to 'Seni Pon' to handle the JSON typo robustly
  }

  for (final entry in list) {
    String entryName = entry.wetonName.toLowerCase().replaceAll(' ', '');
    if (entryName == target) {
      return entry;
    }
  }
  return null;
}
