import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';

/// composition：把 image_set_library repository 接到 Reader [ImageSetReadPort]。
class ImageSetReadPortAdapter implements ImageSetReadPort {
  const ImageSetReadPortAdapter(this._repository);

  final ImageSetRepository _repository;

  @override
  Future<ImageSetOpenedReadSession> openSession({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  }) async {
    final ImageSetReaderSession session = await _repository.openReaderSession(
      libraryId,
      imageSetId,
      startIndex,
    );
    final List<ImageSetReadPage> pages = <ImageSetReadPage>[
      for (int i = 0; i < session.pages.length; i++)
        _toReadPage(session.pages[i], i),
    ];
    final String title = pages.isEmpty
        ? imageSetId
        : (pages.first.name.isNotEmpty ? pages.first.name : imageSetId);
    return ImageSetOpenedReadSession(
      libraryId: session.libraryId,
      imageSetId: session.imageSetId,
      title: title,
      pages: pages,
      startIndex: session.startIndex,
    );
  }

  @override
  Future<Uint8List> loadPageBytes(ImageSetReadPage page) {
    return _repository.loadPageBytes(page.libraryId, _toDomainImage(page));
  }

  static ImageSetReadPage _toReadPage(ImageSetImage image, int index) {
    return ImageSetReadPage(
      imageSetImageId: image.imageSetImageId,
      imageSetId: image.imageSetId,
      libraryId: image.libraryId,
      carrierRelativePath: image.carrierRelativePath,
      memberPath: image.memberPath,
      carrierKind: image.carrierKind,
      name: image.name,
      index: index,
    );
  }

  static ImageSetImage _toDomainImage(ImageSetReadPage page) {
    return ImageSetImage(
      imageSetImageId: page.imageSetImageId,
      imageSetId: page.imageSetId,
      libraryId: page.libraryId,
      carrierRelativePath: page.carrierRelativePath,
      memberPath: page.memberPath,
      carrierKind: page.carrierKind,
      name: page.name,
    );
  }
}
