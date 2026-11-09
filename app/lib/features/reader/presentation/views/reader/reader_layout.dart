import 'package:flutter/material.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_interval.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_chrome.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_chrome_scope.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_interaction_scope.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport_status.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_tap_zone.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 漫画阅读页：letterbox + 画布 extend 至 chrome 下（同 [Scaffold.extendBodyBehindAppBar] 思路）。
class ReaderLayout extends StatefulWidget {
  const ReaderLayout({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.chromeVisible,
    this.onTapZone,
    this.subtitle,
    this.isFullscreen = false,
    this.autoPlayEnabled = false,
    this.autoPlayIntervalSeconds = kReaderAutoPlayIntervalDefault,
    this.onBack,
    this.onOpenSettings,
    this.onToggleFullscreen,
    this.onOpenSeriesCatalog,
    this.onPageChanged,
    this.onPreviousPage,
    this.onNextPage,
    this.onAutoPlayChanged,
    this.onToggleChromeFromKeyboard,
    this.moreMenuEntries = const <M3EMenuNode>[],
    this.viewportStatus = ReaderViewportStatus.ready,
    this.onViewportRetry,
    this.contentBuilder,
  });

  /// 生产页注入真实页图内容；为空时使用 Lab 占位视口。
  final Widget Function(FocusNode focusNode)? contentBuilder;

  final String title;
  final String? subtitle;
  final int currentPage;
  final int totalPages;
  final bool chromeVisible;
  final bool isFullscreen;
  final bool autoPlayEnabled;
  final int autoPlayIntervalSeconds;
  final ValueChanged<ReaderViewportTapZone>? onTapZone;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onOpenSeriesCatalog;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<bool>? onAutoPlayChanged;
  final VoidCallback? onToggleChromeFromKeyboard;
  final List<M3EMenuNode> moreMenuEntries;
  final ReaderViewportStatus viewportStatus;
  final VoidCallback? onViewportRetry;

  @override
  State<ReaderLayout> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderLayout> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ReaderLayout');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return ColoredBox(
      color: ReaderImmersiveColors.letterbox(scheme),
      child: ReaderInteractionScope(
        focusNode: _focusNode,
        onPreviousPage: widget.onPreviousPage,
        onNextPage: widget.onNextPage,
        onToggleChromeFromKeyboard: widget.onToggleChromeFromKeyboard,
        onToggleAutoPlay: widget.onAutoPlayChanged == null
            ? null
            : () => widget.onAutoPlayChanged!(!widget.autoPlayEnabled),
        autoPlayEnabled: widget.autoPlayEnabled,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (widget.contentBuilder != null)
              widget.contentBuilder!(_focusNode)
            else
              ReaderViewport(
                currentPage: widget.currentPage,
                focusNode: _focusNode,
                onTapZone: widget.onTapZone,
                status: widget.viewportStatus,
                onBack: widget.onBack,
                onRetry: widget.onViewportRetry,
              ),
            ReaderChrome(
              visible: widget.chromeVisible,
              title: widget.title,
              subtitle: widget.subtitle,
              currentPage: widget.currentPage,
              totalPages: widget.totalPages,
              isFullscreen: widget.isFullscreen,
              autoPlayEnabled: widget.autoPlayEnabled,
              autoPlayIntervalSeconds: widget.autoPlayIntervalSeconds,
              onBack: widget.onBack,
              onOpenSettings: widget.onOpenSettings,
              onToggleFullscreen: widget.onToggleFullscreen,
              onOpenSeriesCatalog: widget.onOpenSeriesCatalog,
              onPageChanged: widget.onPageChanged,
              onPreviousPage: widget.onPreviousPage,
              onNextPage: widget.onNextPage,
              onAutoPlayChanged: widget.onAutoPlayChanged,
              moreMenuEntries: widget.moreMenuEntries,
            ),
          ],
        ),
      ),
    );
  }
}
