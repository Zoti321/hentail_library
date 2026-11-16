import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_page.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_reader_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/ui/navigation/app_root_navigator_key.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

const ImageSet _alpha = ImageSet(
  imageSetId: 'a',
  libraryId: 'img-1',
  relativePath: 'alpha',
  name: 'alpha',
  isRoot: false,
);

const List<ImageSetImage> _pages = <ImageSetImage>[
  ImageSetImage(
    imageSetImageId: 'i1',
    imageSetId: 'a',
    libraryId: 'img-1',
    carrierRelativePath: 'alpha/1.png',
    memberPath: '',
    carrierKind: 'loose',
    name: '1.png',
  ),
  ImageSetImage(
    imageSetImageId: 'i2',
    imageSetId: 'a',
    libraryId: 'img-1',
    carrierRelativePath: 'alpha/pack.zip',
    memberPath: '2.png',
    carrierKind: 'zip',
    name: '2.png',
  ),
  ImageSetImage(
    imageSetImageId: 'i3',
    imageSetId: 'a',
    libraryId: 'img-1',
    carrierRelativePath: 'alpha/3.png',
    memberPath: '',
    carrierKind: 'loose',
    name: '3.png',
  ),
];

/// 1x1 透明 PNG，用于让 Image.memory 真实解码。
const List<int> _png = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, //
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00, //
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
];

class _Probe {
  final List<ImageSetReaderEntry> sessionEntries = <ImageSetReaderEntry>[];
}

List<Override> _overrides(_Probe probe) {
  return <Override>[
    libraryRevisionStateProvider.overrideWithValue(
      const LibraryRevisionState(),
    ),
    imageSetImagesQueryProvider.overrideWithValue(
      (String libraryId, String imageSetId) async => _pages,
    ),
    imageSetReaderSessionQueryProvider.overrideWithValue((
      ImageSetReaderEntry entry,
    ) async {
      probe.sessionEntries.add(entry);
      return ImageSetReaderSession(
        libraryId: entry.libraryId,
        imageSetId: entry.imageSetId,
        pages: _pages,
        startIndex: entry.index,
      );
    }),
    imageSetPageBytesQueryProvider.overrideWithValue(
      (String libraryId, ImageSetImage image) async => Uint8List.fromList(_png),
    ),
    imageSetReaderEntryCommandProvider.overrideWithValue(
      (ImageSetReaderEntry entry) =>
          pushImageSetReaderPage(appRootNavigatorKey.currentState, entry),
    ),
  ];
}

Future<void> _pumpReader(
  WidgetTester tester,
  _Probe probe,
  ImageSetReaderEntry entry,
) => pumpLocalizedApp(
  tester,
  overrides: _overrides(probe),
  home: ImageSetReaderPage(entry: entry),
);

String _indicator(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey<String>('imageSetReaderIndicator')))
    .data!;

void main() {
  testWidgets('starts at the selected catalog index and pages in order', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpReader(
      tester,
      probe,
      const ImageSetReaderEntry(
        libraryId: 'img-1',
        imageSetId: 'a',
        imageSetImageId: 'i2',
        index: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(probe.sessionEntries.single.index, 1);
    expect(_indicator(tester), '2 / 3');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_indicator(tester), '3 / 3');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_indicator(tester), '3 / 3');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_indicator(tester), '2 / 3');
  });

  testWidgets(
    'selecting a thumbnail launches the reader and back returns to detail',
    (WidgetTester tester) async {
      final _Probe probe = _Probe();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(probe),
          child: MaterialApp(
            navigatorKey: appRootNavigatorKey,
            locale: localizedTestAppConfig().locale,
            localizationsDelegates: localizedTestAppConfig().delegates,
            supportedLocales: localizedTestAppConfig().locales,
            theme: buildAppTheme(Brightness.light),
            home: const ImageSetDetailPage(
              libraryId: 'img-1',
              imageSet: _alpha,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('i2')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('i2')));
      await tester.pumpAndSettle();

      expect(probe.sessionEntries.single.imageSetImageId, 'i2');
      expect(probe.sessionEntries.single.index, 1);
      expect(_indicator(tester), '2 / 3');

      await tester.tap(
        find.byKey(const ValueKey<String>('imageSetReaderBack')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('imageSetReaderIndicator')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('i2')), findsOneWidget);
    },
  );
}
