import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/app_update/app_update_service.dart';

void main() {
  group('AppUpdateService.parseReleaseNotes', () {
    late AppUpdateService service;

    setUp(() {
      service = AppUpdateService();
    });

    test('returns empty list for null or blank body', () {
      expect(service.parseReleaseNotes(null), isEmpty);
      expect(service.parseReleaseNotes(''), isEmpty);
      expect(service.parseReleaseNotes('   \n  '), isEmpty);
    });

    test('v0.2.6 body keeps only the user-facing bullet', () {
      const String body = '''
## Build status

| Platform | Result |
| --- | --- |
| Windows | success |
| macOS | success |
| Linux | success |
| Android | success |
| iOS | failure |

> **部分平台构建失败：** 本 Release 仅包含本次成功产物。修复后可对同一 tag 再次发版（推送 tag 或 `workflow_dispatch` + `publish_release`），成功平台的资产会追加/覆盖到本 Release。

## What's Changed
* 集成 #111–#113：Path migration、Named facet 续载与 Auto-play by @Zoti321 in https://github.com/Zoti321/hentail_library/pull/114


**Full Changelog**: https://github.com/Zoti321/hentail_library/compare/v0.2.5...v0.2.6
''';

      expect(service.parseReleaseNotes(body), <String>[
        '集成 #111–#113：Path migration、Named facet 续载与 Auto-play',
      ]);
    });

    test('v0.2.5 body keeps three change bullets', () {
      const String body = '''
> **iOS：** `ios-arm64-nosign` 为未签名包，无法直接安装到设备，仅供验证 CI 构建。

## What's Changed
* 体验修复：库同步/启动扫描、搜索与阅读器跳页 (#90–#95) by @Zoti321 in https://github.com/Zoti321/hentail_library/pull/96
* 库/阅读器/管理页：#97–#101 功能集成 by @Zoti321 in https://github.com/Zoti321/hentail_library/pull/102
* 加固测试体系：CI 硬门禁、FRB 契约测与共享 harness (#106) by @Zoti321 in https://github.com/Zoti321/hentail_library/pull/110


**Full Changelog**: https://github.com/Zoti321/hentail_library/compare/v0.2.4...v0.2.5
''';

      expect(service.parseReleaseNotes(body), <String>[
        '体验修复：库同步/启动扫描、搜索与阅读器跳页 (#90–#95)',
        '库/阅读器/管理页：#97–#101 功能集成',
        '加固测试体系：CI 硬门禁、FRB 契约测与共享 harness (#106)',
      ]);
    });

    test(
      'Kazumi 2.3.2 style body keeps ten bullets without contributor tags',
      () {
        const String body = '''
- 优化平板电脑与折叠屏布局适配 (@Predidit)
- 设置页面现在支持宽屏分栏布局 (@LiggMax) (@Predidit)
- 支持通过 WebDAV 同步弹幕屏蔽规则 (#1141 #2503) (@Predidit)
- 低内存模式现在可以在数据网络下禁用 (#2514) (@Predidit)
- 修复关闭评分显示后搜索结果和追番页面仍显示评分的问题 (#2545) (@Predidit)
- 修复搜索结果中部分番剧标题显示不全的问题 (#2539) (@Predidit)
- 修复搜索页面布局切换时输入法连接中断的问题 (@Predidit)
- 修复未启用 WebDAV 观看历史同步时启动仍自动同步的问题 (@melancholyFishAndWater)
- 修复退出播放页面时加载指示器一闪而过的问题 (@Predidit)
- 其他 UI 调整 (@Predidit)
''';

        expect(service.parseReleaseNotes(body), <String>[
          '优化平板电脑与折叠屏布局适配',
          '设置页面现在支持宽屏分栏布局',
          '支持通过 WebDAV 同步弹幕屏蔽规则 (#1141 #2503)',
          '低内存模式现在可以在数据网络下禁用 (#2514)',
          '修复关闭评分显示后搜索结果和追番页面仍显示评分的问题 (#2545)',
          '修复搜索结果中部分番剧标题显示不全的问题 (#2539)',
          '修复搜索页面布局切换时输入法连接中断的问题',
          '修复未启用 WebDAV 观看历史同步时启动仍自动同步的问题',
          '修复退出播放页面时加载指示器一闪而过的问题',
          '其他 UI 调整',
        ]);
      },
    );

    test('composed release body keeps bullets only under 更新内容', () {
      const String body = '''
## 更新内容
- 集成 #111–#113：Path migration、Named facet 续载与 Auto-play

> **iOS：** notice

## What's Changed

**Full Changelog**: https://github.com/Zoti321/hentail_library/compare/v0.2.5...v0.2.6
''';

      expect(service.parseReleaseNotes(body), <String>[
        '集成 #111–#113：Path migration、Named facet 续载与 Auto-play',
      ]);
    });

    test('ignores tables, headings, and blockquotes without list markers', () {
      const String body = '''
## Build status
| Platform | Result |
| --- | --- |
> **iOS：** notice only
''';

      expect(service.parseReleaseNotes(body), isEmpty);
    });
  });
}
