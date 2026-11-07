import 'dart:typed_data';

import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

/// Author 仓储：稳定身份字典、Author link 与详情聚合。
abstract class AuthorRepository {
  Future<List<Author>> listAll();

  Stream<List<Author>> watchAll();

  Future<PagedResult<Author>> fetchPage(PageRequest request);

  Future<Author> add(Author author);

  Future<void> deleteByNames(List<String> names);

  Future<void> rename(String oldName, String newName);

  Future<AuthorDetail?> getDetail({
    required int authorId,
    required bool showR18,
  });

  /// Author image 高清字节；`null` 表示无高清图（仅显示库缩略图）。
  Future<Uint8List?> loadImage({
    required int authorId,
    required AuthorImageSlot slot,
    required bool showR18,
  });

  Future<AuthorLink> addLink({
    required int authorId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  });

  Future<void> updateLink({
    required int linkId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  });

  Future<void> deleteLink({required int authorId, required int linkId});
}
