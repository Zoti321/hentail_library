import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';

/// Decides which Library ids need incremental sync at startup / on an interval tick.
///
/// Pure policy — timers and FRB live outside this type so tests can inject a clock
/// and a sync starter.
class LibraryScanScheduler {
  const LibraryScanScheduler();

  List<String> libraryIdsForStartupScan(Iterable<LocalLibrary> libraries) {
    return libraries
        .where((LocalLibrary library) => library.scanOnStartup)
        .map((LocalLibrary library) => library.libraryId)
        .toList(growable: false);
  }

  /// Libraries whose Scan interval is due at [now], given per-library anchors.
  List<String> libraryIdsDueForInterval({
    required Iterable<LocalLibrary> libraries,
    required Map<String, DateTime> intervalAnchors,
    required DateTime now,
  }) {
    final List<String> due = <String>[];
    for (final LocalLibrary library in libraries) {
      final Duration? period = library.scanInterval.period;
      if (period == null) {
        continue;
      }
      final DateTime? anchor = intervalAnchors[library.libraryId];
      if (anchor == null) {
        continue;
      }
      if (!now.isBefore(anchor.add(period))) {
        due.add(library.libraryId);
      }
    }
    return due;
  }
}
