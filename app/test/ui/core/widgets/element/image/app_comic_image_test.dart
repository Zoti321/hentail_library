import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_image_cache.dart';

void main() {
  setUp(ensureReaderImageCacheConfigured);

  testWidgets('shows error placeholder when image source is missing', (
    WidgetTester tester,
  ) async {
    const Key errorKey = Key('error-placeholder');
    const Key loadingKey = Key('loading-placeholder');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppComicImage(
            loadingPlaceholder: SizedBox(key: loadingKey),
            errorPlaceholder: SizedBox(key: errorKey),
          ),
        ),
      ),
    );

    expect(find.byKey(errorKey), findsOneWidget);
    expect(find.byKey(loadingKey), findsNothing);
  });

  testWidgets('missing reader cache file does not sync-throw on build', (
    WidgetTester tester,
  ) async {
    const Key errorKey = Key('error-placeholder');
    const Key loadingKey = Key('loading-placeholder');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppComicImage(
            filePath: r'C:\hentai_library_tests\missing_reader_page.jpg',
            useReaderImageCache: true,
            loadingPlaceholder: const SizedBox(key: loadingKey),
            errorPlaceholder: const SizedBox(key: errorKey),
          ),
        ),
      ),
    );

    // No existsSync on build: first frame may be loading; must not throw.
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(loadingKey).evaluate().isNotEmpty ||
          find.byKey(errorKey).evaluate().isNotEmpty,
      isTrue,
    );

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
