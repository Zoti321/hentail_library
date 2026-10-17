import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/di/shared_state_ports.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_throttle_busy.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_series_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// bootstrap 组装：把 library_admin 的实现注入 shared/di 声明的状态与端口 Provider（#261a）。
///
/// 位于 bootstrap（组合根），因此允许同时依赖 shared 与 library_admin。
List<Override> sharedLibraryStateOverrides() => <Override>[
  currentLibraryPortProvider.overrideWith(createCurrentLibraryPort),
  libraryReorderModePortProvider.overrideWith(createLibraryReorderModePort),
  libraryRevisionSignalPortProvider.overrideWith(
    createLibraryRevisionSignalPort,
  ),
  currentLibraryStateProvider.overrideWith(
    (Ref ref) => ref.watch(currentLibraryProvider),
  ),
  libraryRevisionStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryRevisionProvider),
  ),
  libraryRevisionThrottleBusyStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryRevisionThrottleBusyProvider),
  ),
  seriesByIdStateProvider.overrideWith(
    (Ref ref, String seriesId) => ref.watch(seriesByIdProvider(seriesId).future),
  ),
];
