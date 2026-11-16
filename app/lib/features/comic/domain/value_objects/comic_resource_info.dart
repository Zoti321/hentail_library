import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/domain/value_objects/resource_fingerprint.dart';

part 'comic_resource_info.freezed.dart';

@freezed
abstract class ComicResourceInfo with _$ComicResourceInfo {
  const factory ComicResourceInfo({
    required String path,
    required ResourceType resourceType,
    required int resourceSize,
    required int pageCount,
    ResourceFingerprint? fingerprint,
  }) = _ComicResourceInfo;

  const ComicResourceInfo._();

  /// The saved fingerprint's source modification time, rather than a live stat.
  DateTime? get sourceModifiedAt => fingerprint?.sourceModifiedAt;
}
