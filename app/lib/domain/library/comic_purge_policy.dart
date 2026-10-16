import 'package:hentai_library/domain/models/read_models/trashed_comic.dart';

/// Comic purge 目标中 Local / Remote 的数量（决定确认文案与勾选闸门）。
typedef PurgeTargetCounts = ({int local, int remote});

PurgeTargetCounts countPurgeTargets(Iterable<TrashedComic> items) {
  int local = 0;
  int remote = 0;
  for (final TrashedComic item in items) {
    if (item.isRemote) {
      remote++;
    } else {
      local++;
    }
  }
  return (local: local, remote: remote);
}

/// Comic purge 确认框文案分支。
enum PurgeConfirmCopy {
  singleLocal,
  singleRemote,
  batchLocal,
  batchRemote,
  mixed,
}

PurgeConfirmCopy purgeConfirmCopyFor(PurgeTargetCounts counts) {
  final int total = counts.local + counts.remote;
  if (counts.local > 0 && counts.remote > 0) {
    return PurgeConfirmCopy.mixed;
  }
  if (counts.remote > 0) {
    return total == 1
        ? PurgeConfirmCopy.singleRemote
        : PurgeConfirmCopy.batchRemote;
  }
  return total == 1
      ? PurgeConfirmCopy.singleLocal
      : PurgeConfirmCopy.batchLocal;
}

/// Comic purge 一律需要勾选闸门（ADR-0023）；Local / Remote 文案由对话框分支。
bool purgeRequiresAcknowledgement(PurgeTargetCounts counts) =>
    counts.local + counts.remote > 0;

/// Comic purge 结果汇总 toast 分支。
enum PurgeSummaryKind { nothing, allSucceeded, partial, allFailed }

PurgeSummaryKind purgeSummaryKindFor(ComicPurgeResult result) {
  if (result.succeeded <= 0 && result.failed <= 0) {
    return PurgeSummaryKind.nothing;
  }
  if (result.failed <= 0) {
    return PurgeSummaryKind.allSucceeded;
  }
  if (result.succeeded <= 0) {
    return PurgeSummaryKind.allFailed;
  }
  return PurgeSummaryKind.partial;
}
