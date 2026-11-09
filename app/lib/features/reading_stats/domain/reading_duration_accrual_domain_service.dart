/// Reading duration 入账规则（主测缝）。
///
/// 无痕 → 不入账；有效前台时长 &lt; 10s → 不入账；≥10s → 入账**整段**（含前 10s）。
abstract final class ReadingDurationAccrualDomainService {
  ReadingDurationAccrualDomainService._();

  static const Duration minimumQualifyingForeground = Duration(seconds: 10);

  /// 返回应累加的时长；`null` 表示本会话不入账。
  static Duration? accruedDuration({
    required bool incognito,
    required Duration foregroundElapsed,
  }) {
    if (incognito) {
      return null;
    }
    if (foregroundElapsed < minimumQualifyingForeground) {
      return null;
    }
    return foregroundElapsed;
  }
}
