import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/tag_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;
import 'package:hentai_library/src/rust/api/tag.dart' as rust_tag;

class TagRepositoryImpl implements TagRepository {
  const TagRepositoryImpl();

  @override
  Future<List<Tag>> listAll() async {
    final List<String> names = rust_tag.listAllTagsFrb();
    return names.map((String n) => Tag(name: n)).toList();
  }

  @override
  Future<PagedResult<Tag>> fetchPage(PageRequest request) async {
    final rust_tag.TagPagedNamesDto page = rust_tag.fetchTagsPageFrb(
      request: rust.PageRequestDto(
        page: request.page,
        pageSize: request.pageSize,
      ),
    );
    return PagedResult<Tag>(
      items: page.items.map((String n) => Tag(name: n)).toList(),
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<void> add(Tag tag) async {
    rust_tag.addTagFrb(name: tag.name);
  }

  @override
  Future<void> deleteByNames(List<String> names) async {
    rust_tag.deleteTagsByNamesFrb(names: names);
  }

  @override
  Future<void> rename(String oldName, String newName) async {
    rust_tag.renameTagFrb(oldName: oldName, newName: newName);
  }
}
