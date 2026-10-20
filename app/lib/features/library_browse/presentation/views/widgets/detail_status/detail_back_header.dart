import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_page/comic_detail_back_location.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 漫画与系列详情共用的返回顶栏（含边缘状态页）。
class DetailBackHeader extends StatelessWidget {
  const DetailBackHeader({super.key});

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
            color: context.shadows.catalogCardRest,
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
                foregroundColor: context.hentai.iconDefault,
                hoverColor: theme.hoverColor,
                overlayColor: theme.hoverColor,
                onPressed: () => DetailBackHeader.popOrGoLibrary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 详情返回：能 pop 则 pop；漫画详情优先回到记住的系列来源，否则 Current library browse。
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
        context.go(seriesLocation);
        return;
      }
    }
    requestShellFadeThroughOnce();
    goCurrentLibraryBrowseFromContext(context);
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
