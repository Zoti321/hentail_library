import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/app_navigator_provider.dart';
import 'package:hentai_library/shared/domain/contracts/app_navigator.dart';

/// 无 [WidgetRef] 的 shared UI 调用点：从 [BuildContext] 取注入的导航器。
AppNavigator appNavigatorOf(BuildContext context) => ProviderScope.containerOf(
  context,
  listen: false,
).read(appNavigatorProvider);
