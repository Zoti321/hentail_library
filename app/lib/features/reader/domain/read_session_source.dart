/// Read session 打开来源：Comic 或 Image set（有序页集合）。
sealed class ReadSessionSource {
  const ReadSessionSource();

  /// Opaque cache / ViewModel key（Comic 用 comicId；Image set 用稳定前缀键）。
  String get sessionKey;

  bool get isImageSet => this is ImageSetReadSessionSource;
  bool get isComic => this is ComicReadSessionSource;
}

final class ComicReadSessionSource extends ReadSessionSource {
  const ComicReadSessionSource(this.comicId);

  final String comicId;

  @override
  String get sessionKey => comicId;

  @override
  bool operator ==(Object other) =>
      other is ComicReadSessionSource && other.comicId == comicId;

  @override
  int get hashCode => comicId.hashCode;
}

final class ImageSetReadSessionSource extends ReadSessionSource {
  const ImageSetReadSessionSource({
    required this.libraryId,
    required this.imageSetId,
    required this.startIndex,
    this.imageSetImageId,
  });

  final String libraryId;
  final String imageSetId;

  /// Selected image identity; when present it takes precedence over the index.
  final String? imageSetImageId;

  /// 0-based catalog start index.
  final int startIndex;

  @override
  String get sessionKey => imageSetReadSessionKey(libraryId, imageSetId);

  @override
  bool operator ==(Object other) =>
      other is ImageSetReadSessionSource &&
      other.libraryId == libraryId &&
      other.imageSetId == imageSetId &&
      other.startIndex == startIndex &&
      other.imageSetImageId == imageSetImageId;

  @override
  int get hashCode =>
      Object.hash(libraryId, imageSetId, startIndex, imageSetImageId);
}

String imageSetReadSessionKey(String libraryId, String imageSetId) =>
    'image_set:$libraryId:$imageSetId';
