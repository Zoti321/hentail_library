import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/catalog_selection_command_port.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';

/// 跨 feature 命令端口的声明（只声明、不实现）。
///
/// 默认抛 [UnimplementedError]，由 bootstrap 通过 `overrideWith` 注入实现。
/// 写入通知请使用 `libraryChangeBusProvider`（见 shared/di/library_change_bus.dart）。

final Provider<CatalogSelectionCommandPort>
catalogSelectionCommandPortProvider = Provider<CatalogSelectionCommandPort>(
  (Ref ref) => throw UnimplementedError(
    'catalogSelectionCommandPortProvider 未注入，请在 bootstrap 中 override',
  ),
);

final Provider<ComicTrashCommandPort> comicTrashCommandPortProvider =
    Provider<ComicTrashCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'comicTrashCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
