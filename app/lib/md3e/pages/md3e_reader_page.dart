import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_interaction_scope.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_preview_data.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_viewport.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 漫画阅读页：letterbox + 画布 extend 至 chrome 下（同 [Scaffold.extendBodyBehindAppBar] 思路）。
class Md3eReaderPage extends StatefulWidget {
  const Md3eReaderPage({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.chromeVisible,
    required this.onTapZone,
    this.subtitle,
    this.isFullscreen = false,
    this.autoPlayEnabled = false,
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
    this.viewportStatus = Md3eReaderViewportStatus.ready,
    this.onViewportRetry,
  });

  final String title;
  final String? subtitle;
  final int currentPage;
  final int totalPages;
  final bool chromeVisible;
  final bool isFullscreen;
  final bool autoPlayEnabled;
  final ValueChanged<Md3eReaderTapZone> onTapZone;
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
  final Md3eReaderViewportStatus viewportStatus;
  final VoidCallback? onViewportRetry;

  @override
  State<Md3eReaderPage> createState() => _Md3eReaderPageState();
}

class _Md3eReaderPageState extends State<Md3eReaderPage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Md3eReaderPage');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return ColoredBox(
      color: Md3eReaderImmersiveColors.letterbox(scheme),
      child: Md3eReaderInteractionScope(
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
            Md3eReaderViewport(
              currentPage: widget.currentPage,
              focusNode: _focusNode,
              onTapZone: widget.onTapZone,
              status: widget.viewportStatus,
              onBack: widget.onBack,
              onRetry: widget.onViewportRetry,
            ),
            Md3eReaderChrome(
              visible: widget.chromeVisible,
              title: widget.title,
              subtitle: widget.subtitle,
              currentPage: widget.currentPage,
              totalPages: widget.totalPages,
              isFullscreen: widget.isFullscreen,
              autoPlayEnabled: widget.autoPlayEnabled,
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
