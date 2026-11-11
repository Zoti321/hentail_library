/// 后台缩略图队列是否活跃（供 catalog / home 的 revision 节流消费）。
///
/// 实现由 comic 提供，token 在 `shared/di/thumbnail_activity_providers.dart`。
/// 放 shared/ports 而非 Slot：这是纯状态读口，不参与 UI 组合（ADR-0045）。
abstract class ThumbnailActivityPort {
  Stream<bool> watchBackgroundActive();
}
