import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// 测试桥接：`appSettingsStateProvider`（shared token）→ owner `settingsProvider`。
///
/// 生产环境由 `features/bootstrap/di/overrides/app_settings_trash_shared_state_overrides.dart`
/// 建立同一条边；library_browse 侧已改为只读 shared token（ADR-0034），
/// 因此测试必须显式补这条边，否则 token 抛 `UnimplementedError`。
Override settingsStateBridge() => appSettingsStateProvider.overrideWith(
  (Ref ref) => ref.watch(settingsProvider),
);
