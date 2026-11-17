import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
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

const LibrarySyncState _idle = (
  running: false,
  cancelled: false,
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
      (String libraryId, String imageSetId) async => _alphaImages,
    ),
    imageSetPageBytesQueryProvider.overrideWithValue(
      (String libraryId, ImageSetImage image) async => Uint8List(0),
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

  testWidgets('list shows root image set first and opens detail grid', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(tester, _overrides(probe));
    await tester.pumpAndSettle();

    expect(find.text('库根目录'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('同步图集'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('imageSet-a')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('i1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('i2')), findsOneWidget);
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
        sync: (running: true, cancelled: false, error: null, progress: null),
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
}
