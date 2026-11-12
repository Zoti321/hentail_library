import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/tag.dart' as rust_tag;

/// Tag dictionary import FRB 薄封装（owner：`src/rust/api/tag.dart`）。
class TagFrbAdapter {
  const TagFrbAdapter();

  rust_tag.TagDictionaryImportResultDto importTagDictionary(
    List<int> jsonBytes,
  ) => guardFrbSync(
    () => rust_tag.importTagDictionaryFrb(jsonBytes: jsonBytes),
    fallbackMessage: '导入标签字典失败',
  );
}
