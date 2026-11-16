import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';

class OpenImageSetReaderUseCase {
  const OpenImageSetReaderUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<ImageSetReaderSession> call(ImageSetReaderEntry entry) => _repository
      .openReaderSession(entry.libraryId, entry.imageSetId, entry.index);
}

class LoadImageSetPageBytesUseCase {
  const LoadImageSetPageBytesUseCase(this._repository);

  final ImageSetRepository _repository;

  Future<Uint8List> call(String libraryId, ImageSetImage image) =>
      _repository.loadPageBytes(libraryId, image);
}
