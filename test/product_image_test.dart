// Tests for product image fallback semantics.
//
// The rule under test: a local Flutter asset path is a *rendering* fallback and
// must never be persisted into a field that is meant to hold a network image
// URL. Persistence keeps a real remote URL or null; display substitutes the
// local default asset.
//
// These tests are pure/offline — no Supabase client is constructed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidz_store/checkout.dart';
import 'package:kidz_store/product_image.dart';

void main() {
  group('resolveProductImageUrl', () {
    test('keeps a valid https URL unchanged', () {
      const String url = 'https://cdn.example.com/products/shoe.jpg';
      expect(resolveProductImageUrl(url), url);
    });

    test('keeps a valid http URL unchanged', () {
      const String url = 'http://cdn.example.com/products/bag.png';
      expect(resolveProductImageUrl(url), url);
    });

    test('trims surrounding whitespace but preserves the URL', () {
      expect(
        resolveProductImageUrl('  https://cdn.example.com/a.jpg  '),
        'https://cdn.example.com/a.jpg',
      );
    });

    test('rejects the local default asset path', () {
      expect(resolveProductImageUrl(kDefaultProductImageAsset), isNull);
    });

    test('rejects any local asset path', () {
      expect(resolveProductImageUrl('assets/img/p1.jpg'), isNull);
    });

    test('rejects null, empty, whitespace and non-string values', () {
      expect(resolveProductImageUrl(null), isNull);
      expect(resolveProductImageUrl(''), isNull);
      expect(resolveProductImageUrl('   '), isNull);
      expect(resolveProductImageUrl(42), isNull);
      expect(resolveProductImageUrl(<String>[]), isNull);
    });

    test('rejects non-http schemes and schemeless values', () {
      expect(resolveProductImageUrl('ftp://example.com/a.jpg'), isNull);
      expect(resolveProductImageUrl('file:///tmp/a.jpg'), isNull);
      expect(resolveProductImageUrl('data:image/png;base64,AAAA'), isNull);
      expect(resolveProductImageUrl('cdn.example.com/a.jpg'), isNull);
    });

    test('rejects an http URL with no host', () {
      expect(resolveProductImageUrl('https://'), isNull);
    });
  });

  group('firstProductImageUrl / remoteImageUrls', () {
    test('picks the first usable remote URL', () {
      expect(
        firstProductImageUrl(<dynamic>[
          'https://cdn.example.com/1.jpg',
          'https://cdn.example.com/2.jpg',
        ]),
        'https://cdn.example.com/1.jpg',
      );
    });

    test('skips unusable entries to find a real URL', () {
      expect(
        firstProductImageUrl(<dynamic>[
          null,
          '',
          kDefaultProductImageAsset,
          'https://cdn.example.com/real.jpg',
        ]),
        'https://cdn.example.com/real.jpg',
      );
    });

    test('returns null for empty, null, or all-unusable lists', () {
      expect(firstProductImageUrl(<dynamic>[]), isNull);
      expect(firstProductImageUrl(null), isNull);
      expect(
        firstProductImageUrl(<dynamic>[kDefaultProductImageAsset, '', null]),
        isNull,
      );
    });

    test('remoteImageUrls drops unusable entries without substituting', () {
      expect(
        remoteImageUrls(<dynamic>[
          kDefaultProductImageAsset,
          'https://cdn.example.com/a.jpg',
          null,
        ]),
        <String>['https://cdn.example.com/a.jpg'],
      );
      expect(remoteImageUrls(<dynamic>[kDefaultProductImageAsset]), isEmpty);
      expect(remoteImageUrls(null), isEmpty);
    });
  });

  group('buildOrderItems — persisted order data', () {
    test('a valid network URL is persisted unchanged', () {
      const String url = 'https://cdn.example.com/products/dress.jpg';

      final List<Map<String, dynamic>> items = buildOrderItems(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'product_id': 'p-1',
            'product_name': 'Kidz Dress',
            'product_price': 39.9,
            'product_image': url,
            'quantity': 2,
            'size': 'M',
            'color': 'Red',
          },
        ],
      );

      expect(items.single['product_image'], url);
      expect(items.single['product_name'], 'Kidz Dress');
      expect(items.single['price'], 39.9);
      expect(items.single['quantity'], 2);
    });

    test('a missing product image is persisted as null, not the asset path',
        () {
      final List<Map<String, dynamic>> items = buildOrderItems(
        <Map<String, dynamic>>[
          <String, dynamic>{'product_id': 'p-2', 'product_name': 'No Image'},
        ],
      );

      expect(items.single['product_image'], isNull);
      expect(
        items.single['product_image'],
        isNot(kDefaultProductImageAsset),
        reason: 'a local asset path must never be persisted',
      );
    });

    test('an asset path arriving from upstream is scrubbed to null', () {
      final List<Map<String, dynamic>> items = buildOrderItems(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'product_id': 'p-3',
            'product_image': kDefaultProductImageAsset,
          },
        ],
      );

      expect(items.single['product_image'], isNull);
    });

    test('no persisted order item ever contains a local asset path', () {
      final List<Map<String, dynamic>> items = buildOrderItems(
        <Map<String, dynamic>>[
          <String, dynamic>{'product_image': 'https://cdn.example.com/a.jpg'},
          <String, dynamic>{'product_image': kDefaultProductImageAsset},
          <String, dynamic>{'product_image': null},
          <String, dynamic>{'product_image': ''},
        ],
      );

      for (final Map<String, dynamic> item in items) {
        final Object? stored = item['product_image'];
        expect(
          stored == null || !stored.toString().startsWith('assets/'),
          isTrue,
          reason: 'stored value $stored must not be a local asset path',
        );
      }
    });

    test('falls back to safe defaults for missing scalar fields', () {
      final List<Map<String, dynamic>> items =
          buildOrderItems(<Map<String, dynamic>>[<String, dynamic>{}]);

      expect(items.single['product_name'], 'Unknown');
      expect(items.single['quantity'], 1);
      expect(items.single['price'], 0.0);
      expect(items.single['size'], 'N/A');
      expect(items.single['color'], 'N/A');
    });
  });

  group('productImage — rendering', () {
    Future<void> pump(WidgetTester tester, Object? value) {
      return tester.pumpWidget(
        MaterialApp(home: Scaffold(body: productImage(value))),
      );
    }

    testWidgets('renders the local asset when the URL is missing', (
      WidgetTester tester,
    ) async {
      await pump(tester, null);

      expect(find.byType(Image), findsOneWidget);
      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect(
        (image.image as AssetImage).assetName,
        kDefaultProductImageAsset,
      );
    });

    testWidgets('renders the local asset when the URL is an asset path', (
      WidgetTester tester,
    ) async {
      await pump(tester, kDefaultProductImageAsset);

      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
    });

    testWidgets('renders the local asset when the URL is empty or invalid', (
      WidgetTester tester,
    ) async {
      await pump(tester, '');
      expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());

      await pump(tester, 'not-a-url');
      expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    });

    testWidgets('uses a network image for a valid remote URL', (
      WidgetTester tester,
    ) async {
      await pump(tester, 'https://cdn.example.com/a.jpg');

      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
      expect(
        (image.image as NetworkImage).url,
        'https://cdn.example.com/a.jpg',
      );
      expect(
        image.errorBuilder,
        isNotNull,
        reason: 'network images need a local fallback when loading fails',
      );
    });
  });
}
