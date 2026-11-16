import 'package:hentai_library/features/library_admin/domain/library_scan_domain_service.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';

class LibraryScanIntervalSchedule {
  static const _scheduler = LibraryScanDomainService();

  final Map<String, DateTime> _anchors = {};
  final Map<String, ScanInterval> _lastIntervals = {};

  void reconcile(Iterable<LocalLibrary> libraries, {required DateTime now}) {
    final snapshot = libraries.toList(growable: false);
    final alive = snapshot.map((library) => library.libraryId).toSet();
    _anchors.removeWhere((id, _) => !alive.contains(id));
    _lastIntervals.removeWhere((id, _) => !alive.contains(id));
    for (final library in snapshot) {
      final id = library.libraryId;
      final previous = _lastIntervals[id] ?? ScanInterval.disabled;
      _lastIntervals[id] = library.scanInterval;
      if (library.scanInterval == ScanInterval.disabled) {
        _anchors.remove(id);
      } else if (previous != library.scanInterval ||
          !_anchors.containsKey(id)) {
        _anchors[id] = now;
      }
    }
  }

  List<LocalLibrary> dueLibraries(
    Iterable<LocalLibrary> libraries, {
    required DateTime now,
  }) {
    final snapshot = libraries.toList(growable: false);
    final due = _scheduler
        .libraryIdsDueForInterval(
          libraries: snapshot,
          intervalAnchors: _anchors,
          now: now,
        )
        .toSet();
    return snapshot
        .where((library) => due.contains(library.libraryId))
        .toList(growable: false);
  }

  void advance(LocalLibrary library, {required DateTime fallbackAnchor}) {
    final period = library.scanInterval.period;
    final anchor = _anchors[library.libraryId] ?? fallbackAnchor;
    // The request's snapshot keeps its period; reconciliation may have reset its anchor while waiting.
    _anchors[library.libraryId] = period == null
        ? fallbackAnchor
        : anchor.add(period);
  }
}
