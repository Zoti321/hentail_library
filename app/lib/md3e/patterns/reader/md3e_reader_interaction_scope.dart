import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_keyboard.dart';

/// 阅读页键盘快捷键与焦点（Lab；对齐 M3E 文档中 app bar 的 Tab/Space 交互习惯）。
class Md3eReaderInteractionScope extends StatelessWidget {
  const Md3eReaderInteractionScope({
    super.key,
    required this.focusNode,
    required this.child,
    this.onPreviousPage,
    this.onNextPage,
    this.onToggleAutoPlay,
    this.autoPlayEnabled = false,
    this.onToggleChromeFromKeyboard,
  });

  final FocusNode focusNode;
  final Widget child;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onToggleAutoPlay;
  final bool autoPlayEnabled;
  final VoidCallback? onToggleChromeFromKeyboard;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: Md3eReaderKeyboard.shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          Md3eReaderPrevPageIntent: CallbackAction<Md3eReaderPrevPageIntent>(
            onInvoke: (_) {
              onPreviousPage?.call();
              return null;
            },
          ),
          Md3eReaderNextPageIntent: CallbackAction<Md3eReaderNextPageIntent>(
            onInvoke: (_) {
              onNextPage?.call();
              return null;
            },
          ),
          Md3eReaderToggleAutoPlayIntent:
              CallbackAction<Md3eReaderToggleAutoPlayIntent>(
            onInvoke: (_) {
              onToggleAutoPlay?.call();
              return null;
            },
          ),
          Md3eReaderToggleChromeIntent:
              CallbackAction<Md3eReaderToggleChromeIntent>(
            onInvoke: (_) {
              onToggleChromeFromKeyboard?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          focusNode: focusNode,
          child: child,
        ),
      ),
    );
  }
}
