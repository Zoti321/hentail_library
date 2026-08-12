import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';

abstract class LibraryRepository {
  Future<List<LocalLibrary>> list();

  Future<LocalLibrary> createLocal(String rootPath);

  Future<void> delete(String libraryId);

  Future<String?> getCurrentId();

  Future<void> setCurrentId(String? libraryId);

  Future<LocalLibrary> updateFormatGroups({
    required String libraryId,
    required List<FormatGroup> groups,
  });
}
