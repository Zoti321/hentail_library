/// bootstrap / 测试注入用的 Port 工厂（实现仍在 owner [di/shared_state_ports.dart]）。
library;

import 'package:hentai_library/features/library_admin/data/adapters/remote_credentials_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/shared/domain/ports/remote_library_credentials_port.dart';

export 'package:hentai_library/features/library_admin/di/shared_state_ports.dart'
    show
        createComicMetadataBulkEditCommandPort,
        createLibrariesPort,
        createLibraryMetadataRefreshCommandPort,
        createLibraryReorderModePort,
        createLibraryScanCommandPort;

RemoteLibraryCredentialsPort createRemoteLibraryCredentialsPort(
  LibraryRepository libraryRepository,
) => RemoteLibraryCredentialsFrbAdapter(libraryRepository);
