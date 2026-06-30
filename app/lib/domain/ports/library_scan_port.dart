import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';

/// Saved path 扫描产出的一条可入库 [Comic]。
typedef LibraryScanItem = ({
  String path,
  ResourceType resourceType,
  Comic comic,
});

/// Library sync 扫描 seam：遍历 Saved path，产出领域 [Comic]。
abstract class LibraryScanPort {
  Stream<LibraryScanItem> scanRoots(
    Iterable<String> roots, {
    bool Function()? isCancelled,
  });
}
