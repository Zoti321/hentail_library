import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_page.dart';
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
  final List<List<String>> reorderCalls = <List<String>>[];
}

List<Override> _overrides(
  _Probe probe, {
  ImageSetFacets facets = ImageSetFacets.empty,
  ImageSet imageSet = _alpha,
  List<ImageSetImage>? browseImages,
  List<ImageSetImage>? workspaceImages,
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
      (String libraryId, String imageSetId, List<String> orderedIds) async {
        probe.reorderCalls.add(List<String>.from(orderedIds));
      },
    ),
  ];
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required List<Override> overrides,
  ImageSet imageSet = _alpha,
}) => pumpLocalizedApp(
  tester,
  overrides: overrides,
  home: ImageSetDetailPage(libraryId: imageSet.libraryId, imageSet: imageSet),
);

Future<void> _enterManage(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('管理工作区'));
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

  testWidgets('manage mode lists excluded workspace members', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    _alphaImages = <ImageSetImage>[_image1, _image2];
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterManage(tester);

    expect(find.text('2.jpg'), findsOneWidget);
    expect(find.text('已排除'), findsOneWidget);
  });

  testWidgets('exclude command invoked from manage mode', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterManage(tester);

    await tester.tap(find.text('全选'));
    await tester.pump();
    await tester.tap(find.text('排除'));
    await tester.pump();

    expect(probe.excludeCalls, hasLength(1));
    expect(probe.excludeCalls.single.ids, containsAll(<String>['i1', 'i2']));
    expect(probe.excludeCalls.single.excluded, isTrue);
  });

  testWidgets('reorder command invoked with full permutation', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    _alphaImages = <ImageSetImage>[_image1, _image2];
    await _pumpDetail(
      tester,
      overrides: _overrides(
        probe,
        workspaceImages: <ImageSetImage>[_image1, _image2],
      ),
    );
    await tester.pumpAndSettle();
    await _enterManage(tester);

    final Finder firstRow = find.byKey(const ValueKey<String>('i1'));
    await tester.longPress(firstRow);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(firstRow, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(probe.reorderCalls, hasLength(1));
    expect(
      probe.reorderCalls.single,
      <String>['i2', 'i1'],
    );
  });

  testWidgets('exiting manage restores browse list without excluded', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpDetail(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();
    await _enterManage(tester);
    expect(find.text('2.jpg'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('1 张'), findsOneWidget);
    expect(find.text('2.jpg'), findsNothing);
    expect(find.text('已排除'), findsNothing);
  });
}