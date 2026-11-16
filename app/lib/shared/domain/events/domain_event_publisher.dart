import 'package:hentai_library/shared/domain/events/domain_event.dart';

/// 事件发布端口（ADR-0039）。
///
/// application 层只依赖此接口，由 bootstrap 注入唯一实现；
/// 发布必须在写入成功提交之后，不得在事务 / FRB 调用内部发布。
abstract class DomainEventPublisher {
  void publish(DomainEvent event);
}
