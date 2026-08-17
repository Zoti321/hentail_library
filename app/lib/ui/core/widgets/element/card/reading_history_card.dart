import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReadingHistoryCard extends HookConsumerWidget {
  const ReadingHistoryCard({
    super.key,
    required this.comicId,
    required this.title,
    required this.lastReadTime,
    required this.pageIndex,
    required this.onTap,
    this.onDelete,
  });

  final String comicId;
  final String title;
  final DateTime lastReadTime;
  final int? pageIndex;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ValueNotifier<bool> isHovered = useState(false);

    final BorderRadius cardRadius = BorderRadius.circular(tokens.radius.xs);
    final BorderRadius coverInnerRadius = BorderRadius.only(
      topRight: Radius.circular(tokens.radius.md),
      bottomRight: Radius.circular(tokens.radius.md),
    );

    final Color cardBackground =
        isHovered.value ? cs.surfaceContainer : cs.surface;
    final List<BoxShadow> cardShadows = isHovered.value
        ? <BoxShadow>[
            BoxShadow(
              color: cs.hentai.cardShadowHover,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: cs.hentai.cardShadow,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ];

    final String progressLabel = _progressLabel(context, pageIndex);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: cardRadius,
            border: Border.all(color: cs.hentai.borderSubtle, width: 1),
            boxShadow: cardShadows,
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: coverInnerRadius,
                    child: ComicCoverContent(comicId: comicId),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.hentai.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 12,
                              color: cs.hentai.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.relativeTimeAgo(lastReadTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.hentai.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        if (progressLabel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            progressLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.hentai.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: GhostButton.icon(
                        icon: LucideIcons.trash2,
                        tooltip: context.l10n.historyDeleteRecord,
                        semanticLabel: context.l10n.historyDeleteRecord,
                        onPressed: onDelete,
                        iconSize: 18,
                        size: 32,
                        borderRadius: tokens.radius.md,
                        foregroundColor: cs.hentai.textTertiary,
                        hoverColor: theme.hoverColor,
                        overlayColor: theme.hoverColor.withAlpha(110),
                        delayTooltipThreeSeconds: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _progressLabel(BuildContext context, int? pageIndex) {
  if (pageIndex == null || pageIndex <= 0) {
    return '';
  }
  return context.l10n.readingProgressPage(pageIndex);
}
