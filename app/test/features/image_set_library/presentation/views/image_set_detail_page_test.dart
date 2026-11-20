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
}

List<Override> _overrides(
  _Probe probe, {
  ImageSetFacets facets = ImageSetFacets.empty,
  ImageSet imageSet = _alpha,
}) => <Override>[
  libraryRevisionStateProvider.overrideWithValue(const LibraryRevisionState()),
  imageSetImagesQueryProvider.overrideWithValue(
    (String libraryId, String imageSetId) async =>
        imageSetId == _alpha.imageSetId
        ? _alphaImages
        : const <ImageSetImage>[],
  ),
  imageSetPageBytesQueryProvider.overrideWithValue(
    (String libraryId, ImageSetImage image) async => _png1x1,
  ),
  imageSetFacetsQueryProvider.overrideWithValue((String imageSetId) async {
    probe.lastFacetsImageSetId = imageSetId;
    return facets;
  }),
  imageSetReaderEntryCommandProvider.overrideWithValue(probe.entries.add),
];

Future<void> _pumpDetail(
  WidgetTester tester, {
  required List<Override> overrides,
  ImageSet imageSet = _alpha,
}) => pumpLocalizedApp(
  tester,
  overrides: overrides,
  home: ImageSetDetailPage(libraryId: imageSet.libraryId, imageSet: imageSet),
);

void main() {
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
}
