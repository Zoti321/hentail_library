import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_browse_preferences_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_browse_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_library_filter_sheet.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_library_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:riverpod/misc.dart' show Override;

import '../preview/md3e_image_set_browse_preview_data.dart';

enum ImageSetLibraryLabScenario { loading, empty, populated }

/// Lab / Widgetbook：Image set library browse with in-memory fakes (no FRB).
class ImageSetLibraryPageLabHost extends StatelessWidget {
  const ImageSetLibraryPageLabHost({
    super.key,
    this.scenario = ImageSetLibraryLabScenario.populated,
    this.initialViewMode = CatalogViewMode.grid,
    this.initialPreferences = ImageSetBrowsePreferences.defaults,
    this.openFilterSheet = false,
  });

  final ImageSetLibraryLabScenario scenario;
  final CatalogViewMode initialViewMode;
  final ImageSetBrowsePreferences initialPreferences;
  final bool openFilterSheet;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: _labOverrides(
        scenario: scenario,
        initialPreferences: initialPreferences,
      ),
      child: _ImageSetLibraryLabBody(
        initialViewMode: initialViewMode,
        openFilterSheet: openFilterSheet,
      ),
    );
  }
}

class _ImageSetLibraryLabBody extends StatefulWidget {
  const _ImageSetLibraryLabBody({
    required this.initialViewMode,
    required this.openFilterSheet,
  });

  final CatalogViewMode initialViewMode;
  final bool openFilterSheet;

  @override
  State<_ImageSetLibraryLabBody> createState() =>
      _ImageSetLibraryLabBodyState();
}

class _ImageSetLibraryLabBodyState extends State<_ImageSetLibraryLabBody> {
  @override
  void initState() {
    super.initState();
    if (widget.openFilterSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(
          ImageSetLibraryFilterSheet.show(
            context,
            libraryId: Md3eImageSetBrowsePreviewData.libraryId,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImageSetLibraryPage(
      libraryId: Md3eImageSetBrowsePreviewData.libraryId,
      displayName: Md3eImageSetBrowsePreviewData.displayName,
      initialViewMode: widget.initialViewMode,
    );
  }
}

class _MemoryPrefs implements ImageSetBrowsePreferencesRepository {
  _MemoryPrefs(this.value);

  ImageSetBrowsePreferences value;

  @override
  Future<ImageSetBrowsePreferences> load() async => value;

  @override
  Future<void> save(ImageSetBrowsePreferences preferences) async {
    value = preferences;
  }

  @override
  Future<void> reset() async {
    value = ImageSetBrowsePreferences.defaults;
  }
}

List<Override> _labOverrides({
  required ImageSetLibraryLabScenario scenario,
  required ImageSetBrowsePreferences initialPreferences,
}) {
  final _MemoryPrefs prefs = _MemoryPrefs(initialPreferences);
  return <Override>[
    libraryRevisionStateProvider.overrideWithValue(
      const LibraryRevisionState(),
    ),
    librarySyncStateProvider.overrideWithValue((
      running: false,
      cancelled: false,
      targetLibraryId: null,
      error: null,
      progress: null,
    )),
    imageSetBrowsePreferencesRepositoryProvider.overrideWithValue(prefs),
    imageSetCatalogPageQueryProvider.overrideWithValue(
      ({
        required String libraryId,
        required PageRequest request,
        required ImageSetBrowsePreferences preferences,
      }) async {
        switch (scenario) {
          case ImageSetLibraryLabScenario.loading:
            return Completer<PagedImageSetCatalog>().future;
          case ImageSetLibraryLabScenario.empty:
            return PagedImageSetCatalog(
              items: const <ImageSetCatalogItem>[],
              totalCount: 0,
              page: request.page,
              pageSize: request.pageSize,
            );
          case ImageSetLibraryLabScenario.populated:
            return PagedImageSetCatalog(
              items: Md3eImageSetBrowsePreviewData.populatedItems,
              totalCount: Md3eImageSetBrowsePreviewData.populatedItems.length,
              page: request.page,
              pageSize: request.pageSize,
            );
        }
      },
    ),
    imageSetImagesQueryProvider.overrideWithValue(
      (String libraryId, String imageSetId) async =>
          imageSetId == Md3eImageSetBrowsePreviewData.alpha.imageSetId
          ? Md3eImageSetBrowsePreviewData.alphaImages
          : const <ImageSetImage>[],
    ),
    imageSetFacetsQueryProvider.overrideWithValue(
      (String imageSetId) async =>
          imageSetId == Md3eImageSetBrowsePreviewData.alpha.imageSetId
          ? Md3eImageSetBrowsePreviewData.alphaFacets
          : ImageSetFacets.empty,
    ),
    imageSetPageBytesQueryProvider.overrideWithValue(
      (String libraryId, ImageSetImage image) async =>
          Md3eImageSetBrowsePreviewData.png1x1,
    ),
    imageSetReaderEntryCommandProvider.overrideWithValue((_) {}),
  ];
}
