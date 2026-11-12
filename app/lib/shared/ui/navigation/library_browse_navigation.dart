import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hentai_library/shared/di/library_browse_fallback_providers.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';

/// 仅持有 [BuildContext]（无 WidgetRef）的调用点：无具体库上下文时回 Home。
void goDefaultLibraryBrowseFromContext(BuildContext context) {
  try {
    ProviderScope.containerOf(context)
        .read(goLibraryBrowseFallbackCommandProvider)(context);
  } catch (_) {
    appNavigatorOf(context).goHome();
  }
}
