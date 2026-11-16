/// Finished comic 标记规则（主测缝）。
///
/// 无痕忽略；`pageCount > 0 && pageIndex >= pageCount` 时首次达末页应标记。
abstract final class FinishedComicPolicyDomainService {
  FinishedComicPolicyDomainService._();

  static bool shouldMarkFinished({
    required bool incognito,
    required int pageIndex,
    required int pageCount,
  }) {
    if (incognito) {
      return false;
    }
    if (pageCount <= 0) {
      return false;
    }
    return pageIndex >= pageCount;
  }
}
