import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_band.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 阅读器顶栏：全宽 scrim 上的返回 · 标题 · 操作（沉浸，非灰浮岛）。
class Md3eReaderTopBar extends StatelessWidget {
  const Md3eReaderTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onOpenSettings,
    this.onToggleFullscreen,
    this.isFullscreen = false,
    this.moreMenuEntries = const <M3EMenuNode>[],
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleFullscreen;
  final bool isFullscreen;
  final List<M3EMenuNode> moreMenuEntries;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ETypeScale type = M3ETheme.of(context).typeScale;
    final MediaQueryData media = MediaQuery.of(context);
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      12,
      media.padding.top + Md3eReaderChromeMetrics.edgeGap,
      12,
      8,
    );

    return Md3eReaderChromeBand(
      edge: Md3eReaderChromeBandEdge.top,
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Md3eReaderChromeMetrics.topBarMinHeight,
        ),
        child: Row(
          children: <Widget>[
            _iconButton(
              context: context,
              icon: Symbols.arrow_back,
              tooltip: l10n.shellBack,
              semanticLabel: l10n.readerBackSemantic,
              onPressed: onBack,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _TitleBlock(
                title: title,
                subtitle: subtitle,
                type: type,
              ),
            ),
            _iconButton(
              context: context,
              icon: Symbols.settings,
              tooltip: l10n.readerSettingsTitle,
              semanticLabel: l10n.readerSettingsTitle,
              onPressed: onOpenSettings,
            ),
            _iconButton(
              context: context,
              icon: isFullscreen ? Symbols.fullscreen_exit : Symbols.fullscreen,
              tooltip: isFullscreen
                  ? l10n.readerExitFullscreen
                  : l10n.readerEnterFullscreen,
              semanticLabel: isFullscreen
                  ? l10n.readerExitFullscreenSemantic
                  : l10n.readerEnterFullscreenSemantic,
              onPressed: onToggleFullscreen,
            ),
            if (moreMenuEntries.isEmpty)
              _iconButton(
                context: context,
                icon: Symbols.more_vert,
                tooltip: l10n.metadataMoreActions,
                semanticLabel: l10n.metadataMoreActions,
                onPressed: null,
              )
            else
              Md3eAnchoredMenu(
                position: M3EMenuAnchorPosition.bottomEnd,
                children: moreMenuEntries,
                anchorBuilder: (BuildContext context, VoidCallback open) {
                  return _iconButton(
                    context: context,
                    icon: Symbols.more_vert,
                    tooltip: l10n.metadataMoreActions,
                    semanticLabel: l10n.metadataMoreActions,
                    onPressed: open,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static Widget _iconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required String semanticLabel,
    VoidCallback? onPressed,
  }) {
    final Color foreground = Md3eReaderChromeScope.of(context).onChrome;
    return M3EIconButton(
      icon: Icon(
        icon,
        size: Md3eReaderChromeMetrics.actionIconSize,
        color: foreground,
      ),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.type,
  });

  final String title;
  final String? subtitle;
  final M3ETypeScale type;

  @override
  Widget build(BuildContext context) {
    final Md3eReaderChromeScope scope = Md3eReaderChromeScope.of(context);
    final String display = subtitle ?? title;

    return Text(
      display,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: type.titleSmall.copyWith(color: scope.onChrome),
    );
  }
}
