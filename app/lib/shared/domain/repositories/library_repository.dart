import 'package:hentai_library/shared/domain/library/resource_format_category.dart';
import 'package:hentai_library/shared/domain/library/library_sidebar_layout.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';

abstract class LibraryRepository {
  Future<List<LocalLibrary>> list();

  Future<LocalLibrary> createLocal(String rootPath, {String? name});

  Future<LocalLibrary> createRemote({
    required String rootUrl,
    required String username,
    required String password,
    required bool allowHttp,
    String? name,
  });

  Future<LocalLibrary> updateRemote({
    required String libraryId,
    required String rootUrl,
    required String username,
    required bool allowHttp,

    /// `null` 表示保留原密码；非 null（可为空串）则覆盖。
    String? password,
  });

  Future<LocalLibrary> updateLocalRoot({
    required String libraryId,
    required String rootPath,
  });

  Future<void> delete(String libraryId);

  Future<String?> getCurrentId();

  Future<void> setCurrentId(String? libraryId);

  Future<LocalLibrary> updateResourceFormatCategories({
    required String libraryId,
    required List<ResourceFormatCategory> groups,
  });

  Future<LocalLibrary> updateSettings({
    required String libraryId,
    required String name,
    required List<ResourceFormatCategory> groups,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  });

  /// Legacy `autoScan: true` → all libraries Scan on startup.
  Future<void> setAllScanOnStartup(bool enabled);

  /// Replace every Library's pin group and Library sidebar order.
  Future<List<LocalLibrary>> updateSidebarLayout(
    List<LibrarySidebarPlacement> placements,
  );

  /// 供后续 Remote sync / read 注入 core；登记阶段仅保证可读写。
  Future<String?> readRemotePassword(String libraryId);
}
