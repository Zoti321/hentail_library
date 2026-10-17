import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/catalog_selection_command_port.dart';
import 'package:hentai_library/shared/domain/ports/dictionary_invalidation_port.dart';
import 'package:hentai_library/shared/domain/ports/metadata_saved_port.dart';

/// library_admin 对其它 feature 的命令端口声明（#267）。
///
/// 只声明、不实现；默认抛 [UnimplementedError]，由 bootstrap 通过 `overrideWith` 注入实现。

final Provider<CatalogSelectionCommandPort>
catalogSelectionCommandPortProvider = Provider<CatalogSelectionCommandPort>(
  (Ref ref) => throw UnimplementedError(
    'catalogSelectionCommandPortProvider 未注入，请在 bootstrap 中 override',
  ),
);

final Provider<DictionaryInvalidationPort> dictionaryInvalidationPortProvider =
    Provider<DictionaryInvalidationPort>(
      (Ref ref) => throw UnimplementedError(
        'dictionaryInvalidationPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<MetadataSavedPort> metadataSavedPortProvider =
    Provider<MetadataSavedPort>(
      (Ref ref) => throw UnimplementedError(
        'metadataSavedPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
