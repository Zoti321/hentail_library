import 'package:flutter/material.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_keyboard.dart';

/// 阅读页键盘快捷键与焦点（Lab；对齐 M3E 文档中 app bar 的 Tab/Space 交互习惯）。
class ReaderInteractionScope extends StatelessWidget {
  const ReaderInteractionScope({
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
      shortcuts: ReaderKeyboard.shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          ReaderPrevPageIntent: CallbackAction<ReaderPrevPageIntent>(
            onInvoke: (_) {
              onPreviousPage?.call();
              return null;
            },
          ),
          ReaderNextPageIntent: CallbackAction<ReaderNextPageIntent>(
            onInvoke: (_) {
              onNextPage?.call();
              return null;
            },
          ),
          ReaderToggleAutoPlayIntent:
              CallbackAction<ReaderToggleAutoPlayIntent>(
                onInvoke: (_) {
                  onToggleAutoPlay?.call();
                  return null;
                },
              ),
          ReaderToggleChromeIntent: CallbackAction<ReaderToggleChromeIntent>(
            onInvoke: (_) {
              onToggleChromeFromKeyboard?.call();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, focusNode: focusNode, child: child),
      ),
    );
  }
}
