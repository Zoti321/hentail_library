import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/infrastructure/events/stream_domain_event_bus.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// 领域事件总线（ADR-0039）：全应用唯一实例，随容器释放。
List<Override> domainEventBusOverrides() => <Override>[
  domainEventBusProvider.overrideWith((Ref ref) {
    final StreamDomainEventBus bus = StreamDomainEventBus();
    ref.onDispose(bus.dispose);
    return bus;
  }),
];
