import 'package:hentai_library/domain/library/library_scan_scheduler.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:test/test.dart';

void main() {
  const LibraryScanScheduler scheduler = LibraryScanScheduler();

  LocalLibrary lib({
    required String id,
    bool scanOnStartup = false,
    ScanInterval interval = ScanInterval.disabled,
  }) {
    return (
      libraryId: id,
      kind: 'local',
      rootPath: '/$id',
      name: id,
      enabledFormatGroups: const [],
      username: '',
      allowHttp: false,
      scanOnStartup: scanOnStartup,
      scanInterval: interval,
    );
  }

  test('startup selects every library with Scan on startup', () {
    final List<String> ids = scheduler.libraryIdsForStartupScan([
      lib(id: 'a', scanOnStartup: true),
      lib(id: 'b', scanOnStartup: false),
      lib(id: 'c', scanOnStartup: true),
    ]);
    expect(ids, ['a', 'c']);
  });

  test('disabled interval never due', () {
    final DateTime now = DateTime.utc(2026, 1, 1, 12);
    final List<String> ids = scheduler.libraryIdsDueForInterval(
      libraries: [lib(id: 'a', interval: ScanInterval.disabled)],
      intervalAnchors: {'a': now.subtract(const Duration(days: 30))},
      now: now,
    );
    expect(ids, isEmpty);
  });

  test('hourly interval due after one hour from anchor', () {
    final DateTime anchor = DateTime.utc(2026, 1, 1, 10);
    final DateTime before = anchor.add(const Duration(minutes: 59));
    final DateTime after = anchor.add(const Duration(hours: 1));
    final libraries = [lib(id: 'a', interval: ScanInterval.hourly)];
    final anchors = {'a': anchor};

    expect(
      scheduler.libraryIdsDueForInterval(
        libraries: libraries,
        intervalAnchors: anchors,
        now: before,
      ),
      isEmpty,
    );
    expect(
      scheduler.libraryIdsDueForInterval(
        libraries: libraries,
        intervalAnchors: anchors,
        now: after,
      ),
      ['a'],
    );
  });

  test('changing anchor resets due calculation', () {
    final DateTime oldAnchor = DateTime.utc(2026, 1, 1, 0);
    final DateTime newAnchor = DateTime.utc(2026, 1, 1, 11);
    final DateTime now = DateTime.utc(2026, 1, 1, 11, 30);
    final libraries = [lib(id: 'a', interval: ScanInterval.hourly)];

    expect(
      scheduler.libraryIdsDueForInterval(
        libraries: libraries,
        intervalAnchors: {'a': oldAnchor},
        now: now,
      ),
      ['a'],
    );
    expect(
      scheduler.libraryIdsDueForInterval(
        libraries: libraries,
        intervalAnchors: {'a': newAnchor},
        now: now,
      ),
      isEmpty,
    );
  });
}
