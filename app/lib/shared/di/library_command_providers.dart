import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/features/library_admin/domain/library_metadata_refresh_command_port.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';

final Provider<LibraryMetadataRefreshCommandPort>
libraryMetadataRefreshCommandPortProvider = injectedDi(
  'libraryMetadataRefreshCommandPortProvider',
);

final Provider<ComicTrashCommandPort> comicTrashCommandPortProvider =
    injectedDi('comicTrashCommandPortProvider');
