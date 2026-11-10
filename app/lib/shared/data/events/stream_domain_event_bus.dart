import 'dart:async';

import 'package:hentai_library/shared/domain/events/events.dart';

/// 原生 `StreamController` 实现（ADR-0039）：全应用唯一 [DomainEventBus] 实现。
///
/// `sync: true` 保证「发布 → 订阅方收到」顺序确定。订阅方须先订阅
/// （应用由 `DomainEventRevisions` 在启动时建立），广播流不重放。
final class StreamDomainEventBus implements DomainEventBus {
  final StreamController<DomainEvent> _controller =
      StreamController<DomainEvent>.broadcast(sync: true);

  @override
  Stream<T> on<T extends DomainEvent>() =>
      _controller.stream.where((DomainEvent event) => event is T).cast<T>();

  @override
  void publish(DomainEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}
