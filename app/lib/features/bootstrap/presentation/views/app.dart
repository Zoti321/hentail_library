import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/util/app_window_title.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:hentai_library/features/app_settings/domain/app_font_preference.dart';
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
    // ADR-0039：在应用启动即订阅领域事件，避免发布时 reducer 尚未 build 而丢事件。
    ref.watch(domainEventRevisionsProvider);
    ref.watch(appStartupCoordinatorProvider);
    ref.watch(metadataAutoBackupCoordinatorProvider);
    ref.watch(appUpdateCoordinatorProvider);

    // 主题偏好直接从 owner 设置态读取（原 AppThemePreferencesPort 是冗余层，ADR-0046）。
    final ({
      AppThemePreference themePreference,
      AppColorSchemePreference colorSchemePreference,
      bool useDynamicColor,
      AppFontPreference fontPreference,
    })
    themePrefs = ref.watch(
      appSettingsProvider.select((AsyncValue<AppSetting> async) {
        final AppSetting? setting = async.asData?.value;
        return (
          themePreference:
              setting?.themePreference ?? AppThemePreference.system,
          colorSchemePreference:
              setting?.colorSchemePreference ?? AppColorSchemePreference.brand,
          useDynamicColor: setting?.useDynamicColor ?? false,
          fontPreference: setting?.fontPreference ?? AppFontPreference.miSans,
        );
      }),
    );
    final ThemeMode themeMode = themeModeFromPreference(
      themePrefs.themePreference,
    );
    final String colorSchemeId = colorSchemeIdForPreference(
      themePrefs.colorSchemePreference,
    );
    final AppFontSpec font = appFontSpecFor(themePrefs.fontPreference);
    final Locale? locale = ref.watch(
      settingsProvider.select((AsyncValue<AppSetting> async) {
        final AsyncData<AppSetting>? data = async.asData;
        if (data == null) {
          return null;
        }
        return localeFromPreference(data.value.localePreference);
      }),
    );

    // dynamic_color 2.x 的 ColorScheme 来自 material_ui，与 Flutter ColorScheme 不同型。
    return DynamicColorBuilder(
      builder:
          (
            material_ui.ColorScheme? lightDynamic,
            material_ui.ColorScheme? darkDynamic,
          ) => _ThemedApp(
            lightDynamic: lightDynamic,
            darkDynamic: darkDynamic,
            useDynamicColor: themePrefs.useDynamicColor,
            colorSchemeId: colorSchemeId,
            font: font,
            locale: locale,
            themeMode: themeMode,
          ),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp({
    required this.lightDynamic,
    required this.darkDynamic,
    required this.useDynamicColor,
    required this.colorSchemeId,
    required this.font,
    required this.locale,
    required this.themeMode,
  });

  final material_ui.ColorScheme? lightDynamic;
  final material_ui.ColorScheme? darkDynamic;
  final bool useDynamicColor;
  final String colorSchemeId;
  final AppFontSpec font;
  final Locale? locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final AssembledAppTheme light = assembleAppTheme(
      Brightness.light,
      seed: resolveAppThemeSeed(
        useDynamicColor: useDynamicColor,
        platformPrimary: lightDynamic?.primary,
        colorSchemeId: colorSchemeId,
      ),
      font: font,
    );
    final AssembledAppTheme dark = assembleAppTheme(
      Brightness.dark,
      seed: resolveAppThemeSeed(
        useDynamicColor: useDynamicColor,
        platformPrimary: darkDynamic?.primary,
        colorSchemeId: colorSchemeId,
      ),
      font: font,
    );
    return MaterialApp.router(
      locale: locale,
      // Prefer zh as first entry so unmatched device locales fall back to Chinese.
      supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: appWindowTitle(),
      debugShowCheckedModeBanner: false,
      theme: light.material,
      darkTheme: dark.material,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (BuildContext context, Widget? child) =>
          _AppThemeOverlay(light: light, dark: dark, child: child),
    );
  }
}

class _AppThemeOverlay extends StatelessWidget {
  const _AppThemeOverlay({required this.light, required this.dark, this.child});

  final AssembledAppTheme light;
  final AssembledAppTheme dark;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AssembledAppTheme assembled =
        Theme.of(context).brightness == Brightness.dark ? dark : light;
    return M3ETheme(
      data: assembled.m3e,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: appSystemUiOverlayStyle(Theme.of(context).colorScheme),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
