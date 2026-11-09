/// 跨 feature 领域事件（ADR-0039）。
///
/// 全应用唯一事件词汇表：`DomainEvent` 为 sealed，全部子类必须定义在
/// `shared/domain/events/` 内（本文件或 part），由 Gate
/// `domain_event_rules_test` 静态校验。
library;

part 'catalog_events.dart';

/// 只表达「已经发生的事实」：不可变、无行为、无 Flutter 类型、不持久化。
///
/// 需要返回值或可能失败的模块协作仍走 `shared/domain/ports/**` 命令端口。
sealed class DomainEvent {
  const DomainEvent();
}
