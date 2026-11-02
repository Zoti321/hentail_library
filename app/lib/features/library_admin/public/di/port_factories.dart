/// bootstrap / 测试注入用的 Port 工厂（实现仍在 owner [di/shared_state_ports.dart]）。
library;

export 'package:hentai_library/features/library_admin/di/shared_state_ports.dart'
    show
        createComicMetadataBulkEditCommandPort,
        createCurrentLibraryPort,
        createLibraryMetadataRefreshCommandPort,
        createLibraryReorderModePort,
        createLibraryRevisionSignalPort,
        createLibraryScanCommandPort;
