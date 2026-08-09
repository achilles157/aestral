import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/features/legal/presentation/legal_screen.dart';
import 'package:aestral/features/home/presentation/widgets/dashboard_footer.dart';
import 'package:aestral/features/auth/services/auth_service.dart';

void main() {
  group('LegalScreen', () {
    testWidgets('menampilkan judul Kebijakan Privasi + konten dari asset', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalScreen(type: LegalDocumentType.privacyPolicy),
        ),
      );
      // Loading state tampil dulu.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // rootBundle.loadString adalah I/O nyata - jalankan di luar fake async.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      // Konten markdown di-render: cari teks dari dokumen.
      expect(find.textContaining('Efektif sejak'), findsOneWidget);
      expect(
        find.textContaining('Kebijakan Privasi ini menjelaskan'),
        findsWidgets,
      );
    });

    testWidgets('menampilkan judul Syarat Layanan + konten disclaimer', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalScreen(type: LegalDocumentType.termsOfService),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.text('Syarat Layanan'), findsOneWidget);
      // Konten markdown panjang → Markdown me-render lazy (ListView): frasa
      // di bawah fold belum di-build sebagai widget. Verifikasi dua lapis:
      // (1) data yang diteruskan ke renderer mengandung frasa kunci;
      // (2) scroll sampai frasa benar-benar tampil di layar.
      final md = tester.widget<Markdown>(find.byType(Markdown));
      expect(
        md.data,
        contains('Perjanjian ini diatur oleh **hukum Republik Indonesia**'),
        reason: 'kalimat yurisdiksi harus ada di konten Syarat Layanan',
      );
      expect(
        md.data,
        contains('bintang menawarkan perspektif, bukan takdir'),
        reason: 'tagline penutup harus ada di konten Syarat Layanan',
      );

      // Bukti render visual: scroll sampai tagline penutup terlihat.
      await tester.scrollUntilVisible(
        find.textContaining('bintang menawarkan', findRichText: true),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('bintang menawarkan', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('tombol kembali menutup layar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LegalScreen(
                        type: LegalDocumentType.privacyPolicy,
                      ),
                    ),
                  ),
                  child: const Text('Buka'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      // Route push — pump deterministik (tanpa pumpAndSettle/runAsync: spinner
      // loading adalah animasi infinite, dan tujuan test hanya back navigation).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // AppBar LegalScreen tampil segera (tanpa menunggu konten termuat).
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      // Pop transition ~300ms — pump deterministik.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Buka'), findsOneWidget);
    });
  });

  group('DashboardFooter', () {
    testWidgets('menampilkan link Kebijakan Privasi & Syarat Layanan', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DashboardFooter(session: null)),
          ),
        ),
      );
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('Syarat Layanan'), findsOneWidget);
      expect(
        find.text('Keluar'),
        findsNothing,
      ); // guest: tidak ada tombol logout
    });

    testWidgets('menampilkan tombol Keluar untuk pengguna login', (
      tester,
    ) async {
      final session = UserSession(
        uid: 'test-uid',
        displayName: 'Test',
        email: 'test@example.com',
        isMock: false,
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DashboardFooter(session: session)),
          ),
        ),
      );
      expect(find.text('Keluar'), findsOneWidget);
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
    });
  });
}
