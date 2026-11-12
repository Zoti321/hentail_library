import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

/// 进程内领域事件总线（ADR-0039）：实现由 bootstrap 注入，全应用唯一实例。
///
/// 消费者只读本 token；application 层通过构造参数接收 [DomainEventPublisher]。
final Provider<DomainEventBus> domainEventBusProvider = requiredProvider(
  'domainEventBusProvider',
);
