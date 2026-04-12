import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/app_theme_mode.dart';
import 'package:hentai_library/domain/entity/entities.dart' show AppSetting;
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/routes/routes.dart';

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
  bool _didHandleStartupAutoScanPreference = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppSetting>>(settingsProvider, (prev, next) {
      if (_didHandleStartupAutoScanPreference) return;
      next.whenData((AppSetting s) {
        _didHandleStartupAutoScanPreference = true;
        if (!s.autoScan) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(scanLibraryControllerProvider.notifier).start();
        });
      });
    });

    ref.listen(scanLibraryControllerProvider, (prev, next) {
      final bool wasRunning = prev?.running ?? false;
      if (!wasRunning || next.running) return;
      if (next.cancelled) return;
      if (next.error != null) return;
      ref.read(libraryPageProvider.notifier).refreshStream();
    });

    final AsyncValue<AppSetting> settingsAsync = ref.watch(settingsProvider);
    final ThemeMode themeMode = settingsAsync.maybeWhen(
      data: (AppSetting data) => themeModeFromPreference(data.themePreference),
      orElse: () => ThemeMode.system,
    );

    return MaterialApp.router(
      locale: const Locale('zh', 'CN'),
      title: 'hentai library',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
