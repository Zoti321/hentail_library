/// Image set 库手动同步的终态。失败与警告都不意味着已回滚已提交的目录。
sealed class ImageSetSyncOutcome {
  const ImageSetSyncOutcome();
}

final class ImageSetSyncSucceeded extends ImageSetSyncOutcome {
  const ImageSetSyncSucceeded({
    required this.addedCount,
    required this.removedCount,
  });

  final int addedCount;
  final int removedCount;
}

/// 同步已提交，但存在不完整载体等需要关注的内容。
final class ImageSetSyncWarned extends ImageSetSyncOutcome {
  const ImageSetSyncWarned({
    required this.message,
    required this.addedCount,
    required this.removedCount,
  });

  final String message;
  final int addedCount;
  final int removedCount;
}

final class ImageSetSyncFailed extends ImageSetSyncOutcome {
  const ImageSetSyncFailed({required this.message});

  final String message;
}

final class ImageSetSyncCancelled extends ImageSetSyncOutcome {
  const ImageSetSyncCancelled();
}
