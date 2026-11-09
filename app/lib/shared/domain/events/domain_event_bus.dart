import 'package:hentai_library/shared/domain/events/domain_event.dart';
import 'package:hentai_library/shared/domain/events/domain_event_publisher.dart';

/// 订阅侧契约（ADR-0039）：`shared/di` 的 token 类型，避免 DI 依赖实现层。
abstract class DomainEventBus implements DomainEventPublisher {
  /// 按事件类型过滤的广播流；不重放，订阅方须在发布前订阅。
  Stream<T> on<T extends DomainEvent>();
}
