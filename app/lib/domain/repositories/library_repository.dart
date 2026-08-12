import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';

abstract class LibraryRepository {
  Future<List<LocalLibrary>> list();

  Future<LocalLibrary> createLocal(String rootPath);

  Future<LocalLibrary> createRemote({
    required String rootUrl,
    required String username,
    required String password,
    required bool allowHttp,
  });

  Future<LocalLibrary> updateRemote({
    required String libraryId,
    required String rootUrl,
    required String username,
    required bool allowHttp,

    /// `null` 表示保留原密码；非 null（可为空串）则覆盖。
    String? password,
  });

  Future<void> delete(String libraryId);

  Future<String?> getCurrentId();

  Future<void> setCurrentId(String? libraryId);

  Future<LocalLibrary> updateFormatGroups({
    required String libraryId,
    required List<FormatGroup> groups,
  });

  /// 供后续 Remote sync / read 注入 core；登记阶段仅保证可读写。
  Future<String?> readRemotePassword(String libraryId);
}
