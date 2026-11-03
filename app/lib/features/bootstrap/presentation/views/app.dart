import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/util/app_locale.dart';
import 'package:hentai_library/core/util/app_theme_mode.dart';
import 'package:hentai_library/core/util/app_window_title.dart';
import 'package:hentai_library/shared/domain/models/models.dart'
    show AppSetting;
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/metadata_backup/public.dart';
import 'package:hentai_library/features/bootstrap/presentation/view_models/app_startup_coordinator_notifier.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:riverpod/misc.dart' show Override;

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.overrides = const <Override>[]});

  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(overrides: overrides, child: const _AppRoot());
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  @override
  Widget build(BuildContext context) {
    ref.watch(appStartupCoordinatorProvider);
    ref.watch(metadataAutoBackupCoordinatorProvider);
    ref.watch(appUpdateCoordinatorProvider);

    final AppThemePreferencesPort themePrefs = ref.watch(
      appThemePreferencesPortProvider,
    );
    final ThemeMode themeMode = themeModeFromPreference(
      themePrefs.themePreference,
    );
    final Locale? locale = ref.watch(
      settingsProvider.select((AsyncValue<AppSetting> async) {
        final AsyncData<AppSetting>? data = async.asData;
        if (data == null) {
          return null;
        }
        return localeFromPreference(data.value.localePreference);
      }),
    );

    return MaterialApp.router(
      locale: locale,
      // Prefer zh as first entry so unmatched device locales fall back to Chinese.
      supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: appWindowTitle(),
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        Brightness.light,
        colorSchemeId: _colorSchemeId(themePrefs.colorSchemePreference),
        useDynamicColor: themePrefs.useDynamicColor,
      ),
      darkTheme: buildAppTheme(
        Brightness.dark,
        colorSchemeId: _colorSchemeId(themePrefs.colorSchemePreference),
        useDynamicColor: themePrefs.useDynamicColor,
      ),
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (BuildContext context, Widget? child) {
        final Brightness brightness = Theme.of(context).brightness;
        final M3EThemeData m3e = buildAppM3eThemeData(brightness);
        return M3ETheme(
          data: m3e,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: appSystemUiOverlayStyle(Theme.of(context).colorScheme),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

String _colorSchemeId(AppColorSchemePreference preference) {
  switch (preference) {
    case AppColorSchemePreference.brand:
      return 'brand';
  }
}
