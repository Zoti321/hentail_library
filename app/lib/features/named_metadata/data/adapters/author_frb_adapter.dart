import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/src/rust/api/author.dart' as rust_author;
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

/// Author FRB 薄封装（owner：`src/rust/api/author.dart`）。
class AuthorFrbAdapter {
  const AuthorFrbAdapter();

  Future<List<rust_author.AuthorIdentityFrbDto>> listAll() =>
      guardFrb(rust_author.listAllAuthorsFrb, fallbackMessage: '读取作者列表失败');

  Stream<List<rust_author.AuthorIdentityFrbDto>> watchAll() => guardFrbStream(
    () => rust_author.watchAuthorsFrb(),
    fallbackMessage: '监听作者列表失败',
  );

  Future<rust_author.AuthorPagedDto> fetchPage(PageRequest request) => guardFrb(
    () => rust_author.fetchAuthorsPageFrb(
      request: rust.PageRequestDto(
        page: request.page,
        pageSize: request.pageSize,
      ),
    ),
    fallbackMessage: '读取作者分页失败',
  );

  Future<rust_author.AuthorIdentityFrbDto> add({required String name}) =>
      guardFrb(
        () => rust_author.addAuthorFrb(name: name),
        fallbackMessage: '添加作者失败',
      );

  Future<void> deleteByNames(List<String> names) => guardFrb(
    () => rust_author.deleteAuthorsByNamesFrb(names: names),
    fallbackMessage: '删除作者失败',
  );

  Future<void> rename({required String oldName, required String newName}) =>
      guardFrb(
        () => rust_author.renameAuthorFrb(oldName: oldName, newName: newName),
        fallbackMessage: '重命名作者失败',
      );

  Future<rust_author.AuthorDetailFrbDto?> getDetail({
    required int authorId,
    required bool showR18,
  }) => guardFrb(
    () => rust_author.getAuthorDetailFrb(
      authorId: _toI64(authorId),
      showR18: showR18,
    ),
    fallbackMessage: '读取作者详情失败',
  );

  Future<rust_author.AuthorImageRefFrbDto> resolveImage({
    required int authorId,
    required bool showR18,
  }) => guardFrb(
    () => rust_author.resolveAuthorImageFrb(
      authorId: _toI64(authorId),
      showR18: showR18,
    ),
    fallbackMessage: '读取作者形象失败',
  );

  Future<Uint8List?> loadImage({
    required int authorId,
    required AuthorImageSlot slot,
    required bool showR18,
  }) => guardFrb(
    () => rust_author.loadAuthorImageFrb(
      authorId: _toI64(authorId),
      slot: switch (slot) {
        AuthorImageSlot.avatar => rust_author.AuthorImageSlotFrb.avatar,
        AuthorImageSlot.background => rust_author.AuthorImageSlotFrb.background,
      },
      showR18: showR18,
    ),
    fallbackMessage: '读取作者形象高清图失败',
  );

  Future<rust_author.AuthorLinkFrbDto> addLink({
    required int authorId,
    required rust_author.AuthorLinkPlatformFrb platform,
    required String url,
    String? platformDisplayName,
  }) => guardFrb(
    () => rust_author.addAuthorLinkFrb(
      authorId: _toI64(authorId),
      platform: platform,
      url: url,
      platformDisplayName: platformDisplayName,
    ),
    fallbackMessage: '添加作者链接失败',
  );

  Future<void> updateLink({
    required int linkId,
    required rust_author.AuthorLinkPlatformFrb platform,
    required String url,
    String? platformDisplayName,
  }) => guardFrb(
    () => rust_author.updateAuthorLinkFrb(
      linkId: _toI64(linkId),
      platform: platform,
      url: url,
      platformDisplayName: platformDisplayName,
    ),
    fallbackMessage: '更新作者链接失败',
  );

  Future<void> deleteLink({required int authorId, required int linkId}) =>
      guardFrb(
        () => rust_author.deleteAuthorLinkFrb(
          authorId: _toI64(authorId),
          linkId: _toI64(linkId),
        ),
        fallbackMessage: '删除作者链接失败',
      );
}

PlatformInt64 _toI64(int value) => PlatformInt64.parse(value.toString());
