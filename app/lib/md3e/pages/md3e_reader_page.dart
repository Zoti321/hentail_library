import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_keyboard.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_viewport.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 漫画阅读页预览：全屏画布 + 可隐藏顶/底 chrome（视口与 FRB 后续接）。
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
    this.onPageChanged,
    this.onPreviousPage,
    this.onNextPage,
    this.onAutoPlayChanged,
    this.onToggleChromeFromKeyboard,
    this.moreMenuEntries = const <M3EMenuNode>[],
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
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<bool>? onAutoPlayChanged;
  final VoidCallback? onToggleChromeFromKeyboard;
  final List<M3EMenuNode> moreMenuEntries;

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
      child: Shortcuts(
        shortcuts: Md3eReaderKeyboard.shortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            Md3eReaderPrevPageIntent: CallbackAction<Md3eReaderPrevPageIntent>(
              onInvoke: (_) {
                widget.onPreviousPage?.call();
                return null;
              },
            ),
            Md3eReaderNextPageIntent: CallbackAction<Md3eReaderNextPageIntent>(
              onInvoke: (_) {
                widget.onNextPage?.call();
                return null;
              },
            ),
            Md3eReaderToggleAutoPlayIntent:
                CallbackAction<Md3eReaderToggleAutoPlayIntent>(
              onInvoke: (_) {
                if (widget.onAutoPlayChanged != null) {
                  widget.onAutoPlayChanged!(!widget.autoPlayEnabled);
                }
                return null;
              },
            ),
            Md3eReaderToggleChromeIntent:
                CallbackAction<Md3eReaderToggleChromeIntent>(
              onInvoke: (_) {
                widget.onToggleChromeFromKeyboard?.call();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            focusNode: _focusNode,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Md3eReaderViewport(
                  currentPage: widget.currentPage,
                  chromeVisible: widget.chromeVisible,
                  focusNode: _focusNode,
                  onTapZone: widget.onTapZone,
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
                  onPageChanged: widget.onPageChanged,
                  onPreviousPage: widget.onPreviousPage,
                  onNextPage: widget.onNextPage,
                  onAutoPlayChanged: widget.onAutoPlayChanged,
                  moreMenuEntries: widget.moreMenuEntries,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
