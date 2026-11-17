import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_card.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_library_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

const ImageSet _root = ImageSet(
  imageSetId: 'root',
  libraryId: 'img-1',
  relativePath: '',
  name: '',
  isRoot: true,
);
const ImageSet _alpha = ImageSet(
  imageSetId: 'a',
  libraryId: 'img-1',
  relativePath: 'alpha',
  name: 'alpha',
  isRoot: false,
);

const List<ImageSetImage> _alphaImages = <ImageSetImage>[
  ImageSetImage(
    imageSetImageId: 'i1',
    imageSetId: 'a',
    libraryId: 'img-1',
    carrierRelativePath: 'alpha/1.jpg',
    memberPath: '',
    carrierKind: 'loose',
    name: '1.jpg',
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
];

/// 1×1 opaque PNG for cover decode in widget tests.
final Uint8List _png1x1 = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const LibrarySyncState _idle = (
  running: false,
  cancelled: false,
  targetLibraryId: null,
  error: null,
  progress: null,
);

class _Probe {
  final List<ImageSetReaderEntry> entries = <ImageSetReaderEntry>[];
}

List<Override> _overrides(
  _Probe probe, {
  LibrarySyncState sync = _idle,
}) {
  return <Override>[
    libraryRevisionStateProvider.overrideWithValue(
      const LibraryRevisionState(),
    ),
    librarySyncStateProvider.overrideWithValue(sync),
    imageSetListQueryProvider.overrideWithValue(
      (String libraryId) async => <ImageSet>[_root, _alpha],
    ),
    imageSetImagesQueryProvider.overrideWithValue(
      (String libraryId, String imageSetId) async =>
          imageSetId == _alpha.imageSetId
          ? _alphaImages
          : const <ImageSetImage>[],
    ),
    imageSetPageBytesQueryProvider.overrideWithValue(
      (String libraryId, ImageSetImage image) async => _png1x1,
    ),
    imageSetReaderEntryCommandProvider.overrideWithValue(probe.entries.add),
  ];
}

Future<void> _pumpPage(WidgetTester tester, List<Override> overrides) =>
    pumpLocalizedApp(
      tester,
      overrides: overrides,
      home: const ImageSetLibraryPage(
        libraryId: 'img-1',
        displayName: 'Gallery',
      ),
    );

void main() {
  testWidgets(
    'defaults to card grid with root unclassified label and covers',
    (WidgetTester tester) async {
      final _Probe probe = _Probe();
      await _pumpPage(tester, _overrides(probe));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogViewModeButtonGroup), findsOneWidget);
      expect(find.byType(ImageSetCard), findsNWidgets(2));
      expect(find.byType(ImageSetCover), findsWidgets);
      expect(find.text('未分类'), findsOneWidget);
      expect(find.text('alpha'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    },
  );

  testWidgets('toggles to list with leading cover thumbs', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(tester, _overrides(probe));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('列表视图'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.byType(ImageSetCard), findsNothing);
    expect(find.byType(ImageSetCover), findsNWidgets(2));
    expect(find.text('未分类'), findsOneWidget);
  });

  testWidgets(
    'list Scrollbar shares an explicit controller on desktop surface',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final _Probe probe = _Probe();
      await _pumpPage(tester, _overrides(probe));
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('card tap opens detail with stub header and caption-free tiles', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(tester, _overrides(probe));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('imageSet-a')));
    await tester.pumpAndSettle();

    expect(find.text('alpha'), findsWidgets);
    expect(find.text('2 张'), findsOneWidget);
    expect(find.text('作者'), findsOneWidget);
    expect(find.text('标签'), findsOneWidget);
    expect(find.text('原作'), findsOneWidget);
    expect(find.text('角色'), findsOneWidget);
    expect(find.text('暂无'), findsNWidgets(4));
    expect(find.byKey(const ValueKey<String>('i1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('i2')), findsOneWidget);
    expect(find.text('1.jpg'), findsNothing);
    expect(find.text('2.png'), findsNothing);
  });

  testWidgets(
    'selecting a thumbnail invokes the Reader entry with catalog index',
    (WidgetTester tester) async {
      final _Probe probe = _Probe();
      await _pumpPage(tester, _overrides(probe));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('imageSet-a')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('i2')));
      await tester.pump();

      expect(probe.entries.single.imageSetId, 'a');
      expect(probe.entries.single.imageSetImageId, 'i2');
      expect(probe.entries.single.index, 1);
    },
  );

  testWidgets('busy library sync shows progress without a page sync action', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(
      tester,
      _overrides(
        probe,
        sync: (
          running: true,
          cancelled: false,
          targetLibraryId: 'img-1',
          error: null,
          progress: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('imageSetSyncProgress')),
      findsOneWidget,
    );
    expect(find.text('正在同步图集…'), findsOneWidget);
    expect(find.text('同步图集'), findsNothing);
  });

  testWidgets('sync for another library does not show progress on this page', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(
      tester,
      _overrides(
        probe,
        sync: (
          running: true,
          cancelled: false,
          targetLibraryId: 'other-lib',
          error: null,
          progress: null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('imageSetSyncProgress')),
      findsNothing,
    );
    expect(find.text('正在同步图集…'), findsNothing);
  });
}
