import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/interaction/desktop_page_transition.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/comic_detail_back_location.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared back chrome for comic/series detail edge states.
class ComicDetailBackHeader extends StatelessWidget {
  const ComicDetailBackHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.hentai.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GhostButton.icon(
                icon: LucideIcons.arrowLeft,
                tooltip: l10n.shellBack,
                semanticLabel: l10n.shellBack,
                iconSize: 16,
                size: 32,
                borderRadius: 8,
                foregroundColor: cs.hentai.iconDefault,
                hoverColor: theme.hoverColor,
                overlayColor: theme.hoverColor,
                onPressed: () => ComicDetailBackHeader.popOrGoLibrary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Comic/series detail back: pop when possible; on comic detail prefer a
  /// remembered Series source; otherwise Current library browse.
  static void popOrGoLibrary(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final String path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/comic/')) {
      final String? seriesLocation = resolveComicDetailBackLocation(
        returnSeriesId: _readReturnSeriesId(context),
      );
      if (seriesLocation != null) {
        clearComicDetailReturnSeriesFromContext(context);
        // Series detail already uses fade-through pageBuilder.
        context.go(seriesLocation);
        return;
      }
    }
    requestShellFadeThroughOnce();
    LibraryManagementActions.goCurrentLibraryBrowseFromContext(context);
  }

  static String? _readReturnSeriesId(BuildContext context) {
    try {
      return ProviderScope.containerOf(
        context,
      ).read(comicDetailReturnSeriesProvider);
    } catch (_) {
      return null;
    }
  }
}
