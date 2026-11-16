import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';

/// 首页下钻的二级页（阅读历史、垃圾桶、管理等）：能 pop 则 pop，否则回 Home。
void popOrGoHome(BuildContext context) {
  final navigator = appNavigatorOf(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  navigator.goHome();
}
