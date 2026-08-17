import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/ui/features/shell/state/metadata_refresh_toasts.dart';
import 'package:test/test.dart';

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  test('skipped remote library uses skip message', () {
    expect(
      metadataRefreshBatchMessage(l10n, (
        succeeded: 0,
        failed: 0,
        cancelled: false,
        skipped: true,
        skipMessage: '已跳过远程库（缺少凭证）: https://nas.example/dav',
      )),
      '已跳过远程库（缺少凭证）: https://nas.example/dav',
    );
  });

  test('cancelled batch reports kept writes', () {
    expect(
      metadataRefreshBatchMessage(l10n, (
        succeeded: 40,
        failed: 1,
        cancelled: true,
        skipped: false,
        skipMessage: null,
      )),
      '已取消元数据刷新（已刷新 40，失败 1）',
    );
  });

  test('completed batch reports succeeded and failed counts', () {
    expect(
      metadataRefreshBatchMessage(l10n, (
        succeeded: 120,
        failed: 3,
        cancelled: false,
        skipped: false,
        skipMessage: null,
      )),
      '元数据刷新完成：成功 120，失败 3',
    );
  });
}
