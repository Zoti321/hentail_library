typedef RecordReadSessionActivityCommand = Future<void> Function({
  required String comicId,
  required bool incognito,
  required Duration foregroundElapsed,
  required int pageIndex,
  required int pageCount,
});
