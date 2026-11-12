import 'package:hentai_library/shared/domain/models/enums.dart';

/// [ResourceType] → Rust/FRB 筛选与阅读 API 使用的 wire 字符串。
String mapResourceType(ResourceType type) {
  return switch (type) {
    ResourceType.dir => 'dir',
    ResourceType.zip => 'zip',
    ResourceType.cbz => 'cbz',
    ResourceType.epub => 'epub',
    ResourceType.cbr => 'cbr',
    ResourceType.rar => 'rar',
    ResourceType.cb7 => 'cb7',
    ResourceType.sevenZ => 'sevenz',
    ResourceType.pdf => 'pdf',
  };
}
