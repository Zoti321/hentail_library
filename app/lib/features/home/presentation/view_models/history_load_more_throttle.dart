/// Minimum interval between History scroll-driven `loadMore` attempts (P2-6).
const Duration kHistoryLoadMoreMinInterval = Duration(milliseconds: 300);

/// Returns true when [now] is far enough from [lastAttemptAt] to allow another
/// `loadMore` call. A null [lastAttemptAt] always allows.
bool shouldAttemptHistoryLoadMore({
  required DateTime? lastAttemptAt,
  required DateTime now,
  Duration minInterval = kHistoryLoadMoreMinInterval,
}) {
  if (lastAttemptAt == null) {
    return true;
  }
  return now.difference(lastAttemptAt) >= minInterval;
}
