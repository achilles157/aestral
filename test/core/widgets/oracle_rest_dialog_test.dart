import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/errors/oracle_rest_exception.dart';
import 'package:aestral/core/widgets/oracle_rest_dialog.dart';

void main() {
  const exception = OracleRestException(
    'Oracle sedang beristirahat — kapasitas kosmis hari ini sudah penuh.',
    retryAfterSeconds: 2 * 3600 + 30 * 60,
  );

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('OracleRestDialog', () {
    testWidgets('menampilkan judul, pesan, dan hitung mundur', (tester) async {
      await tester.pumpWidget(host(const SizedBox()));

      unawaited(
        OracleRestDialog.show(
          tester.element(find.byType(SizedBox)),
          exception,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sesepuh Sedang Beristirahat'), findsOneWidget);
      expect(find.textContaining('kapasitas kosmis'), findsOneWidget);
      expect(find.textContaining('2 jam 30 menit'), findsOneWidget);
      expect(find.text('Baiklah, sampai nanti'), findsOneWidget);
    });

    testWidgets('tombol menutup dialog', (tester) async {
      await tester.pumpWidget(host(const SizedBox()));

      unawaited(
        OracleRestDialog.show(
          tester.element(find.byType(SizedBox)),
          exception,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Baiklah, sampai nanti'));
      await tester.pumpAndSettle();

      expect(find.text('Sesepuh Sedang Beristirahat'), findsNothing);
    });
  });

  group('OracleRestDialog.showIfOracleRest', () {
    testWidgets('menampilkan dialog saat error OracleRestException', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SizedBox()));

      OracleRestDialog.showIfOracleRest(
        tester.element(find.byType(SizedBox)),
        exception,
      );
      await tester.pumpAndSettle();

      expect(find.text('Sesepuh Sedang Beristirahat'), findsOneWidget);
    });

    testWidgets('tidak menampilkan dialog untuk error lain', (tester) async {
      await tester.pumpWidget(host(const SizedBox()));

      OracleRestDialog.showIfOracleRest(
        tester.element(find.byType(SizedBox)),
        Exception('Error biasa'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sesepuh Sedang Beristirahat'), findsNothing);
    });
  });
}
