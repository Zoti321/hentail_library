import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets_patch.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_named_facet_kind.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_facet_dictionary_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/patterns/metadata_edit/image_set_metadata_edit_present.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_metadata_edit_sheet.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

const ImageSet _imageSet = ImageSet(
  imageSetId: 'a',
  libraryId: 'img-1',
  relativePath: 'alpha',
  name: 'alpha',
  isRoot: false,
);

class _Probe {
  final List<({String imageSetId, String name})> nameCalls =
      <({String imageSetId, String name})>[];
  final List<({String imageSetId, bool locked})> lockCalls =
      <({String imageSetId, bool locked})>[];
  final List<({String imageSetId, ImageSetFacetsPatch patch})> facetCalls =
      <({String imageSetId, ImageSetFacetsPatch patch})>[];
}

List<Override> _overrides(_Probe probe, {ImageSetFacets? facetsOverride}) {
  return <Override>[
    ...domainEventBusOverrides(),
    imageSetUpdateNameCommandProvider.overrideWithValue(
      (String imageSetId, String name) async {
        probe.nameCalls.add((imageSetId: imageSetId, name: name));
      },
    ),
    imageSetSetNameLockedCommandProvider.overrideWithValue(
      (String imageSetId, {required bool locked}) async {
        probe.lockCalls.add((imageSetId: imageSetId, locked: locked));
      },
    ),
    imageSetUpdateFacetsCommandProvider.overrideWithValue(
      (String imageSetId, ImageSetFacetsPatch patch) async {
        probe.facetCalls.add((imageSetId: imageSetId, patch: patch));
      },
    ),
    imageSetFacetDictionaryProvider.overrideWith(
      (Ref ref, ImageSetNamedFacetKind kind) async {
        if (facetsOverride != null) {
          return switch (kind) {
            ImageSetNamedFacetKind.author => facetsOverride.authors,
            ImageSetNamedFacetKind.tag => facetsOverride.tags,
            ImageSetNamedFacetKind.parody => facetsOverride.parodies,
            ImageSetNamedFacetKind.character => facetsOverride.characters,
          };
        }
        return const <String>['Alice', 'tag-a'];
      },
    ),
  ];
}

Future<void> _pumpEdit(
  WidgetTester tester, {
  required List<Override> overrides,
  ImageSet imageSet = _imageSet,
  ImageSetFacets initialFacets = ImageSetFacets.empty,
}) async {
  configureTestView(tester, const Size(1200, 1200));
  await pumpLocalizedApp(
    tester,
    overrides: overrides,
    home: Scaffold(
      body: ImageSetMetadataEditSheet(
        imageSet: imageSet,
        initialFacets: initialFacets,
      ),
    ),
  );
}

void main() {
  testWidgets('save invokes update name command', (WidgetTester tester) async {
    final _Probe probe = _Probe();
    await _pumpEdit(tester, overrides: _overrides(probe));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(OutlinedTextField), 'renamed');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(probe.nameCalls, hasLength(1));
    expect(probe.nameCalls.single.imageSetId, 'a');
    expect(probe.nameCalls.single.name, 'renamed');
  });

  testWidgets('save invokes set name locked command', (WidgetTester tester) async {
    final _Probe probe = _Probe();
    await _pumpEdit(
      tester,
      overrides: _overrides(probe),
      imageSet: const ImageSet(
        imageSetId: 'a',
        libraryId: 'img-1',
        relativePath: 'alpha',
        name: 'alpha',
        isRoot: false,
        nameLocked: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(probe.lockCalls, hasLength(1));
    expect(probe.lockCalls.single.locked, isFalse);
  });

  testWidgets('save invokes update facets command when bindings change', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpEdit(
      tester,
      overrides: _overrides(probe),
      initialFacets: const ImageSetFacets(
        authors: <String>['Alice'],
        tags: <String>[],
        parodies: <String>[],
        characters: <String>[],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('作者'));
    await tester.pumpAndSettle();

    final Finder clearAll = find.byKey(FacetMultiSelectField.clearAllButtonKey);
    await tester.scrollUntilVisible(
      clearAll.first,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(clearAll.first);
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(probe.facetCalls, hasLength(1));
    expect(probe.facetCalls.single.patch.authors, isEmpty);
  });

  testWidgets('expanded window opens medium dialog shell', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    configureTestView(tester, const Size(1280, 900));
    await pumpLocalizedApp(
      tester,
      overrides: _overrides(probe),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showImageSetMetadataEdit(
                context: context,
                imageSet: _imageSet,
                initialFacets: ImageSetFacets.empty,
              );
            },
            child: const Text('open-edit'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-edit'));
    await tester.pumpAndSettle();

    expect(find.byType(M3EDialog), findsOneWidget);
    expect(find.byType(ImageSetMetadataEditSheet), findsOneWidget);
    expect(find.byType(M3EFullScreenDialog), findsNothing);
  });

  testWidgets('compact window opens full-screen dialog shell', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    configureTestView(tester, const Size(400, 800));
    await pumpLocalizedApp(
      tester,
      overrides: _overrides(probe),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showImageSetMetadataEdit(
                context: context,
                imageSet: _imageSet,
                initialFacets: ImageSetFacets.empty,
              );
            },
            child: const Text('open-edit'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-edit'));
    await tester.pumpAndSettle();

    expect(find.byType(M3EFullScreenDialog), findsOneWidget);
    expect(find.byType(ImageSetMetadataEditSheet), findsOneWidget);
  });
}