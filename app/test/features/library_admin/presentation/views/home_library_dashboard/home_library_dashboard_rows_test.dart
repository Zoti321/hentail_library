import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/public/home_library_stat.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/home_library_dashboard_rows.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/resource_format_category.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

final DateTime _now = DateTime(2026, 11, 12, 12);

LocalLibrary _library({
  required String id,
  String kind = 'local',
  String name = '',
  String rootPath = '/lib/a',
  ScanInterval scanInterval = ScanInterval.disabled,
}) {
  return (
    libraryId: id,
    kind: kind,
    rootPath: rootPath,
    name: name,
    enabledResourceFormatCategories: const <ResourceFormatCategory>[],
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: scanInterval,
    pinned: false,
    sidebarOrder: 0,
  );
}

void main() {
  test('空 stats 时漫画 / 系列数回落 0 且无健康提示', () {
    final List<HomeLibraryDashboardRow> rows = buildHomeLibraryDashboardRows(
      libraries: <LocalLibrary>[_library(id: 'a', name: '库 A')],
      stats: const <HomeLibraryStat>[],
      now: _now,
    );

    expect(rows, hasLength(1));
    expect(rows.single.comicCount, 0);
    expect(rows.single.seriesCount, 0);
    expect(rows.single.hint, HomeLibraryRowHint.none);
    expect(rows.single.displayName, '库 A');
  });

  test('stats 缺项时该库漫画数回落 0，有统计的库取实际值', () {
    final List<HomeLibraryDashboardRow> rows = buildHomeLibraryDashboardRows(
      libraries: <LocalLibrary>[
        _library(id: 'a'),
        _library(id: 'b'),
      ],
      stats: const <HomeLibraryStat>[
        HomeLibraryStat(libraryId: 'b', comicCount: 7, seriesCount: 3),
      ],
      now: _now,
    );

    expect(rows[0].comicCount, 0);
    expect(rows[1].comicCount, 7);
    expect(rows[1].seriesCount, 3);
  });

  test('远程库标记为 remote', () {
    final List<HomeLibraryDashboardRow> rows = buildHomeLibraryDashboardRows(
      libraries: <LocalLibrary>[_library(id: 'r', kind: 'remote')],
      stats: const <HomeLibraryStat>[
        HomeLibraryStat(libraryId: 'r', comicCount: 1, seriesCount: 0),
      ],
      now: _now,
    );

    expect(rows.single.kind, HomeLibraryKind.remote);
  });

  test('无上次成功同步但有漫画时给出 syncWarning 且 staleDays 为空', () {
    final List<HomeLibraryDashboardRow> rows = buildHomeLibraryDashboardRows(
      libraries: <LocalLibrary>[
        _library(id: 'a', scanInterval: ScanInterval.daily),
      ],
      stats: const <HomeLibraryStat>[
        HomeLibraryStat(libraryId: 'a', comicCount: 4, seriesCount: 1),
      ],
      now: _now,
    );

    expect(rows.single.lastSyncedAt, isNull);
    expect(rows.single.hint, HomeLibraryRowHint.syncWarning);
    expect(rows.single.staleDays, isNull);
  });

  test('扫描中与元数据刷新进度只作用于匹配库', () {
    final List<HomeLibraryDashboardRow> rows = buildHomeLibraryDashboardRows(
      libraries: <LocalLibrary>[
        _library(id: 'a'),
        _library(id: 'b'),
      ],
      stats: const <HomeLibraryStat>[],
      now: _now,
      scanInProgress: true,
      metadataRefreshLibraryId: 'b',
    );

    expect(rows[0].scanInProgress, isTrue);
    expect(rows[0].metadataRefreshInProgress, isFalse);
    expect(rows[1].metadataRefreshInProgress, isTrue);
    expect(rows[1].busy, isTrue);
  });
}
