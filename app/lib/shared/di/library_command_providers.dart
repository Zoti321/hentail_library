import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/catalog_selection_command_port.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';

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
