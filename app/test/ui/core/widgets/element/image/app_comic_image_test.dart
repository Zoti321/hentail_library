import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';

void main() {
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
}
