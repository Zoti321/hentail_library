import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';
import 'package:hentai_library/shared/domain/contracts/app_navigator.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';

/// 在 View 侧执行 ViewModel 产出的导航意图。
void applyReaderNavigationIntent(
  BuildContext context,
  ReaderNavigationIntent? intent,
) {
  if (intent == null || !context.mounted) {
    return;
  }
  final AppNavigator navigator = appNavigatorOf(context);
  switch (intent) {
    case ReaderReplaceReaderRouteIntent(:final String location):
      navigator.replaceLocation(location);
  }
}

void applyReaderExitIntent(BuildContext context, ReaderExitIntent intent) {
  if (!context.mounted) {
    return;
  }
  final AppNavigator navigator = appNavigatorOf(context);
  switch (intent) {
    case ReaderExitPopIntent():
      navigator.pop();
    case ReaderExitGoIntent(:final String location):
      navigator.goLocation(location);
  }
}
