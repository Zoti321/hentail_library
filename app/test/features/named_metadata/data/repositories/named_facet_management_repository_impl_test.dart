import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/named_facet_management_repository_impl.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';

void main() {
  test('author merge refusal copy is the Author-specific message', () {
    final copy = namedFacetFallbackCopyOf(ManagedNamedFacetKind.author);
    expect(copy.merge, '作者暂不支持合并');
    expect(copy.list, '读取作者列表失败');
    expect(copy.add, '添加作者失败');
  });

  test('dictionary kinds keep their own merge copy', () {
    expect(namedFacetFallbackCopyOf(ManagedNamedFacetKind.tag).merge, '合并标签失败');
    expect(
      namedFacetFallbackCopyOf(ManagedNamedFacetKind.parody).merge,
      '合并原作失败',
    );
    expect(
      namedFacetFallbackCopyOf(ManagedNamedFacetKind.character).merge,
      '合并角色失败',
    );
  });

  test('every managed kind has complete non-empty fallback copy', () {
    for (final kind in ManagedNamedFacetKind.values) {
      final copy = namedFacetFallbackCopyOf(kind);
      for (final text in <String>[
        copy.list,
        copy.page,
        copy.add,
        copy.delete,
        copy.rename,
        copy.count,
        copy.merge,
      ]) {
        expect(text, isNotEmpty, reason: kind.name);
      }
    }
  });
}
