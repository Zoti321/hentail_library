import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/data/events/event_bus_adapter.dart';
import 'package:hentai_library/shared/di/event_bus_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// 领域事件总线（ADR-0039）：全应用唯一实例，随容器释放。
List<Override> eventBusOverrides() => <Override>[
  appEventBusProvider.overrideWith((Ref ref) {
    final EventBusDomainEventBus bus = EventBusDomainEventBus();
    ref.onDispose(bus.dispose);
    return bus;
  }),
];
