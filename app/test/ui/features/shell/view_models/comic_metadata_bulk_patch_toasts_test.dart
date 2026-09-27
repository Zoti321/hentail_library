import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/ui/features/shell/view_models/comic_metadata_bulk_patch_toasts.dart';

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  test('done message includes succeeded failed unchanged', () {
    const ComicMetadataBulkPatchResult result = (
      succeeded: 3,
      failed: 1,
      unchanged: 2,
      cancelled: false,
      errorSamples: <String>[],
    );
    expect(
      comicMetadataBulkPatchMessage(l10n, result),
      '批量编辑完成：已更新 3，失败 1，无变化 2',
    );
  });

  test('cancelled message uses cancelled template', () {
    const ComicMetadataBulkPatchResult result = (
      succeeded: 1,
      failed: 0,
      unchanged: 0,
      cancelled: true,
      errorSamples: <String>[],
    );
    expect(
      comicMetadataBulkPatchMessage(l10n, result),
      '已取消批量编辑（已更新 1，失败 0，无变化 0）',
    );
  });
}
