import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_session_notifier.g.dart';

/// 当前阅读页的会话开始时间（进入阅读页时设置，退出时用于计算时长并清除）
@Riverpod(keepAlive: true)
class ReadingSessionStart extends _$ReadingSessionStart {
  @override
  DateTime? build() => null;

  void setStartedAt(DateTime? value) => state = value;
}
