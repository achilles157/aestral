import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widgets/city_search_sheet.dart';

/// Shared service untuk load dan parse daftar kota dari CSV asset.
///
/// Dipakai oleh BaziCalculatorScreen, DashboardScreen, dan WetonCalculatorScreen.
/// Menyertakan validasi per-baris sehingga baris malformed di-skip dengan aman.
class CityService {
  CityService._(); // prevent instantiation

  /// Loads [CityPreset] list dari `assets/data/lat_long_kota_kab.csv`.
  ///
  /// Format CSV yang diharapkan: kolom ke-4 = nama kota, ke-5 = latitude, ke-6 = longitude
  /// (0-indexed: [3], [4], [5]).
  ///
  /// Validasi yang dilakukan per baris:
  /// - Minimal 6 kolom
  /// - Latitude dan longitude harus parseable sebagai double
  /// - Koordinat harus berada dalam batas wilayah Indonesia
  ///   (lat: −11° s/d +6°, lng: 95° s/d 141°)
  ///
  /// Returns minimal fallback list (hanya "Koordinat Kustom") jika file gagal dimuat.
  static Future<List<CityPreset>> loadCitiesFromCsv() async {
    try {
      final String csv = await rootBundle.loadString(
        'assets/data/lat_long_kota_kab.csv',
      );
      final lines = csv.split('\n');
      final cities = <CityPreset>[
        const CityPreset(
          name: 'Koordinat Kustom',
          latitude: 0.0,
          longitude: 0.0,
        ),
      ];

      // Start at 1 to skip header row
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final tokens = line.split(',');

        // Must have at least 6 columns: [0..2] metadata, [3] name, [4] lat, [5] lng
        if (tokens.length < 6) {
          debugPrint(
            'CityService: skipping malformed line $i (${tokens.length} cols): $line',
          );
          continue;
        }

        final name = tokens[3].trim();
        final lat = double.tryParse(tokens[4].trim());
        final lng = double.tryParse(tokens[5].trim());

        // lat/lng must be valid numbers
        if (lat == null || lng == null) {
          debugPrint(
            'CityService: skipping invalid coords at line $i — lat=$lat lng=$lng',
          );
          continue;
        }

        // Must be within Indonesia geographic bounds
        if (lat < -11 || lat > 6 || lng < 95 || lng > 141) {
          debugPrint(
            'CityService: skipping out-of-bounds coords at line $i — $lat, $lng',
          );
          continue;
        }

        cities.add(
          CityPreset(
            name: _formatCityName(name),
            latitude: lat,
            longitude: lng,
          ),
        );
      }

      // Sort alphabetically, keep "Koordinat Kustom" pinned at index 0
      if (cities.length > 1) {
        final custom = cities.removeAt(0);
        cities.sort((a, b) => a.name.compareTo(b.name));
        cities.insert(0, custom);
      }

      return cities;
    } catch (e) {
      debugPrint('CityService: error loading CSV — $e');
      return const [
        CityPreset(name: 'Koordinat Kustom', latitude: 0.0, longitude: 0.0),
      ];
    }
  }

  /// Title-cases each word in a city name.
  /// E.g. "KOTA BANDUNG" → "Kota Bandung"
  static String _formatCityName(String name) {
    if (name.isEmpty) return '';
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
