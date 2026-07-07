import 'package:aestral/features/weton/domain/pranata_mangsa.dart';
import 'package:aestral/features/weton/presentation/widgets/seasonal_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SeasonalBanner renders active Mangsa info correctly', (WidgetTester tester) async {
    const mockMangsa = PranataMangsaModel(
      id: 1,
      namaMangsa: 'Kasa',
      namaLain: 'Kartika',
      tanggalSiklus: '22 Juni - 1 Agustus',
      candraMangsa: 'Sotya murca saking embanan',
      arketipeModern: 'Sang Pembersih Lahan (Ego-Death & Decluttering)',
      karakterEnergi: 'Energi pembersihan dan persiapan.',
      ramalanKarier: 'Fokus pada perencanaan dan persiapan.',
      ramalanAsmara: 'Melepas adalah bagian dari proses.',
      pesanKesadaran: 'Kadang kita harus merelakan yang lama.',
      saranAktivitas: ['Declutter digital dan fisik', 'Bersihkan meja kerja Anda'],
      tandaAlam: 'Daun berguguran',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SeasonalBanner(mangsa: mockMangsa),
          ),
        ),
      ),
    );

    // Verify presence of title, sub-headline, and description
    expect(find.text('Mangsa Kasa (Kartika)'), findsOneWidget);
    expect(find.text('Sang Pembersih Lahan (Ego-Death & Decluttering)'), findsOneWidget);
    expect(find.text('“Sotya murca saking embanan”'), findsOneWidget);
    expect(find.text('22 Juni - 1 Agustus'), findsOneWidget);
    expect(find.text('Energi pembersihan dan persiapan.'), findsOneWidget);

    // Expand the ExpansionTile
    await tester.tap(find.text('Lihat Ramalan Karir, Asmara & Saran Aktivitas'));
    await tester.pumpAndSettle();

    // Verify presence of detailed horoscopes
    expect(find.text('Fokus pada perencanaan dan persiapan.'), findsOneWidget);
    expect(find.text('Melepas adalah bagian dari proses.'), findsOneWidget);
    expect(find.text('Declutter digital dan fisik'), findsOneWidget);
  });
}
