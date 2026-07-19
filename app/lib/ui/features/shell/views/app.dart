import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/util/app_locale.dart';
import 'package:hentai_library/core/util/app_theme_mode.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/settings.dart';
import 'package:hentai_library/ui/features/shell/state/app_startup_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
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
    ref.watch(appUpdateCoordinatorProvider);

    final ThemeMode themeMode = ref.watch(
      settingsProvider.select((AsyncValue<AppSetting> async) {
        final AsyncData<AppSetting>? data = async.asData;
        if (data == null) {
          return ThemeMode.system;
        }
        return themeModeFromPreference(data.value.themePreference);
      }),
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
      supportedLocales: const <Locale>[
        Locale('zh'),
        Locale('en'),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'hentai library',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
