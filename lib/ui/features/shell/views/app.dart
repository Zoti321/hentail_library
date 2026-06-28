import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/core/util/app_theme_mode.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/features/settings/settings.dart';
import 'package:hentai_library/ui/features/shell/state/app_startup_coordinator_notifier.dart';
import 'package:hentai_library/ui/core/theme/mobile_material_theme.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppRoot());
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

    return MaterialApp.router(
      locale: const Locale('zh', 'CN'),
      title: 'hentai library',
      debugShowCheckedModeBanner: false,
      theme: isDesktop
          ? buildAppTheme(Brightness.light)
          : buildMobileMaterialTheme(Brightness.light),
      darkTheme: isDesktop
          ? buildAppTheme(Brightness.dark)
          : buildMobileMaterialTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
