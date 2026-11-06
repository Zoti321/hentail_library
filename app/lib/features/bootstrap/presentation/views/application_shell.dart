import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/read_session/public.dart';
import 'package:hentai_library/shared/di/app_shell_providers.dart';
import 'package:hentai_library/shared/ui/shell/responsive_app_shell.dart';

export 'package:hentai_library/shared/ui/shell/responsive_app_shell.dart'
    show
        ResponsiveAppShell,
        AppShellSidebarBuilder,
        AppShellSidebarSlot,
        AppShellNavigationSlot,
        AppShellNavigationSlotBuilder,
        openAppShellNavigationDrawer,
        appShellDesktopShellKey;

/// Composition root: binds app preferences, navigation, and feature shell slots.
class ApplicationShell extends ConsumerWidget {
  const ApplicationShell({super.key, required this.routeChild});

  final Widget routeChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSidebarExpandedPref = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> asyncValue) =>
            asyncValue.asData?.value.desktopSidebarExpanded ?? true,
      ),
    );
    final bool readerFullscreen = ref.watch(readerFullscreenControllerProvider);
    final AppShellFeedbackBelowTitleBarFactory feedbackFactory = ref.watch(
      appShellFeedbackBelowTitleBarFactoryProvider,
    );
    final AppShellNavigationSlotAssembly navigationAssembly = ref.watch(
      appShellNavigationSlotAssemblyProvider,
    );

    return ResponsiveAppShell(
      routeChild: routeChild,
      isDesktopSidebarExpanded: isSidebarExpandedPref,
      onToggleDesktopSidebarExpanded: () {
        ref
            .read(settingsProvider.notifier)
            .setDesktopSidebarExpanded(!isSidebarExpandedPref);
      },
      isReaderFullscreen: readerFullscreen,
      shellFeedbackBelowTitleBar: feedbackFactory(),
      navigationSlotBuilder: (BuildContext ctx) =>
          navigationAssembly(ctx, ref),
    );
  }
}
