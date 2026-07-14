import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/widgets/glass_card.dart';
import 'package:aestral/core/widgets/glass_button.dart';
import 'package:aestral/core/widgets/cosmic_loader.dart';

void main() {
  group('GlassCard', () {
    testWidgets('should render child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassCard(child: Text('Hello Aestral'))),
        ),
      );

      expect(find.text('Hello Aestral'), findsOneWidget);
    });

    testWidgets('should apply padding when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(padding: EdgeInsets.all(16), child: Text('padded')),
          ),
        ),
      );

      expect(find.text('padded'), findsOneWidget);
    });

    testWidgets('should skip BackdropFilter when disableAnimations true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: GlassCard(blur: 20, child: const Text('no blur')),
            ),
          ),
        ),
      );

      // BackdropFilter should NOT be present
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('no blur'), findsOneWidget);
    });

    testWidgets('should use BackdropFilter when animations enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassCard(blur: 10, child: Text('with blur'))),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('with blur'), findsOneWidget);
    });

    testWidgets('should use custom border radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(borderRadius: 32, child: Text('rounded')),
          ),
        ),
      );

      expect(find.text('rounded'), findsOneWidget);
    });
  });

  group('GlassButton', () {
    testWidgets('should render label widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(label: const Text('Tap Me'), onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: const Text('Press'),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Press'));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should not call onPressed when disabled', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: const Text('Disabled'),
              onPressed: () => tapped = true,
              isEnabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await tester.pump();

      expect(tapped, false);
    });

    testWidgets('should render icon widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: const Text('With Icon'),
              icon: const Icon(Icons.star),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('should have reduced opacity when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassButton(
              label: const Text('Dimmed'),
              onPressed: () {},
              isEnabled: false,
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 0.4);
    });
  });

  group('CosmicLoader', () {
    testWidgets('should render auto_awesome icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CosmicLoader())),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('should render label when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CosmicLoader(label: 'Memuat...')),
        ),
      );

      expect(find.text('Memuat...'), findsOneWidget);
    });

    testWidgets('should not render label when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CosmicLoader())),
      );

      // No label text should be present
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('should use custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CosmicLoader(size: 64))),
      );

      // Icon size = size * 0.40 (see CosmicLoader implementation)
      final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
      expect(icon.size, 64 * 0.40);
    });

    testWidgets('should be static when disableAnimations true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: CosmicLoader()),
          ),
        ),
      );

      // Should still render icon
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}
