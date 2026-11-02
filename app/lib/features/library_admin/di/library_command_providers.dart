import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/domain/library_metadata_refresh_command_port.dart';

final Provider<LibraryMetadataRefreshCommandPort>
libraryMetadataRefreshCommandPortProvider =
    Provider<LibraryMetadataRefreshCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'libraryMetadataRefreshCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
