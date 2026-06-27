import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';

typedef LibraryViewSettings = ({
  bool isHealthyMode,
  bool hideComicsInSeries,
});

final Provider<LibraryViewSettings> libraryViewSettingsProvider =
    Provider<LibraryViewSettings>((Ref ref) {
      final AsyncValue<AppSetting> async = ref.watch(settingsProvider);
      return (
        isHealthyMode: async.asData?.value.isHealthyMode ?? false,
        hideComicsInSeries:
            async.asData?.value.libraryHideComicsInSeries ?? false,
      );
    });
