/// bootstrap / 测试注入用的 命令工厂（实现仍在 owner [di/library_commands.dart]）。
library;

import 'package:hentai_library/features/library_admin/data/adapters/remote_credentials_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/remote_library_credentials_port.dart';

export 'package:hentai_library/features/library_admin/di/library_commands.dart'
    show
        createDeleteLibraryCommand,
        createUpdateLibrarySidebarCommand,
        createSubmitLibraryFormCommand,
        createStartLibraryScanCommand,
        createCancelLibraryScanCommand,
        createRefreshComicMetadataCommand,
        createRefreshSeriesMetadataCommand,
        createRefreshLibraryMetadataCommand,
        createCancelMetadataRefreshCommand,
        createBulkEditComicMetadataCommand,
        createExitLibraryReorderCommand;

RemoteLibraryCredentialsPort createRemoteLibraryCredentialsPort(
  LibraryRepository libraryRepository,
) => RemoteLibraryCredentialsFrbAdapter(libraryRepository);
