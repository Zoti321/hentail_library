import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 顶栏：[M3EAppBar.top] + scrim（主标题漫画名 · 副标题系列名）。
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
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color foreground = Md3eReaderImmersiveColors.onChrome(scheme);

    return M3EAppBar.top(
      backgroundColor: scheme.scrim,
      foregroundColor: foreground,
      elevation: 0,
      safeArea: true,
      centerTitle: false,
      title: _ReaderAppBarTitleBlock(
        title: title,
        subtitle: subtitle,
      ),
      leading: _iconButton(
        context: context,
        foreground: foreground,
        icon: Symbols.arrow_back,
        tooltip: l10n.shellBack,
        semanticLabel: l10n.readerBackSemantic,
        onPressed: onBack,
      ),
      actions: <Widget>[
        _iconButton(
          context: context,
          foreground: foreground,
          icon: Symbols.settings,
          tooltip: l10n.readerSettingsTitle,
          semanticLabel: l10n.readerSettingsTitle,
          onPressed: onOpenSettings,
        ),
        _iconButton(
          context: context,
          foreground: foreground,
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
            foreground: foreground,
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
                foreground: foreground,
                icon: Symbols.more_vert,
                tooltip: l10n.metadataMoreActions,
                semanticLabel: l10n.metadataMoreActions,
                onPressed: open,
              );
            },
          ),
      ],
    );
  }

  static Widget _iconButton({
    required BuildContext context,
    required Color foreground,
    required IconData icon,
    required String tooltip,
    required String semanticLabel,
    VoidCallback? onPressed,
  }) {
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

/// 顶栏标题区：漫画名 [titleSmall] · 系列名 [labelMedium]（Lab 自定排版，非 AppBar 内置副标题样式）。
class _ReaderAppBarTitleBlock extends StatelessWidget {
  const _ReaderAppBarTitleBlock({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final Md3eReaderChromeScope scope = Md3eReaderChromeScope.of(context);
    final M3ETypeScale type = M3ETheme.of(context).typeScale;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.titleSmall.copyWith(color: scope.onChrome),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.labelMedium.copyWith(color: scope.onChromeVariant),
          ),
      ],
    );
  }
}
