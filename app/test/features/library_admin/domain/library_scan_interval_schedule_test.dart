import 'package:hentai_library/features/library_admin/domain/library_scan_interval_schedule.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:test/test.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1);
  final hourly = _library('a', ScanInterval.hourly);

  for (final initiallyDisabled in [false, true]) {
    test(
      'new or enabled intervals anchor at reconciliation: disabled=$initiallyDisabled',
      () {
        final schedule = LibraryScanIntervalSchedule();
        schedule.reconcile(
          initiallyDisabled ? [_library('a', ScanInterval.disabled)] : [],
          now: start,
        );
        final enabledAt = start.add(const Duration(hours: 4));
        schedule.reconcile([hourly], now: enabledAt);
        expect(
          schedule.dueLibraries([
            hourly,
          ], now: enabledAt.add(const Duration(minutes: 59))),
          isEmpty,
        );
        expect(
          schedule.dueLibraries([
            hourly,
          ], now: enabledAt.add(const Duration(hours: 1))),
          [hourly],
        );
      },
    );
  }

  test(
    'reconciling the same interval preserves its anchor across other changes',
    () {
      final schedule = LibraryScanIntervalSchedule()
        ..reconcile([hourly], now: start);
      final renamed = _library('a', ScanInterval.hourly, name: 'Renamed');
      schedule.reconcile([
        renamed,
      ], now: start.add(const Duration(minutes: 45)));
      expect(
        schedule.dueLibraries([
          renamed,
        ], now: start.add(const Duration(minutes: 59))),
        isEmpty,
      );
      expect(
        schedule.dueLibraries([
          renamed,
        ], now: start.add(const Duration(hours: 1))),
        [renamed],
      );
    },
  );

  test('changing an interval resets its anchor', () {
    final schedule = LibraryScanIntervalSchedule()
      ..reconcile([hourly], now: start);
    final changed = _library('a', ScanInterval.every6Hours);
    schedule.reconcile([changed], now: start.add(const Duration(hours: 1)));
    expect(
      schedule.dueLibraries([
        changed,
      ], now: start.add(const Duration(hours: 6, minutes: 59))),
      isEmpty,
    );
    expect(
      schedule.dueLibraries([
        changed,
      ], now: start.add(const Duration(hours: 7))),
      [changed],
    );
  });

  test(
    'disabling removes the anchor even when an older snapshot is queried',
    () {
      final schedule = LibraryScanIntervalSchedule()
        ..reconcile([hourly], now: start);
      final disabled = _library('a', ScanInterval.disabled);
      schedule.reconcile([
        disabled,
      ], now: start.add(const Duration(minutes: 30)));
      expect(
        schedule.dueLibraries([
          hourly,
          disabled,
        ], now: start.add(const Duration(days: 1))),
        isEmpty,
      );
      final enabledAt = start.add(const Duration(days: 1));
      schedule.reconcile([hourly], now: enabledAt);
      expect(
        schedule.dueLibraries([
          hourly,
        ], now: enabledAt.add(const Duration(minutes: 59))),
        isEmpty,
      );
      expect(
        schedule.dueLibraries([
          hourly,
        ], now: enabledAt.add(const Duration(hours: 1))),
        [hourly],
      );
    },
  );

  test(
    'deleting a library clears its schedule and readding starts a new interval',
    () {
      final schedule = LibraryScanIntervalSchedule()
        ..reconcile([hourly], now: start);
      schedule.reconcile([], now: start.add(const Duration(minutes: 30)));
      expect(
        schedule.dueLibraries([
          hourly,
        ], now: start.add(const Duration(days: 1))),
        isEmpty,
      );
      final addedAt = start.add(const Duration(days: 2));
      schedule.reconcile([hourly], now: addedAt);
      expect(
        schedule.dueLibraries([
          hourly,
        ], now: addedAt.add(const Duration(minutes: 59))),
        isEmpty,
      );
      expect(
        schedule.dueLibraries([
          hourly,
        ], now: addedAt.add(const Duration(hours: 1))),
        [hourly],
      );
    },
  );

  test(
    'due results preserve query snapshots and order without advancing anchors',
    () {
      final second = _library('b', ScanInterval.hourly);
      final daily = _library('c', ScanInterval.daily);
      final disabled = _library('d', ScanInterval.disabled);
      final schedule = LibraryScanIntervalSchedule()
        ..reconcile([hourly, second, daily, disabled], now: start);
      final latestSecond = _library('b', ScanInterval.hourly, name: 'Latest B');
      final query = [
        latestSecond,
        daily,
        disabled,
        hourly,
        _library('unknown', ScanInterval.hourly),
      ];
      final now = start.add(const Duration(hours: 1));
      expect(schedule.dueLibraries(query, now: now), [latestSecond, hourly]);
      expect(schedule.dueLibraries(query, now: now), [latestSecond, hourly]);
    },
  );

  test(
    'advance moves one period from the anchor rather than from tick time',
    () {
      final schedule = LibraryScanIntervalSchedule()
        ..reconcile([hourly], now: start);
      schedule.advance(
        hourly,
        fallbackAnchor: start.add(const Duration(hours: 3, minutes: 30)),
      );
      expect(
        schedule.dueLibraries([
          hourly,
        ], now: start.add(const Duration(hours: 1, minutes: 59))),
        isEmpty,
      );
      expect(
        schedule.dueLibraries([
          hourly,
        ], now: start.add(const Duration(hours: 2))),
        [hourly],
      );
    },
  );

  test('advance uses the latest reconciled anchor with the pending snapshot period', () {
    final schedule = LibraryScanIntervalSchedule()
      ..reconcile([hourly], now: start);
    final tickAt = start.add(const Duration(hours: 1));
    final pending = schedule.dueLibraries([hourly], now: tickAt).single;
    final daily = _library('a', ScanInterval.daily);
    schedule.reconcile([daily], now: start.add(const Duration(hours: 2)));
    schedule.advance(pending, fallbackAnchor: tickAt);
    expect(
      schedule.dueLibraries([
        daily,
      ], now: start.add(const Duration(hours: 26, minutes: 59))),
      isEmpty,
    );
    expect(
      schedule.dueLibraries([daily], now: start.add(const Duration(hours: 27))),
      [daily],
    );
  });

  test('advance falls back when the original library anchor is absent', () {
    final schedule = LibraryScanIntervalSchedule()
      ..reconcile([hourly], now: start);
    schedule.reconcile([], now: start.add(const Duration(hours: 2)));
    final fallback = start.add(const Duration(hours: 5));
    schedule.advance(hourly, fallbackAnchor: fallback);
    expect(
      schedule.dueLibraries([
        hourly,
      ], now: fallback.add(const Duration(hours: 1, minutes: 59))),
      isEmpty,
    );
    expect(
      schedule.dueLibraries([
        hourly,
      ], now: fallback.add(const Duration(hours: 2))),
      [hourly],
    );
  });

  test('a disabled snapshot advances directly to fallback rather than using the current anchor', () {
    final schedule = LibraryScanIntervalSchedule()
      ..reconcile([hourly], now: start);
    final fallback = start.add(const Duration(hours: 5));
    schedule.advance(
      _library('a', ScanInterval.disabled),
      fallbackAnchor: fallback,
    );
    expect(
      schedule.dueLibraries([
        hourly,
      ], now: fallback.add(const Duration(minutes: 59))),
      isEmpty,
    );
    expect(
      schedule.dueLibraries([
        hourly,
      ], now: fallback.add(const Duration(hours: 1))),
      [hourly],
    );
  });
}

LocalLibrary _library(
  String id,
  ScanInterval interval, {
  String name = 'Library',
}) => (
  libraryId: id,
  kind: 'local',
  catalogKind: 'comic',
  rootPath: '/$id',
  name: name,
  enabledResourceFormatCategories: const [],
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: interval,
  pinned: true,
  sidebarOrder: 0,
);
