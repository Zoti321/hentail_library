/// 全局 Author / Tag 字典只读 token（ADR-0048）。
///
/// 由 `comic_metadata` 拥有；实现由 bootstrap 用 `allTagsProvider` /
/// `allAuthorsProvider` override（`metadata_dictionary_shared_state_overrides`）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<AsyncValue<List<Tag>>> libraryTagDictionaryStateProvider =
    requiredProvider('libraryTagDictionaryStateProvider');

final Provider<AsyncValue<List<Author>>> libraryAuthorDictionaryStateProvider =
    requiredProvider('libraryAuthorDictionaryStateProvider');
