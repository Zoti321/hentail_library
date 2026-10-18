import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/desktop_sidebar.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/library_management_actions.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/library_sidebar_overflow_actions.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/metadata_refresh_toasts.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'libraries_sidebar_widgets.dart';

/// Trailing action slot width — matches [GhostButton.icon] `size` on library rows.
const double _kSidebarRowTrailingSlotSize = 28;

/// Extra left inset for libraries nested under the 「更多」 expander.
const double _kLibrariesMoreChildIndent = 8;

/// Row hover: lighter than the shared sidebar token so action buttons can
/// sit on a deeper chrome without blending in.
Color _sidebarRowHoverBackground(HentaiColorScheme h) =>
    Color.lerp(h.sidebarBackground, h.sidebarItemHoverBackground, 0.55)!;

/// Trailing +/-/⋯ button hover: darker than the row hover for contrast.
Color _sidebarActionHoverBackground(HentaiColorScheme h) =>
    Color.lerp(h.sidebarItemHoverBackground, h.borderStrong, 0.5)!;

/// Komga-style Libraries section for the desktop sidebar (injected by shell).
class LibrariesSidebarSection extends HookConsumerWidget {
  const LibrariesSidebarSection({
    super.key,
    required this.expandProgress,
    required this.labelOpacity,
    required this.showCollapsedTooltip,
    this.allowLibraryReorder = true,
    this.onNavigate,
  });

  final double expandProgress;
  final double labelOpacity;
  final bool showCollapsedTooltip;
  final bool allowLibraryReorder;

  /// Called before route changes (e.g. close the compact navigation drawer).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CurrentLibraryState? state = ref
        .watch(currentLibraryProvider)
        .asData
        ?.value;
    final List<LocalLibrary> libraries =
        state?.libraries ?? const <LocalLibrary>[];
    final String path = GoRouterState.of(context).uri.path;
    final LibrariesSidebarSelection selection = librariesSidebarSelection(
      path: path,
      currentLibraryId: state?.currentId,
    );
    final bool collapsed = expandProgress < 0.05;
    final LibrarySidebarSections sections = splitLibrarySidebar(libraries);
    final String? currentId = state?.currentId;
    final bool currentIsUnpinned =
        currentId != null &&
        sections.unpinned.any(
          (LocalLibrary library) => library.libraryId == currentId,
        );
    final ValueNotifier<bool> moreExpanded = useState(false);
    final ObjectRef<String?> autoOpenedFor = useRef<String?>(null);
    useEffect(() {
      if (currentIsUnpinned && autoOpenedFor.value != currentId) {
        moreExpanded.value = true;
        autoOpenedFor.value = currentId;
      }
      return null;
    }, <Object?>[currentId, currentIsUnpinned]);

    if (collapsed) {
      return _CollapsedLibrariesButton(
        isActive: librariesRailIconActive(selection),
        libraries: libraries,
        showCollapsedTooltip: showCollapsedTooltip,
        onNavigate: onNavigate,
      );
    }

    final bool showMore = showLibrariesMore(sections.unpinned);
    final bool reorderEnabled =
        allowLibraryReorder && librariesReorderMenuEnabled(libraries.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LibrariesSectionHeader(
          isActive: selection.sectionActive,
          expandProgress: expandProgress,
          labelOpacity: labelOpacity,
          reorderEnabled: reorderEnabled,
          onTap: () {
            LibraryManagementActions.goAllLibraries(context);
            onNavigate?.call();
          },
        ),
        ...sections.pinned.map(
          (LocalLibrary library) => _LibrarySidebarRow(
            library: library,
            isActive: selection.activeLibraryId == library.libraryId,
            expandProgress: expandProgress,
            labelOpacity: labelOpacity,
            onNavigate: onNavigate,
          ),
        ),
        if (showMore)
          _LibrariesMoreRow(
            expanded: moreExpanded.value,
            expandProgress: expandProgress,
            labelOpacity: labelOpacity,
            onTap: () => moreExpanded.value = !moreExpanded.value,
          ),
        if (showMore && moreExpanded.value)
          ...sections.unpinned.map(
            (LocalLibrary library) => _LibrarySidebarRow(
              library: library,
              isActive: selection.activeLibraryId == library.libraryId,
              expandProgress: expandProgress,
              labelOpacity: labelOpacity,
              nestedUnderMore: true,
              onNavigate: onNavigate,
            ),
          ),
      ],
    );
  }
}
