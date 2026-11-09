import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/data_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/event_bus_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:riverpod/misc.dart' show Override;

/// 应用唯一 DI 组合根：data → shared state → shell/composition。
///
/// 顺序与历史拼接一致；后段（composition / shell）依赖前段已注册的实现。
/// `main.dart` 与测试应只经此入口组装 override，避免多处拼接产生漂移。
List<Override> bootstrapDiOverrides() => <Override>[
  ...dataProviderOverrides(),
  ...eventBusOverrides(),
  ...sharedLibraryStateOverrides(),
  ...bootstrapCompositionOverrides(),
];
