import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';

/// Image set catalog + workspace write contracts（owner：`image_set_library`）。
abstract interface class ImageSetRepository {
  Future<List<ImageSet>> listImageSets(String libraryId);

  /// 至少有一张图片的图集，按 Image set catalog query 默认顺序（显示名称自然序）。
  Future<List<ImageSet>> listNonEmptyImageSets(String libraryId);

  Future<List<ImageSetImage>> listImageSetImages(
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
