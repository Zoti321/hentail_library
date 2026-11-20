import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';

/// Image set Reader 的 go_router query 编解码（对齐 [ReaderRouteArgs] 与 ADR-0061）。
class ImageSetReaderRouteArgs {
  const ImageSetReaderRouteArgs({
    required this.libraryId,
    required this.imageSetId,
    required this.startIndex,
    this.imageSetImageId,
  });

  static const String libraryIdKey = 'library_id';
  static const String imageSetIdKey = 'image_set_id';
  static const String startIndexKey = 'start_index';
  static const String imageSetImageIdKey = 'image_set_image_id';

  final String libraryId;
  final String imageSetId;
  final int startIndex;
  final String? imageSetImageId;

  factory ImageSetReaderRouteArgs.fromEntry(ImageSetReaderEntry entry) {
    return ImageSetReaderRouteArgs(
      libraryId: entry.libraryId,
      imageSetId: entry.imageSetId,
      startIndex: entry.index,
      imageSetImageId: entry.imageSetImageId,
    );
  }

  factory ImageSetReaderRouteArgs.resolve({
    required String libraryId,
    required String imageSetId,
    required Map<String, String> queryParameters,
  }) {
    final String? imageId = queryParameters[imageSetImageIdKey]?.trim();
    final int index = int.tryParse(queryParameters[startIndexKey] ?? '') ?? 0;
    return ImageSetReaderRouteArgs(
      libraryId: libraryId,
      imageSetId: imageSetId,
      startIndex: index,
      imageSetImageId: imageId?.isEmpty ?? true ? null : imageId,
    );
  }

  ImageSetReaderEntry toEntry() {
    return ImageSetReaderEntry(
      libraryId: libraryId,
      imageSetId: imageSetId,
      imageSetImageId: imageSetImageId ?? '',
      index: startIndex,
    );
  }

  ReaderRouteContext toRouteContext() {
    return ReaderRouteContext.imageSet(
      libraryId: libraryId,
      imageSetId: imageSetId,
      startIndex: startIndex,
      imageSetImageId: imageSetImageId,
    );
  }

  Map<String, String> toQueryParameters() {
    final Map<String, String> query = <String, String>{
      startIndexKey: '$startIndex',
    };
    final String? imageId = imageSetImageId?.trim();
    if (imageId != null && imageId.isNotEmpty) {
      query[imageSetImageIdKey] = imageId;
    }
    return query;
  }
}