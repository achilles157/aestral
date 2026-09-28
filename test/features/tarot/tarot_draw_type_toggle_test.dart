import 'package:aestral/features/tarot/presentation/widgets/tarot_draw_type_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget test untuk [TarotDrawTypeToggle] — toggle pill antara
/// Tarot Mangsa / Tarot Lahir / Tarot Tematik.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('TarotDrawTypeToggle — render label', () {
    testWidgets('menampilkan 3 pill dalam Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'mangsa',
            currentLang: 'id',
            onTypeChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Tarot Mangsa'), findsOneWidget);
      expect(find.text('Tarot Lahir'), findsOneWidget);
      expect(find.text('Tarot Tematik'), findsOneWidget);
    });

    testWidgets('menampilkan 3 pill dalam Bahasa Inggris', (tester) async {
      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'mangsa',
            currentLang: 'en',
            onTypeChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Mangsa Tarot'), findsOneWidget);
      expect(find.text('Birth Tarot'), findsOneWidget);
      expect(find.text('Thematic Tarot'), findsOneWidget);
    });
  });

  group('TarotDrawTypeToggle — interaksi', () {
    testWidgets('tap pill Mangsa memanggil onTypeChanged("mangsa")', (
      tester,
    ) async {
      String? dipilih;

      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'birth',
            currentLang: 'id',
            onTypeChanged: (t) => dipilih = t,
          ),
        ),
      );

      await tester.tap(find.text('Tarot Mangsa'));
      await tester.pump();

      expect(dipilih, 'mangsa');
    });

    testWidgets('tap pill Lahir memanggil onTypeChanged("birth")', (
      tester,
    ) async {
      String? dipilih;

      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'mangsa',
            currentLang: 'id',
            onTypeChanged: (t) => dipilih = t,
          ),
        ),
      );

      await tester.tap(find.text('Tarot Lahir'));
      await tester.pump();

      expect(dipilih, 'birth');
    });

    testWidgets('tap pill Tematik memanggil onTypeChanged("thematic")', (
      tester,
    ) async {
      String? dipilih;

      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'mangsa',
            currentLang: 'id',
            onTypeChanged: (t) => dipilih = t,
          ),
        ),
      );

      await tester.tap(find.text('Tarot Tematik'));
      await tester.pump();

      expect(dipilih, 'thematic');
    });

    testWidgets('tap pill yang sedang aktif tetap memanggil callback', (
      tester,
    ) async {
      var jumlahPanggilan = 0;

      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'mangsa',
            currentLang: 'id',
            onTypeChanged: (_) => jumlahPanggilan++,
          ),
        ),
      );

      await tester.tap(find.text('Tarot Mangsa'));
      await tester.pump();

      expect(jumlahPanggilan, 1);
    });
  });

  group('TarotDrawTypeToggle — status terkunci', () {
    testWidgets(
      'saat isLocked=true, pill Mangsa & Tematik menampilkan ikon kunci',
      (tester) async {
        await tester.pumpWidget(
          host(
            TarotDrawTypeToggle(
              selectedDrawType: 'birth',
              currentLang: 'id',
              onTypeChanged: (_) {},
              isLocked: true,
            ),
          ),
        );

        // Dua pill terkunci (mangsa + tematik); pill birth tidak pernah terkunci.
        expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
      },
    );

    testWidgets('saat isLocked=false, tidak ada ikon kunci', (tester) async {
      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'mangsa',
            currentLang: 'id',
            onTypeChanged: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('pill terkunci masih bisa di-tap (gate ada di pemanggil)', (
      tester,
    ) async {
      String? dipilih;

      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'birth',
            currentLang: 'id',
            onTypeChanged: (t) => dipilih = t,
            isLocked: true,
          ),
        ),
      );

      await tester.tap(find.text('Tarot Mangsa'));
      await tester.pump();

      expect(dipilih, 'mangsa');
    });
  });

  group('TarotDrawTypeToggle — penyorotan pilihan', () {
    /// Cari warna latar Container milik pill berlabel [label].
    Color? warnaPill(WidgetTester tester, String label) {
      final pillText = find.text(label);
      final container = find
          .ancestor(of: pillText, matching: find.byType(Container))
          .first;
      final decoration =
          tester.widget<Container>(container).decoration as BoxDecoration?;
      return decoration?.color;
    }

    testWidgets('pill aktif punya warna latar, yang tidak aktif transparan', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'birth',
            currentLang: 'id',
            onTypeChanged: (_) {},
          ),
        ),
      );

      final aktif = warnaPill(tester, 'Tarot Lahir');
      final nonaktif = warnaPill(tester, 'Tarot Mangsa');

      expect(aktif, isNot(Colors.transparent));
      expect(nonaktif, Colors.transparent);
    });

    testWidgets('berpindah pilihan memindahkan sorotan', (tester) async {
      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'mangsa',
            currentLang: 'id',
            onTypeChanged: (_) {},
          ),
        ),
      );

      expect(warnaPill(tester, 'Tarot Mangsa'), isNot(Colors.transparent));
      expect(warnaPill(tester, 'Tarot Lahir'), Colors.transparent);

      // Bangun ulang dengan pilihan berbeda.
      await tester.pumpWidget(
        host(
          TarotDrawTypeToggle(
            selectedDrawType: 'thematic',
            currentLang: 'id',
            onTypeChanged: (_) {},
          ),
        ),
      );

      expect(warnaPill(tester, 'Tarot Mangsa'), Colors.transparent);
      expect(warnaPill(tester, 'Tarot Tematik'), isNot(Colors.transparent));
    });
  });
}
