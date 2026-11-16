/// 阅读器导航意图：由 ViewModel / SeriesNavigation 产出，View 执行 go_router。
sealed class ReaderNavigationIntent {
  const ReaderNavigationIntent();
}

/// `pushReplacement` 到新阅读路由（系列切卷）。
final class ReaderReplaceReaderRouteIntent extends ReaderNavigationIntent {
  const ReaderReplaceReaderRouteIntent(this.location);

  final String location;
}

/// 退出阅读器：`pop` 或 `go` 到详情。
sealed class ReaderExitIntent {
  const ReaderExitIntent();
}

final class ReaderExitPopIntent extends ReaderExitIntent {
  const ReaderExitPopIntent();
}

final class ReaderExitGoIntent extends ReaderExitIntent {
  const ReaderExitGoIntent(this.location);

  final String location;
}
