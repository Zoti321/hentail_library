import 'package:hentai_library/composition/composition_overrides.dart';
import 'package:hentai_library/composition/infrastructure_overrides.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';
import 'package:hentai_library/composition/feature_state_overrides.dart';
import 'package:riverpod/misc.dart' show Override;

/// 应用组合根：基础设施绑定、领域事件、模块状态桥接和应用壳。
///
/// Provider 按需求值；保留既有分组顺序，集中维护所有生产 override。
/// `main.dart` 与测试应只经此入口组装 override，避免多处拼接产生漂移。
List<Override> appProviderOverrides() => <Override>[
  ...infrastructureOverrides(),
  ...domainEventBusOverrides(),
  ...featureStateOverrides(),
  ...bootstrapCompositionOverrides(),
];
