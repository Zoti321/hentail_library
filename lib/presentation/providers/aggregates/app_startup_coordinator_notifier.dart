import 'package:flutter/widgets.dart';
import 'package:hentai_library/domain/entity/entities.dart' show AppSetting;
import 'package:hentai_library/presentation/providers/aggregates/comic_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:hentai_library/presentation/providers/usecases/scan_library_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_coordinator_notifier.g.dart';

@Riverpod(keepAlive: true)
class AppStartupCoordinatorNotifier extends _$AppStartupCoordinatorNotifier {
  bool _didHandleStartupAutoScanPreference = false;

  @override
  bool build() {
    ref.listen<AsyncValue<AppSetting>>(settingsProvider, (
      AsyncValue<AppSetting>? previous,
      AsyncValue<AppSetting> next,
    ) {
      if (_didHandleStartupAutoScanPreference) return;
      next.whenData((AppSetting setting) {
        _didHandleStartupAutoScanPreference = true;
        if (!setting.autoScan) return;
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          ref.read(scanLibraryControllerProvider.notifier).start();
        });
      });
    });
    ref.listen(scanLibraryControllerProvider, (
      ScanLibraryState? previous,
      ScanLibraryState next,
    ) {
      final bool wasRunning = previous?.running ?? false;
      if (!wasRunning || next.running) return;
      if (next.cancelled) return;
      if (next.error != null) return;
      ref.read(comicAggregateProvider.notifier).refreshStream();
      ref.read(seriesAggregateProvider.notifier).refreshAllSeries();
    });
    return true;
  }
}
