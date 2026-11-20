import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets_patch.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';

/// Image set catalog + workspace write contracts（owner：`image_set_library`）。
abstract interface class ImageSetRepository {
  Future<List<ImageSet>> listImageSets(String libraryId);

  /// 至少有一张图片的图集，按 Image set catalog query 默认顺序（显示名称自然序）。
  Future<List<ImageSet>> listNonEmptyImageSets(String libraryId);

  /// One page of the Image set catalog for [libraryId] under [preferences].
  Future<PagedImageSetCatalog> fetchCatalogPage({
    required String libraryId,
    required PageRequest request,
    required ImageSetBrowsePreferences preferences,
  });

  /// Author / Tag / Parody / Character bindings for [imageSetId].
  Future<ImageSetFacets> fetchFacets(String imageSetId);

  Future<void> updateName(String imageSetId, String name);

  Future<void> setNameLocked(String imageSetId, {required bool locked});

  Future<void> updateFacets(String imageSetId, ImageSetFacetsPatch patch);

  Future<List<ImageSetImage>> listImageSetImages(
    String libraryId,
    String imageSetId,
  );

  /// Manage workspace: all members in user order with real `excluded`.
  Future<List<ImageSetImage>> listWorkspaceImages(
    String libraryId,
    String imageSetId,
  );

  /// 打开 Read session（只读，不写 Comic 阅读历史）。
  Future<ImageSetReaderSession> openReaderSession(
    String libraryId,
    String imageSetId,
    int startIndex,
  );

  /// 按 catalog 载体读取单页原始字节。
  Future<Uint8List> loadPageBytes(String libraryId, ImageSetImage image);

  /// Catalog cover JPEG (≤512); null when missing.
  Future<Uint8List?> findCover(String imageSetId);

  /// Ensure catalog cover; may return null while queued (non-critical).
  Future<Uint8List?> ensureCover({
    required String libraryId,
    required String imageSetId,
    required ThumbnailPriority priority,
  });

  Future<ImageSetLibraryGates> getLibraryGates(String libraryId);

  Future<void> setResourceMutation(String libraryId, {required bool enabled});

  Future<void> setManagedLayout(String libraryId, {required bool enabled});

  Future<void> setImagesExcluded(
    String libraryId,
    String imageSetId,
    List<String> imageIds, {
    required bool excluded,
  });

  Future<void> reorderImages(
    String libraryId,
    String imageSetId,
    List<String> orderedIds,
  );

  Future<List<ImageSetSubmission>> listSubmissions(
    String libraryId,
    String imageSetId,
  );

  Future<ImageSetSubmission> createSubmission(
    String libraryId,
    String imageSetId,
    String name,
  );

  Future<void> renameSubmission(
    String libraryId,
    String submissionId,
    String name,
  );

  Future<void> deleteSubmission(String libraryId, String submissionId);

  Future<void> addSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  );

  Future<void> removeSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  );

  Future<void> reorderSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> orderedIds,
  );

  Future<List<ImageSetImage>> copyImagesIn(
    String libraryId,
    String imageSetId,
    List<String> sourcePaths,
  );

  Future<void> deleteImagesOnDisk(
    String libraryId,
    String imageSetId,
    List<String> imageIds,
  );

  Future<void> takeOverManagedLayout(String libraryId, String imageSetId);
}
