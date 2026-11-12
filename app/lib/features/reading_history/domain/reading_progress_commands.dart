typedef RecordReadingProgressCommand = Future<void> Function({
  required String comicId,
  required String title,
  required DateTime lastReadTime,
  required int pageIndex,
});
typedef ReadResumePageQuery = Future<int?> Function(String comicId);
