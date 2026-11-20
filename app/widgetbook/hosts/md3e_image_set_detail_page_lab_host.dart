import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_cover_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:riverpod/misc.dart' show Override;

import '../preview/md3e_image_set_browse_preview_data.dart';

/// Lab / Widgetbook：Image set detail with optional read-only facets (no FRB).
class ImageSetDetailPageLabHost extends StatelessWidget {
  const ImageSetDetailPageLabHost({
    super.key,
    this.imageSet = Md3eImageSetBrowsePreviewData.alpha,
    this.facets = Md3eImageSetBrowsePreviewData.alphaFacets,
    this.images = Md3eImageSetBrowsePreviewData.alphaImages,
  });

  final ImageSet imageSet;
  final ImageSetFacets facets;
  final List<ImageSetImage> images;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: _overrides(imageSet: imageSet, facets: facets, images: images),
      child: ImageSetDetailPage(
        libraryId: imageSet.libraryId,
        imageSet: imageSet,
      ),
    );
  }
}

List<Override> _overrides({
  required ImageSet imageSet,
  required ImageSetFacets facets,
  required List<ImageSetImage> images,
}) => <Override>[
  libraryRevisionStateProvider.overrideWithValue(const LibraryRevisionState()),
  imageSetImagesQueryProvider.overrideWithValue(
    (String libraryId, String imageSetId) async =>
        imageSetId == imageSet.imageSetId ? images : const <ImageSetImage>[],
  ),
  imageSetFacetsQueryProvider.overrideWithValue(
    (String imageSetId) async =>
        imageSetId == imageSet.imageSetId ? facets : ImageSetFacets.empty,
  ),
  imageSetPageBytesQueryProvider.overrideWithValue(
    (String libraryId, ImageSetImage image) async =>
        Md3eImageSetBrowsePreviewData.png1x1,
  ),
  imageSetEnsureCoverQueryProvider.overrideWithValue(
    ({
      required String libraryId,
      required String imageSetId,
      required ThumbnailPriority priority,
    }) async => Md3eImageSetBrowsePreviewData.png1x1,
  ),
  imageSetFindCoverQueryProvider.overrideWithValue(
    (String imageSetId) async => Md3eImageSetBrowsePreviewData.png1x1,
  ),
  imageSetReaderEntryCommandProvider.overrideWithValue((_) {}),
  imageSetWorkspaceImagesQueryProvider.overrideWithValue(
    (String libraryId, String imageSetId) async => images,
  ),
  imageSetSubmissionsQueryProvider.overrideWithValue(
    (_, __) async => const <ImageSetSubmission>[],
  ),
  imageSetCreateSubmissionCommandProvider.overrideWithValue(
    (_, __, ___) async => throw UnimplementedError('Lab preview'),
  ),
  imageSetRenameSubmissionCommandProvider.overrideWithValue(
    (_, __, ___) async {},
  ),
  imageSetDeleteSubmissionCommandProvider.overrideWithValue((_, __) async {}),
  imageSetAddSubmissionMembersCommandProvider.overrideWithValue(
    (_, __, ___) async {},
  ),
  imageSetRemoveSubmissionMembersCommandProvider.overrideWithValue(
    (_, __, ___) async {},
  ),
  imageSetReorderSubmissionMembersCommandProvider.overrideWithValue(
    (_, __, ___) async {},
  ),
];
