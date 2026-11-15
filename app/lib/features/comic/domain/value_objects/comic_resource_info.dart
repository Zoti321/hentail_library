import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

part 'comic_resource_info.freezed.dart';

@freezed
abstract class ComicResourceInfo with _$ComicResourceInfo {
  const factory ComicResourceInfo({
    required String path,
    required ResourceType resourceType,
    required int resourceSize,
    required int pageCount,
  }) = _ComicResourceInfo;
}
