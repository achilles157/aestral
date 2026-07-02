import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pranata_mangsa.dart';

final pranataMangsaListProvider = FutureProvider<List<PranataMangsaModel>>((ref) async {
  final String jsonString = await rootBundle.loadString('assets/weton/pranata_mangsa.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => PranataMangsaModel.fromJson(json)).toList();
});

final pranataMangsaRepositoryProvider = Provider((ref) => PranataMangsaRepository(ref));

class PranataMangsaRepository {
  final Ref _ref;

  PranataMangsaRepository(this._ref);

  Future<PranataMangsaModel?> getMangsaById(int id) async {
    final list = await _ref.read(pranataMangsaListProvider.future);
    try {
      return list.firstWhere((m) => m.id == id);
    } catch (_) {
      return list.isNotEmpty ? list.first : null;
    }
  }
}
