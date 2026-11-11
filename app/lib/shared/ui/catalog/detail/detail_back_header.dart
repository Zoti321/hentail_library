import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';
import 'package:hentai_library/shared/ui/navigation/library_browse_navigation.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 无法 pop 时的额外落地页解析器（由详情 owner 注入，如漫画→来源系列）。
typedef DetailBackLocationResolver = String? Function(BuildContext context);

/// 漫画与系列详情共用的返回顶栏（含边缘状态页）。
///
/// 只下达导航意图 + [DetailBackLocationResolver]；owner 私有导航语义不经 shared。
class DetailBackHeader extends StatelessWidget {
  const DetailBackHeader({super.key, this.locationResolver});

  final DetailBackLocationResolver? locationResolver;

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
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                hoverColor: theme.hoverColor,
                overlayColor: theme.hoverColor,
                onPressed: () =>
                    popOrGoLibrary(context, locationResolver: locationResolver),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 详情返回：能 pop 则 pop；否则交给 owner 解析器，最后回 Current library browse。
  static void popOrGoLibrary(
    BuildContext context, {
    DetailBackLocationResolver? locationResolver,
  }) {
    final navigator = appNavigatorOf(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final String? resolved = locationResolver?.call(context);
    if (resolved != null && resolved.isNotEmpty) {
      navigator.goLocation(resolved);
      return;
    }
    goDefaultLibraryBrowseFromContext(context);
  }
}
