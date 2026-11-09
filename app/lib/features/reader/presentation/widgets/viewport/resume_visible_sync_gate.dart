/// Gates page/spread index → currentIndex sync around programmatic resume jumps.
///
/// Scroll layout and paged PageView may briefly report a wrong index while
/// aligning after open/resume. Writing that back corrupts Reading history
/// (e.g. 54→38→25 across opens). Keep suppress until the resume target is
/// observed within ±1 (or [alignTimeout] elapses).
class ResumeVisibleSyncGate {
  ResumeVisibleSyncGate({this.alignTimeout = const Duration(seconds: 2)});

  final Duration alignTimeout;

  bool _suppressed = false;
  int? _targetOneBased;
  DateTime? _alignStartedAt;

  bool get isSuppressed => _suppressed;

  void beginProgrammaticAlign({required int targetOneBased, DateTime? now}) {
    _suppressed = true;
    _targetOneBased = targetOneBased;
    _alignStartedAt = now ?? DateTime.now();
  }

  /// Test-only: mimics the old one-frame post-jump unsuppress.
  void debugForceUnsuppress() {
    _suppressed = false;
    _targetOneBased = null;
    _alignStartedAt = null;
  }

  /// Returns the one-based page to apply, or null to ignore this visible event.
  int? onVisibleIndex(int visibleOneBased, {DateTime? now}) {
    if (!_suppressed) {
      return visibleOneBased;
    }
    final int? target = _targetOneBased;
    if (target != null && (visibleOneBased - target).abs() <= 1) {
      _suppressed = false;
      _targetOneBased = null;
      _alignStartedAt = null;
      return null;
    }
    final DateTime? started = _alignStartedAt;
    final DateTime clock = now ?? DateTime.now();
    if (started != null && clock.difference(started) >= alignTimeout) {
      _suppressed = false;
      _targetOneBased = null;
      _alignStartedAt = null;
      return visibleOneBased;
    }
    return null;
  }
}
