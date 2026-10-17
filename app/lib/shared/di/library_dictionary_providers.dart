import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';

/// 字典只读状态（#268）：library_browse 等消费方只读，不依赖 named_metadata。
///
/// 实现由 bootstrap 通过 `overrideWith` 桥接到 named_metadata 的 Provider。
final Provider<AsyncValue<List<Tag>>> libraryTagDictionaryStateProvider =
    Provider<AsyncValue<List<Tag>>>(
      (Ref ref) => throw UnimplementedError(
        'libraryTagDictionaryStateProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<AsyncValue<List<Author>>> libraryAuthorDictionaryStateProvider =
    Provider<AsyncValue<List<Author>>>(
      (Ref ref) => throw UnimplementedError(
        'libraryAuthorDictionaryStateProvider 未注入，请在 bootstrap 中 override',
      ),
    );
