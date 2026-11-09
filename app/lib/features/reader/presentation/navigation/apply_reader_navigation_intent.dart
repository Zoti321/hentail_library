import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';

/// 在 View 侧执行 ViewModel 产出的导航意图。
void applyReaderNavigationIntent(
  BuildContext context,
  ReaderNavigationIntent? intent,
) {
  if (intent == null || !context.mounted) {
    return;
  }
  switch (intent) {
    case ReaderReplaceReaderRouteIntent(:final String location):
      GoRouter.of(context).pushReplacement(location);
  }
}

void applyReaderExitIntent(BuildContext context, ReaderExitIntent intent) {
  if (!context.mounted) {
    return;
  }
  switch (intent) {
    case ReaderExitPopIntent():
      GoRouter.of(context).pop();
    case ReaderExitGoIntent(:final String location):
      GoRouter.of(context).go(location);
  }
}
