// Widget and asset tests for the Kidz store app.
//
// The default Flutter counter template test was replaced: this project is a
// Supabase-backed e-commerce app and never had a counter. `MyApp`'s home is
// `SplashScreen`, whose `initState` reads `Supabase.instance.client` and starts
// a 3 second navigation timer, so mounting it in a test would require a live
// backend and would not be deterministic. The tests below therefore exercise
// the real widgets while staying offline and timer-free.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidz_store/main.dart';
import 'package:kidz_store/privacy.dart';

void main() {
  testWidgets('MyApp builds a MaterialApp with the splash screen as home', (
    WidgetTester tester,
  ) async {
    // Build the real application widget and inspect what it returns, without
    // mounting SplashScreen (which would need Supabase and a pending timer).
    late Widget built;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          built = const MyApp().build(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(built, isA<MaterialApp>());
    final MaterialApp app = built as MaterialApp;
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.home, isA<SplashScreen>());
  });

  testWidgets('A real app screen renders without a backend', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  group('restored assets are bundled and loadable', () {
    // Every asset the application code references from the local bundle.
    const List<String> bundledAssets = <String>[
      'assets/img/splashscreen.png',
      'assets/img/babyboy.jpg',
      'assets/img/babygirl.jpg',
      'assets/img/debitcard.jpg',
      'assets/img/default.jpg',
      'assets/img/icon.jpg',
      'assets/img/p1.jpg',
      'assets/img/p2.jpg',
      'assets/img/p3.jpg',
      'assets/img/p4.jpg',
      'assets/img/p5.jpg',
      'assets/img/p6.jpg',
      'assets/img/p7.jpg',
      'assets/anime/woman-shopping-online.json',
      'assets/anime/tracking-order-online.json',
    ];

    for (final String asset in bundledAssets) {
      test('$asset loads from the asset bundle', () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final ByteData data = await rootBundle.load(asset);
        expect(
          data.lengthInBytes,
          greaterThan(0),
          reason: '$asset resolved but is empty',
        );
      });
    }
  });
}
