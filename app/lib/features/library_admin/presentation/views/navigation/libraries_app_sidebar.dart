import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/app_navigation.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/libraries_sidebar_section.dart';
import 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/desktop_sidebar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// App navigation sidebar: main/system destinations + Libraries partition.
class LibrariesAppSidebar extends HookConsumerWidget {
  const LibrariesAppSidebar({
    super.key,
    required this.slot,
    this.librariesReorderPaneBuilder,
  });

  final AppShellSidebarSlot slot;
  final WidgetBuilder? librariesReorderPaneBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      if (!slot.isExpanded || !slot.allowLibraryReorder) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(libraryReorderModeProvider.notifier).exit();
        });
      }
      return null;
    }, <Object?>[slot.isExpanded, slot.allowLibraryReorder]);

    final bool reorderMode = ref.watch(libraryReorderModeProvider);
    final l10n = context.l10n;

    return DesktopSidebar(
      activeId: slot.activeNavId,
      isExpanded: slot.isExpanded,
      showCollapseToggle: slot.showCollapseToggle,
      applyDrawerTopInset: slot.applyDrawerTopInset,
      onToggleExpanded: slot.onToggleExpanded,
      onDestinationSelected: slot.onDestinationSelected,
      allowLibraryReorder: slot.allowLibraryReorder,
      librariesReorderPaneBuilder: librariesReorderPaneBuilder,
      librariesSectionBuilder:
          ({
            required double expandProgress,
            required double labelOpacity,
            required bool showCollapsedTooltip,
          }) => LibrariesSidebarSection(
            expandProgress: expandProgress,
            labelOpacity: labelOpacity,
            showCollapsedTooltip: showCollapsedTooltip,
            allowLibraryReorder: slot.allowLibraryReorder,
            onNavigate: slot.onLibrariesNavigate,
          ),
      mainNavItems: AppNavigation.desktopMainNavItems(l10n),
      systemNavItems: AppNavigation.desktopSystemNavItems(l10n),
      librariesAnchorNavId: AppNavigation.navIdHome,
      reorderMode: reorderMode,
    );
  }
}
