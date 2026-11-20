import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_page.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_image_tile.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

const ImageSet _root = ImageSet(
  imageSetId: 'root',
  libraryId: 'img-1',
  relativePath: '',
  name: 'legacy-root',
  isRoot: true,
);

const ImageSet _alpha = ImageSet(
  imageSetId: 'a',
  libraryId: 'img-1',
  relativePath: 'alpha',
  name: 'alpha',
  isRoot: false,
);

const ImageSetImage _image1 = ImageSetImage(
  imageSetImageId: 'i1',
  imageSetId: 'a',
  libraryId: 'img-1',
  carrierRelativePath: 'alpha/1.jpg',
  memberPath: '',
  carrierKind: 'loose',
  name: '1.jpg',
);

const ImageSetImage _image2 = ImageSetImage(
  imageSetImageId: 'i2',
  imageSetId: 'a',
  libraryId: 'img-1',
  carrierRelativePath: 'alpha/2.jpg',
  memberPath: '',
  carrierKind: 'loose',
  name: '2.jpg',
);

const ImageSetImage _image2Excluded = ImageSetImage(
  imageSetImageId: 'i2',
  imageSetId: 'a',
  libraryId: 'img-1',
  carrierRelativePath: 'alpha/2.jpg',
  memberPath: '',
  carrierKind: 'loose',
  name: '2.jpg',
  excluded: true,
);

List<ImageSetImage> _alphaImages = <ImageSetImage>[_image1];

List<ImageSetImage> _workspaceWithExcluded = <ImageSetImage>[
  _image1,
  _image2Excluded,
];

final Uint8List _png1x1 = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _Probe {
  final List<ImageSetReaderEntry> entries = <ImageSetReaderEntry>[];
  String? lastFacetsImageSetId;
  final List<({List<String> ids, bool excluded})> excludeCalls =
      <({List<String> ids, bool excluded})>[];
  final List<List<String>> deleteOnDiskCalls = <List<String>>[];
  List<ImageSetSubmission> submissions = const <ImageSetSubmission>[];
  final List<String> createSubmissionNames = <String>[];
  final List<({String submissionId, List<String> ids})> addMemberCalls =
      <({String submissionId, List<String> ids})>[];
  ImageSetLibraryGates gates = const ImageSetLibraryGates(
    resourceMutation: false,
    managedLayout: false,
  );
}

List<Override> _overrides(
  _Probe probe, {
  ImageSetFacets facets = ImageSetFacets.empty,
  ImageSet imageSet = _alpha,
  List<ImageSetImage>? browseImages,
  List<ImageSetImage>? workspaceImages,
  ImageSetLibraryGates? gates,
}) {
  final List<ImageSetImage> browse =
      browseImages ??
      (imageSet.imageSetId == _alpha.imageSetId
          ? _alphaImages
          : const <ImageSetImage>[]);
  final List<ImageSetImage> workspace =
      workspaceImages ??
      (imageSet.imageSetId == _alpha.imageSetId
          ? _workspaceWithExcluded
          : const <ImageSetImage>[]);
  return <Override>[
    libraryRevisionStateProvider.overrideWithValue(const LibraryRevisionState()),
    imageSetImagesQueryProvider.overrideWithValue(
      (String libraryId, String imageSetId) async =>
          imageSetId == _alpha.imageSetId ? browse : const <ImageSetImage>[],
    ),
    imageSetWorkspaceImagesQueryProvider.overrideWithValue(
      (String libraryId, String imageSetId) async =>
          imageSetId == _alpha.imageSetId ? workspace : const <ImageSetImage>[],
    ),
    imageSetPageBytesQueryProvider.overrideWithValue(
      (String libraryId, ImageSetImage image) async => _png1x1,
    ),
    imageSetFacetsQueryProvider.overrideWithValue((String imageSetId) async {
      probe.lastFacetsImageSetId = imageSetId;
      return facets;
    }),
    imageSetReaderEntryCommandProvider.overrideWithValue(probe.entries.add),
    imageSetSetImagesExcludedCommandProvider.overrideWithValue(
      (String libraryId, String imageSetId, List<String> imageIds, {
        required bool excluded,
      }) async {
        probe.excludeCalls.add((ids: List<String>.from(imageIds), excluded: excluded));
      },
    ),
    imageSetReorderImagesCommandProvider.overrideWithValue(
      (_, __, ___) async {},
    ),
    imageSetLibraryGatesQueryProvider.overrideWithValue(
      (_) async => gates ?? probe.gates,
    ),
    imageSetDeleteImagesOnDiskCommandProvider.overrideWithValue(
      (String libraryId, String imageSetId, List<String> imageIds) async {
        probe.deleteOnDiskCalls.add(List<String>.from(imageIds));
      },
    ),
    imageSetCopyImagesInCommandProvider.overrideWithValue(
      (_, __, ___) async => const <ImageSetImage>[],
    ),
    imageSetTakeOverManagedLayoutCommandProvider.overrideWithValue(
      (_, __) async {},
    ),
    imageSetSubmissionsQueryProvider.overrideWithValue(
      (String libraryId, String imageSetId) async => probe.submissions,
    ),
    imageSetCreateSubmissionCommandProvider.overrideWithValue(
      (String libraryId, String imageSetId, String name) async {
        probe.createSubmissionNames.add(name);
        final ImageSetSubmission created = ImageSetSubmission(
          submissionId: 'new-${probe.createSubmissionNames.length}',
          libraryId: libraryId,
          imageSetId: imageSetId,
          name: name,
          memberImageIds: const <String>[],
        );
        probe.submissions = <ImageSetSubmission>[...probe.submissions, created];
        return created;
      },
    ),
    imageSetRenameSubmissionCommandProvider.overrideWithValue(
      (_, __, ___) async {},
    ),
    imageSetDeleteSubmissionCommandProvider.overrideWithValue((_, __) async {}),
    imageSetAddSubmissionMembersCommandProvider.overrideWithValue(
      (String libraryId, String submissionId, List<String> imageIds) async {
        probe.addMemberCalls.add((
          submissionId: submissionId,
          ids: List<String>.from(imageIds),
        ));
      },
    ),
    imageSetRemoveSubmissionMembersCommandProvider.overrideWithValue(
      (_, __, ___) async {},
    ),
    imageSetReorderSubmissionMembersCommandProvider.overrideWithValue(
      (_, __, ___) async {},
    ),
  ];
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required List<Override> overrides,
  ImageSet imageSet = _alpha,
  ImageSetCarrierShape carrierShape = ImageSetCarrierShape.directory,
}) => pumpLocalizedApp(
  tester,
  overrides: overrides,
  home: ImageSetDetailPage(
    libraryId: imageSet.libraryId,
    imageSet: imageSet,
    carrierShape: carrierShape,
  ),
);

Future<void> _enterSelectionViaLongPress(WidgetTester tester) async {
  await tester.longPress(find.byKey(const ValueKey<String>('i1')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _alphaImages = <ImageSetImage>[_image1];
  });

  testWidgets('renders bound facet names from injected query', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(
      tester,
      overrides: _overrides(
        probe,
        facets: const ImageSetFacets(
          authors: <String>['Alice'],
          tags: <String>['tag-a'],
          parodies: <String>['Series X'],
          characters: <String>['Char'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(probe.lastFacetsImageSetId, 'a');
    expect(find.text('作者'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('标签'), findsOneWidget);
    expect(find.text('tag-a'), findsOneWidget);
    expect(find.text('原作'), findsOneWidget);
    expect(find.text('Series X'), findsOneWidget);
    expect(find.text('角色'), findsOneWidget);
    expect(find.text('Char'), findsOneWidget);
    expect(find.text('暂无'), findsNothing);
  });

  testWidgets('omits unbound facet rows without empty placeholders', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    expect(find.text('作者'), findsNothing);
    expect(find.text('标签'), findsNothing);
    expect(find.text('原作'), findsNothing);
    expect(find.text('角色'), findsNothing);
    expect(find.text('暂无'), findsNothing);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('1 张'), findsOneWidget);
  });

  testWidgets('title uses name only even when isRoot', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(
      tester,
      imageSet: _root,
      overrides: _overrides(probe, imageSet: _root),
    );
    await tester.pumpAndSettle();

    expect(find.text('legacy-root'), findsOneWidget);
    expect(find.text('未分类'), findsNothing);
  });

  testWidgets('thumbnail tap invokes Reader entry with catalog index', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('i1')));
    await tester.pump();

    expect(probe.entries.single.imageSetId, 'a');
    expect(probe.entries.single.imageSetImageId, 'i1');
    expect(probe.entries.single.index, 0);
  });

  testWidgets('no manage workspace entry on detail', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('管理工作区'), findsNothing);
    expect(find.text('管理工作区'), findsNothing);
  });

  testWidgets('long-press enters selection with excluded workspace members', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterSelectionViaLongPress(tester);

    expect(find.text('已选 1 张'), findsOneWidget);
    expect(find.text('已排除'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('i2')), findsOneWidget);
  });

  testWidgets('exclude command invoked from selection toolbar', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterSelectionViaLongPress(tester);

    await tester.tap(find.text('清除'));
    await tester.pump();
    await tester.tap(find.text('全选'));
    await tester.pump();
    await tester.tap(find.text('排除'));
    await tester.pump();

    expect(probe.excludeCalls, hasLength(1));
    expect(probe.excludeCalls.single.ids, containsAll(<String>['i1', 'i2']));
    expect(probe.excludeCalls.single.excluded, isTrue);
  });

  testWidgets('empty selection disables bulk exclude', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterSelectionViaLongPress(tester);

    await tester.tap(find.text('清除'));
    await tester.pump();

    expect(find.text('已选 0 张'), findsOneWidget);
    final TextButton exclude = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '排除'),
    );
    expect(exclude.onPressed, isNull);
  });

  testWidgets('取消排除 only when selection contains excluded members', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterSelectionViaLongPress(tester);

    expect(find.text('取消排除'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('i2')));
    await tester.pump();

    expect(find.text('取消排除'), findsOneWidget);
  });

  testWidgets('detail browse has no bottom submissions section', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    expect(find.text('投稿'), findsNothing);
    expect(find.textContaining('尚无投稿'), findsNothing);
    expect(find.text('新建'), findsNothing);
  });

  testWidgets('root archive shows unsupported copy when mutation enabled', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe()
      ..gates = const ImageSetLibraryGates(
        resourceMutation: true,
        managedLayout: false,
      );
    await _pumpDetail(
      tester,
      overrides: _overrides(probe),
      carrierShape: ImageSetCarrierShape.rootArchive,
    );
    await tester.pumpAndSettle();

    expect(find.text('根目录压缩包图集不支持资源变更。'), findsOneWidget);
    expect(find.byKey(const Key('imageSetDetailAdd')), findsNothing);
    expect(find.text('复制图片入库'), findsNothing);
  });

  testWidgets('button pager pages grid and Reader uses workspace index', (
    WidgetTester tester,
  ) async {
    configureTestView(tester, const Size(1280, 900));
    final _Probe probe = _Probe();
    final List<ImageSetImage> many = List<ImageSetImage>.generate(
      kImageSetDetailImagePageSize + 1,
      (int i) => ImageSetImage(
        imageSetImageId: 'i$i',
        imageSetId: 'a',
        libraryId: 'img-1',
        carrierRelativePath: 'alpha/$i.jpg',
        memberPath: '',
        carrierKind: 'loose',
        name: '$i.jpg',
      ),
    );
    _alphaImages = many;
    await _pumpDetail(
      tester,
      overrides: _overrides(
        probe,
        browseImages: many,
        workspaceImages: many,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25 张'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('i0')), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('i$kImageSetDetailImagePageSize')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('imageSetDetailPager'), skipOffstage: false),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('imageSetDetailPager')), findsOneWidget);
    await tester.tap(find.widgetWithText(PaginationPageButton, '2'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('i0')), findsNothing);
    expect(
      find.byKey(ValueKey<String>('i$kImageSetDetailImagePageSize')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(ValueKey<String>('i$kImageSetDetailImagePageSize')),
    );
    await tester.pumpAndSettle();
    expect(probe.entries, hasLength(1));
    expect(probe.entries.single.index, kImageSetDetailImagePageSize);
    expect(
      probe.entries.single.imageSetImageId,
      'i$kImageSetDetailImagePageSize',
    );
  });

  testWidgets('detail cover is enlarged and tonal add shows when mutation on', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe()
      ..gates = const ImageSetLibraryGates(
        resourceMutation: true,
        managedLayout: false,
      );
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    final Size coverSize = tester.getSize(
      find.byKey(const Key('imageSetDetailCover')),
    );
    expect(coverSize.width, greaterThanOrEqualTo(160));
    expect(find.byKey(const Key('imageSetDetailAdd')), findsOneWidget);
    expect(find.text('复制图片入库'), findsOneWidget);
  });

  testWidgets('tonal add hidden when resource mutation off', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('imageSetDetailAdd')), findsNothing);
  });

  testWidgets('delete on disk from selection when mutation gated', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe()
      ..gates = const ImageSetLibraryGates(
        resourceMutation: true,
        managedLayout: false,
      );
    await _pumpDetail(
      tester,
      overrides: _overrides(
        probe,
        workspaceImages: <ImageSetImage>[_image1, _image2],
      ),
    );
    await tester.pumpAndSettle();
    await _enterSelectionViaLongPress(tester);

    await tester.tap(find.text('清除'));
    await tester.pump();
    await tester.tap(find.text('全选'));
    await tester.pump();
    await tester.tap(find.text('从磁盘删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(M3EButton, '删除'));
    await tester.pumpAndSettle();

    expect(probe.deleteOnDiskCalls, hasLength(1));
    expect(
      probe.deleteOnDiskCalls.single,
      containsAll(<String>['i1', 'i2']),
    );
  });

  testWidgets('disk delete hidden when resource mutation off', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterSelectionViaLongPress(tester);

    expect(find.text('从磁盘删除'), findsNothing);
  });

  testWidgets('exiting selection restores browse list without excluded', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterSelectionViaLongPress(tester);
    expect(find.byKey(const ValueKey<String>('i2')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('1 张'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('i2')), findsNothing);
    expect(find.text('已排除'), findsNothing);
  });

  testWidgets('submission affinity strips only on member tiles', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    _alphaImages = <ImageSetImage>[_image1, _image2];
    probe.submissions = const <ImageSetSubmission>[
      ImageSetSubmission(
        submissionId: 's1',
        libraryId: 'img-1',
        imageSetId: 'a',
        name: 'Pack A',
        memberImageIds: <String>['i1'],
      ),
      ImageSetSubmission(
        submissionId: 's2',
        libraryId: 'img-1',
        imageSetId: 'a',
        name: 'Pack B',
        memberImageIds: <String>['i1'],
      ),
    ];
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('imageSetAffinityStrips-i1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('imageSetAffinityStrip-i1-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('imageSetAffinityStrip-i1-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('imageSetAffinityStrips-i2')),
      findsNothing,
    );
  });
}