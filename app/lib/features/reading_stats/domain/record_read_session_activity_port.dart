/// Read session → reading_stats 活动入账写口。
///
/// Token：[recordReadSessionActivityPortProvider]。
abstract class RecordReadSessionActivityPort {
  Future<void> record({
    required String comicId,
    required bool incognito,
    required Duration foregroundElapsed,
    required int pageIndex,
    required int pageCount,
  });
}
