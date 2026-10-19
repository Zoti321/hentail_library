import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/library/library_metadata_refresh_command_port.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';

final Provider<LibraryMetadataRefreshCommandPort>
libraryMetadataRefreshCommandPortProvider =
    Provider<LibraryMetadataRefreshCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'libraryMetadataRefreshCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<ComicTrashCommandPort> comicTrashCommandPortProvider =
    Provider<ComicTrashCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'comicTrashCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
