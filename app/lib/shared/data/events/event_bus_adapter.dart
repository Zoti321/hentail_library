import 'package:event_bus/event_bus.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

/// `event_bus` 包适配（ADR-0039）：全应用唯一 [DomainEventBus] 实现。
///
/// `sync: true` 保证「发布 → 订阅方收到」顺序确定。订阅方须先订阅
/// （应用由 [DomainEventRevisions] 在启动时建立），广播流不重放。
final class EventBusDomainEventBus implements DomainEventBus {
  EventBusDomainEventBus({bool sync = true}) : _bus = EventBus(sync: sync);

  final EventBus _bus;

  @override
  Stream<T> on<T extends DomainEvent>() => _bus.on<T>();

  @override
  void publish(DomainEvent event) => _bus.fire(event);

  void dispose() => _bus.destroy();
}
