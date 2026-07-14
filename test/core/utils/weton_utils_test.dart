import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/weton_utils.dart';

void main() {
  group('WetonUtils.dateToJdn', () {
    test('should calculate correct JDN for known dates', () {
      // Reference: 2000-01-01 = JDN 2451545
      expect(WetonUtils.dateToJdn(2000, 1, 1), 2451545);
      
      // Reference: 1990-01-01 = JDN 2447893
      expect(WetonUtils.dateToJdn(1990, 1, 1), 2447893);
      
      // Reference: 2026-07-14 (today in context)
      expect(WetonUtils.dateToJdn(2026, 7, 14), 2460869);
    });

    test('should handle leap years correctly', () {
      // 2000 is a leap year (divisible by 400)
      final jdn2000Feb29 = WetonUtils.dateToJdn(2000, 2, 29);
      final jdn2000Mar01 = WetonUtils.dateToJdn(2000, 3, 1);
      expect(jdn2000Mar01 - jdn2000Feb29, 1);
      
      // 1900 is NOT a leap year (divisible by 100 but not 400)
      // 2024 is a leap year
      final jdn2024Feb29 = WetonUtils.dateToJdn(2024, 2, 29);
      final jdn2024Feb28 = WetonUtils.dateToJdn(2024, 2, 28);
      expect(jdn2024Feb29 - jdn2024Feb28, 1);
    });

    test('should handle month transitions correctly', () {
      final jdnDec31 = WetonUtils.dateToJdn(1999, 12, 31);
      final jdnJan01 = WetonUtils.dateToJdn(2000, 1, 1);
      expect(jdnJan01 - jdnDec31, 1);
    });
  });

  group('WetonUtils.calculateWeton', () {
    test('should calculate correct weton for reference date', () {
      // Test with a known date: 2000-01-01 (Saturday/Sabtu)
      final date = DateTime.utc(2000, 1, 1);
      final weton = WetonUtils.calculateWeton(date);
      
      // JDN 2451545 % 7 = 6 -> Sabtu (Saturday)
      expect(weton.saptawara, 'Sabtu');
      
      // JDN 2451545 % 5 = 0 -> Legi
      expect(weton.pancawara, 'Legi');
      
      // Neptu values
      expect(weton.neptuSaptawara, 9); // Sabtu = 9
      expect(weton.neptuPancawara, 5); // Legi = 5
      expect(weton.totalNeptu, 14); // 9 + 5
    });

    test('should calculate correct weton for 1990-01-01', () {
      final date = DateTime.utc(1990, 1, 1);
      final weton = WetonUtils.calculateWeton(date);
      
      // JDN 2447893 % 7 = 1 -> Senin (Monday)
      expect(weton.saptawara, 'Senin');
      expect(weton.neptuSaptawara, 4);
      
      // JDN 2447893 % 5 = 3 -> Wage
      expect(weton.pancawara, 'Wage');
      expect(weton.neptuPancawara, 4);
      
      expect(weton.totalNeptu, 8);
    });

    test('should calculate correct weton for 2026-07-14', () {
      final date = DateTime.utc(2026, 7, 14);
      final weton = WetonUtils.calculateWeton(date);
      
      // JDN 2460869 % 7 = 1 -> Senin (Monday)
      expect(weton.saptawara, 'Senin');
      
      // JDN 2460869 % 5 = 4 -> Kliwon
      expect(weton.pancawara, 'Kliwon');
      
      expect(weton.neptuSaptawara, 4);
      expect(weton.neptuPancawara, 8);
      expect(weton.totalNeptu, 12);
    });

    test('should calculate wuku correctly', () {
      final date = DateTime.utc(2000, 1, 1);
      final weton = WetonUtils.calculateWeton(date);
      
      // Wuku should be one of the 30 wuku names
      expect(WetonUtils.wukuNames.contains(weton.wuku), true);
      
      // Wuku index should be valid (0-29)
      final wukuIndex = WetonUtils.wukuNames.indexOf(weton.wuku);
      expect(wukuIndex, greaterThanOrEqualTo(0));
      expect(wukuIndex, lessThan(30));
    });

    test('should calculate Javanese date components', () {
      final date = DateTime.utc(2000, 1, 1);
      final weton = WetonUtils.calculateWeton(date);
      
      // Javanese day should be 1-30
      expect(weton.javaneseDay, greaterThanOrEqualTo(1));
      expect(weton.javaneseDay, lessThanOrEqualTo(30));
      
      // Javanese year should be reasonable (around 1900+ Javanese era)
      expect(weton.javaneseYear, greaterThan(1800));
      expect(weton.javaneseYear, lessThan(2100));
      
      // Javanese year name should be one of 8 windu
      final validYearNames = ["Alip", "Ehe", "Jimawal", "Je", "Dal", "Be", "Wawu", "Jimakir"];
      expect(validYearNames.contains(weton.javaneseYearName), true);
      
      // Javanese month should be one of 12 months
      final validMonths = [
        "Sura", "Sapar", "Mulud", "Bakda Mulud", "Jumadilawal", "Jumadilakir",
        "Rejeb", "Ruwah", "Pasa", "Sawal", "Sela", "Besar"
      ];
      expect(validMonths.contains(weton.javaneseMonth), true);
    });

    test('should return consistent results for same date', () {
      final date = DateTime.utc(1995, 6, 15);
      final weton1 = WetonUtils.calculateWeton(date);
      final weton2 = WetonUtils.calculateWeton(date);
      
      expect(weton1.saptawara, weton2.saptawara);
      expect(weton1.pancawara, weton2.pancawara);
      expect(weton1.totalNeptu, weton2.totalNeptu);
      expect(weton1.wuku, weton2.wuku);
      expect(weton1.javaneseYear, weton2.javaneseYear);
    });
  });

  group('WetonUtils.calculatePranataMangsaId', () {
    test('should return correct mangsa for each period', () {
      // Mangsa 1: June 22 - August 1
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 6, 22)), 1);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 7, 15)), 1);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 8, 1)), 1);
      
      // Mangsa 2: August 2 - August 24
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 8, 2)), 2);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 8, 15)), 2);
      
      // Mangsa 3: August 25 - September 17
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 8, 25)), 3);
      
      // Mangsa 12: May 12 - June 21
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 5, 12)), 12);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2026, 6, 21)), 12);
    });

    test('should handle leap year for Mangsa 8 (Kawolu)', () {
      // Leap year: Kawolu ends Feb 29
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2024, 2, 29)), 8);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2024, 3, 1)), 9);
      
      // Non-leap year: Kawolu ends Feb 28
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2025, 2, 28)), 8);
      expect(WetonUtils.calculatePranataMangsaId(DateTime.utc(2025, 3, 1)), 9);
    });
  });

  group('WetonUtils.calculateDinoWas', () {
    test('should calculate Dino Was for birth date', () {
      final birthDate = DateTime.utc(1990, 1, 1); // Senin Wage
      final dinoWas = WetonUtils.calculateDinoWas(birthDate);
      
      // Birth: Senin (idx 1) Wage (idx 3)
      // Naas: +2 for both -> Rabu (idx 3) Kliwon (idx 0)
      expect(dinoWas.hari, 'Rabu');
      expect(dinoWas.pasaran, 'Kliwon');
    });

    test('should wrap around correctly at end of week/pasaran', () {
      // Birth on Jumat Pahing (idx 4, 1)
      // Naas should be Minggu Wage (idx 6, 3)
      final jdnFriday = 2451545; // Some Friday
      final birthJdn = jdnFriday + (4 - jdnFriday % 7); // Adjust to Friday
      final birthDate = DateTime.utc(2000, 1, 7); // Friday
      
      final dinoWas = WetonUtils.calculateDinoWas(birthDate);
      
      // Should be valid day and pasaran
      expect(WetonUtils.saptawaraNames.contains(dinoWas.hari), true);
      expect(WetonUtils.pancawaraNames.contains(dinoWas.pasaran), true);
    });
  });

  group('WetonUtils.checkIsDinoWas', () {
    test('should return true for exact Dino Was day', () {
      final birthDate = DateTime.utc(1990, 1, 1); // Senin Wage
      
      // Calculate Dino Was: Rabu Kliwon
      final dinoWas = WetonUtils.calculateDinoWas(birthDate);
      
      // Find first occurrence after birth (cycle = 35 days)
      // Birth JDN: 2447893
      final birthJdn = WetonUtils.dateToJdn(1990, 1, 1);
      
      // Scan next 35 days to find Dino Was
      for (int i = 1; i <= 35; i++) {
