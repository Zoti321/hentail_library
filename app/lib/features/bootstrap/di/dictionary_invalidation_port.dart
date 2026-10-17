import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_distinct_metadata_providers.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/author_management_notifier.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_dictionary_providers.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/shared/domain/ports/dictionary_invalidation_port.dart';

/// 字典缓存失效适配器（#267）。
///
/// 位于 bootstrap（组合根），因为需要同时失效 named_metadata 与 library_browse 的 Provider。
class _DictionaryInvalidationAdapter implements DictionaryInvalidationPort {
  _DictionaryInvalidationAdapter(this._ref);

  final Ref _ref;

  @override
  void invalidate({
    required bool tagsWritten,
    required bool authorsWritten,
    required bool parodiesWritten,
    required bool charactersWritten,
  }) {
    if (tagsWritten) {
      _ref.invalidate(allTagsProvider);
    }
    if (authorsWritten) {
      _ref.invalidate(allAuthorsProvider);
    }
    if (parodiesWritten) {
      _ref.invalidate(allParodiesProvider);
      _ref.invalidate(libraryDistinctParodiesProvider);
    }
    if (charactersWritten) {
      _ref.invalidate(allCharactersProvider);
      _ref.invalidate(libraryDistinctCharactersProvider);
    }
  }
}

DictionaryInvalidationPort createDictionaryInvalidationPort(Ref ref) =>
    _DictionaryInvalidationAdapter(ref);
