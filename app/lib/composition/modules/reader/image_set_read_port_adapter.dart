import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/reader/domain/image_set_navigation.dart';
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
    final String title = await _resolveImageSetTitle(
      libraryId: libraryId,
      imageSetId: imageSetId,
    );
    return ImageSetOpenedReadSession(
      libraryId: session.libraryId,
      imageSetId: session.imageSetId,
      title: title,
      pages: pages,
      startIndex: session.startIndex,
    );
  }

  Future<String> _resolveImageSetTitle({
    required String libraryId,
    required String imageSetId,
  }) async {
    final List<ImageSet> sets = await _repository.listImageSets(libraryId);
    for (final ImageSet set in sets) {
      if (set.imageSetId == imageSetId) {
        final String name = set.name.trim();
        if (name.isNotEmpty) {
          return name;
        }
        break;
      }
    }
    return imageSetId;
  }

  @override
  Future<Uint8List> loadPageBytes(ImageSetReadPage page) {
    return _repository.loadPageBytes(page.libraryId, _toDomainImage(page));
  }

  @override
  Future<List<ImageSetNavItem>> listNavigableImageSets({
    required String libraryId,
  }) async => <ImageSetNavItem>[
    for (final ImageSet set in await _repository.listNonEmptyImageSets(
      libraryId,
    ))
      ImageSetNavItem(imageSetId: set.imageSetId, title: set.name),
  ];

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
