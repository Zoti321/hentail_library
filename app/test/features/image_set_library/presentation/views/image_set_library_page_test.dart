import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_sync_outcome.dart';
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
  final List<String> syncCalls = <String>[];
  final List<ImageSetReaderEntry> entries = <ImageSetReaderEntry>[];
}

List<Override> _overrides(
  _Probe probe, {
  ImageSetSyncOutcome? outcome,
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
    syncImageSetLibraryCommandProvider.overrideWithValue((
      String libraryId,
    ) async {
      probe.syncCalls.add(libraryId);
      return outcome ??
          const ImageSetSyncSucceeded(addedCount: 2, removedCount: 1);
    }),
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
  testWidgets('list shows root image set first and opens detail grid', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(tester, _overrides(probe));
    await tester.pumpAndSettle();

    expect(find.text('库根目录'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);

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

  testWidgets('sync success shows added and removed counts', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(tester, _overrides(probe));
    await tester.pumpAndSettle();

    await tester.tap(find.text('同步图集'));
    await tester.pumpAndSettle();

    expect(probe.syncCalls, <String>['img-1']);
    expect(find.text('同步完成：新增 2，移除 1'), findsOneWidget);
  });

  testWidgets(
    'sync warning surfaces carrier message without rollback wording',
    (WidgetTester tester) async {
      final _Probe probe = _Probe();
      await _pumpPage(
        tester,
        _overrides(
          probe,
          outcome: const ImageSetSyncWarned(
            message: '已跳过不可读的图集库',
            addedCount: 0,
            removedCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('同步图集'));
      await tester.pumpAndSettle();

      expect(find.text('同步完成，但有内容需要关注：已跳过不可读的图集库'), findsOneWidget);
    },
  );

  testWidgets('sync failure shows the error message', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpPage(
      tester,
      _overrides(probe, outcome: const ImageSetSyncFailed(message: '磁盘错误')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('同步图集'));
    await tester.pumpAndSettle();

    expect(find.text('图集同步失败：磁盘错误'), findsOneWidget);
  });

  testWidgets('busy library sync shows progress and disables the sync button', (
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
    final ExpressiveFilledButton button = tester.widget<ExpressiveFilledButton>(
      find.ancestor(
        of: find.text('同步图集'),
        matching: find.byType(ExpressiveFilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(probe.syncCalls, isEmpty);
  });
}
