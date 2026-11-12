import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/foundation/pointer_target.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
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
    this.gridIndex,
    this.coverViewportScope,
  });

  final String comicId;
  final String title;
  final DateTime lastReadTime;
  final int? pageIndex;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  /// History grid index for cover viewport prioritization; leave null off-grid.
  final int? gridIndex;

  /// [coverViewportProvider] scope；与 [gridIndex] 同时提供时启用视口优先级。
  final String? coverViewportScope;

  Object? _handleActivateIntent(ActivateIntent intent) {
    onTap();
    return null;
  }

  void _handleTap() {
    onTap();
    unfocusAfterPointerActivation();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ValueNotifier<bool> isHovered = useState(false);
    final ValueNotifier<bool> isFocused = useState(false);

    final BorderRadius cardRadius = BorderRadius.circular(tokens.radius.xs);
    final BorderRadius coverInnerRadius = BorderRadius.only(
      topRight: Radius.circular(tokens.radius.md),
      bottomRight: Radius.circular(tokens.radius.md),
    );

    final Color cardBackground = (isHovered.value || isFocused.value)
        ? cs.surfaceContainer
        : cs.surface;
    final List<BoxShadow> cardShadows = context.shadows.catalogCard(
      highlighted: isHovered.value || isFocused.value,
    );

    final String progressLabel = _progressLabel(context, pageIndex);

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: title,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => isHovered.value = true,
          onExit: (_) => isHovered.value = false,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            onShowFocusHighlight: (bool value) => isFocused.value = value,
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: _handleActivateIntent,
              ),
            },
            child: GestureDetector(
              onTap: _handleTap,
              child: AnimatedContainer(
                duration: motionDurationOf(
                  context,
                  context.motion.durationMedium,
                ),
                curve: AppMotionTokens.standardCurve,
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: cardRadius,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
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
                          child: ComicCoverContent(
                            comicId: comicId,
                            gridIndex: gridIndex,
                            coverViewportScope: coverViewportScope,
                          ),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.clock,
                                    size: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.l10n.relativeTimeAgo(lastReadTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
