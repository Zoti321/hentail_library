import 'dart:typed_data';

import 'package:hentai_library/composition/modules/reader/image_set_read_port_adapter.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets_patch.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:test/test.dart';

class _Repo implements ImageSetRepository {
  _Repo({required this.sets, required this.pages});

  final List<ImageSet> sets;
  final List<ImageSetImage> pages;

  @override
  Future<List<ImageSet>> listImageSets(String libraryId) async => sets;

  @override
  Future<List<ImageSet>> listNonEmptyImageSets(String libraryId) async => sets;

  @override
  Future<PagedImageSetCatalog> fetchCatalogPage({
    required String libraryId,
    required PageRequest request,
    required ImageSetBrowsePreferences preferences,
  }) => throw UnimplementedError();

  @override
  Future<ImageSetFacets> fetchFacets(String imageSetId) =>
      throw UnimplementedError();

  @override
  Future<void> updateName(String imageSetId, String name) =>
      throw UnimplementedError();

  @override
  Future<void> setNameLocked(String imageSetId, {required bool locked}) =>
      throw UnimplementedError();

  @override
  Future<void> updateFacets(String imageSetId, ImageSetFacetsPatch patch) =>
      throw UnimplementedError();

  @override
  Future<List<ImageSetImage>> listImageSetImages(
    String libraryId,
    String imageSetId,
  ) async => pages;

  @override
  Future<List<ImageSetImage>> listWorkspaceImages(
    String libraryId,
    String imageSetId,
  ) async => pages;

  @override
  Future<ImageSetReaderSession> openReaderSession(
    String libraryId,
    String imageSetId,
    int startIndex,
  ) async => ImageSetReaderSession(
    libraryId: libraryId,
    imageSetId: imageSetId,
    pages: pages,
    startIndex: startIndex,
  );

  @override
  Future<Uint8List> loadPageBytes(String libraryId, ImageSetImage image) =>
      throw UnimplementedError();

  @override
  Future<ImageSetLibraryGates> getLibraryGates(String libraryId) =>
      throw UnimplementedError();

  @override
  Future<void> setResourceMutation(
    String libraryId, {
    required bool enabled,
  }) => throw UnimplementedError();

  @override
  Future<void> setManagedLayout(String libraryId, {required bool enabled}) =>
      throw UnimplementedError();

  @override
  Future<void> setImagesExcluded(
    String libraryId,
    String imageSetId,
    List<String> imageIds, {
    required bool excluded,
  }) => throw UnimplementedError();

  @override
  Future<void> reorderImages(
    String libraryId,
    String imageSetId,
    List<String> orderedIds,
  ) => throw UnimplementedError();

  @override
  Future<List<ImageSetSubmission>> listSubmissions(
    String libraryId,
    String imageSetId,
  ) => throw UnimplementedError();

  @override
  Future<ImageSetSubmission> createSubmission(
    String libraryId,
    String imageSetId,
    String name,
  ) => throw UnimplementedError();

  @override
  Future<void> renameSubmission(
    String libraryId,
    String submissionId,
    String name,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteSubmission(String libraryId, String submissionId) =>
      throw UnimplementedError();

  @override
  Future<void> addSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  ) => throw UnimplementedError();

  @override
  Future<void> removeSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  ) => throw UnimplementedError();

  @override
  Future<void> reorderSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> orderedIds,
  ) => throw UnimplementedError();

  @override
  Future<List<ImageSetImage>> copyImagesIn(
    String libraryId,
    String imageSetId,
    List<String> sourcePaths,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteImagesOnDisk(
    String libraryId,
    String imageSetId,
    List<String> imageIds,
  ) => throw UnimplementedError();

  @override
  Future<void> takeOverManagedLayout(String libraryId, String imageSetId) =>
      throw UnimplementedError();
}

void main() {
  test('openSession title uses Image set display name, not first page filename',
      () async {
    const ImageSet set = ImageSet(
      imageSetId: 'a',
      libraryId: 'lib',
      relativePath: 'alpha',
      name: 'Night Gallery',
      isRoot: false,
    );
    const ImageSetImage page = ImageSetImage(
      imageSetImageId: 'i1',
      imageSetId: 'a',
      libraryId: 'lib',
      carrierRelativePath: 'alpha/1.png',
      memberPath: '',
      carrierKind: 'loose',
      name: '1.png',
    );
    final ImageSetReadPortAdapter adapter = ImageSetReadPortAdapter(
      _Repo(sets: <ImageSet>[set], pages: <ImageSetImage>[page]),
    );

    final session = await adapter.openSession(
      libraryId: 'lib',
      imageSetId: 'a',
      startIndex: 0,
    );

    expect(session.title, 'Night Gallery');
    expect(session.pages.single.name, '1.png');
  });
}
